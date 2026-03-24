import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:presto/features/report/domain/payment_with_client.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/day_summary.dart';
import '../domain/report_generator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/dark_mode_helper.dart';
import '../../today/domain/payment_model.dart';
import '../../today/data/payment_repository.dart';
import '../../today/presentation/widgets/payment_edit_dialog.dart';
import '../../clients/domain/client_model.dart';
import '../../clients/data/client_repository.dart';

class DayDetailScreen extends StatefulWidget {
  final DaySummary summary;
  final String routeName;
  final String routeId;

  const DayDetailScreen({
    super.key,
    required this.summary,
    required this.routeName,
    required this.routeId,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final ClientRepository _clientRepository = ClientRepository();
  late DaySummary _summary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
  }

  /// Recarga el resumen del día desde la DB.
  Future<void> _reloadSummary() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _paymentRepository.getPaymentsByDate(
        widget.routeId,
        widget.summary.date,
      );

      // Reconstruir el DaySummary con los pagos actualizados
      final updatedPayments = <PaymentWithClient>[];
      for (final payment in payments) {
        final clients = await _clientRepository.getClientsByRoute(
          widget.routeId,
        );
        final client = clients.firstWhere(
          (c) => c.id == payment.clientId,
          orElse: () => ClientModel(
            id: payment.clientId,
            routeId: widget.routeId,
            name: 'Cliente eliminado',
            credit: 0,
            paymentType: PaymentType.daily,
            paymentDays: {},
            position: 0,
            isActive: false,
            createdAt: '',
          ),
        );
        updatedPayments.add(
          PaymentWithClient(payment: payment, clientName: client.name),
        );
      }

      final totalCollected = updatedPayments
          .where((p) => p.payment.status == PaymentStatus.paid)
          .fold<double>(0, (sum, p) => sum + p.payment.amount);

      setState(() {
        _summary = DaySummary(
          date: _summary.date,
          totalCollected: totalCollected,
          totalExpenses: _summary.totalExpenses,
          baseAmount: _summary.baseAmount,
          netTotal: _summary.baseAmount + totalCollected - _summary.totalExpenses,
          paidCount: updatedPayments
              .where((p) => p.payment.status == PaymentStatus.paid)
              .length,
          skippedCount: updatedPayments
              .where((p) => p.payment.status == PaymentStatus.skipped)
              .length,
          payments: updatedPayments,
        );
      });
    } catch (e) {
      debugPrint('Error recargando resumen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = DateTime.parse(_summary.date);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalle del día'),
            Text(
              Formatters.formatShortDate(date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          // Agregar pago
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Agregar pago',
            onPressed: _showAddPaymentDialog,
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar informe',
            onPressed: () => _copyReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir informe',
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(context),
                const SizedBox(height: 16),
                _buildPaymentsList(context),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            context: context,
            label: 'Base del día',
            amount: _summary.baseAmount,
            color: colorScheme.onSurface,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            context: context,
            label: 'Total cobrado',
            amount: _summary.totalCollected,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            context: context,
            label: 'Total gastos',
            amount: _summary.totalExpenses,
            color: Colors.red.shade600,
            isNegative: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Neto del día',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                Formatters.formatAmount(_summary.netTotal),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _summary.netTotal >= 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountChip(
                context: context,
                label: '${_summary.paidCount} pagaron',
                color: Colors.green.shade600,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _buildCountChip(
                context: context,
                label: '${_summary.skippedCount} no dieron',
                color: Colors.red.shade600,
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
    required String label,
    required double amount,
    required Color color,
    bool isNegative = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '${isNegative ? '- ' : ''}${Formatters.formatAmount(amount)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCountChip({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_summary.payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Text(
            'Sin cobros registrados',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cobros del día',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._summary.payments.asMap().entries.map((entry) {
          final index = entry.key;
          final pwc = entry.value;
          return _buildPaymentTile(context, pwc, index);
        }),
      ],
    );
  }

  Widget _buildPaymentTile(
    BuildContext context,
    PaymentWithClient pwc,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaid = pwc.payment.status == PaymentStatus.paid;
    final isTransfer = pwc.payment.paymentMethod == PaymentMethod.transfer;

    return Dismissible(
      key: Key('day_payment_${pwc.payment.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) =>
          _showDeleteConfirmation(context, pwc.clientName),
      onDismissed: (_) => _deletePayment(pwc.payment),
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => _showEditPaymentDialog(pwc),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPaid
                  ? DarkModeHelper.paidBorder(context)
                  : DarkModeHelper.skippedBorder(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Número
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? DarkModeHelper.paidIconBackground(context)
                          : DarkModeHelper.skippedIconBackground(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPaid
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nombre cliente
                  Expanded(
                    child: Text(
                      pwc.clientName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Monto y tipo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPaid
                            ? Formatters.formatAmount(pwc.payment.amount)
                            : 'No dio',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isPaid
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                      ),
                      if (isPaid) ...[
                        const SizedBox(height: 2),
                        _buildMethodBadge(context, isTransfer),
                      ],
                    ],
                  ),

                  // Ícono editar
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),

              // Imagen comprobante
              if (isPaid &&
                  isTransfer &&
                  pwc.payment.imagePath != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                      _showFullImage(context, pwc.payment.imagePath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(pwc.payment.imagePath!),
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodBadge(BuildContext context, bool isTransfer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isTransfer
            ? Colors.blue.withValues(alpha: 0.1)
            : colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTransfer
              ? Colors.blue.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTransfer
                ? Icons.phone_android_outlined
                : Icons.payments_outlined,
            size: 10,
            color: isTransfer
                ? Colors.blue.shade600
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 3),
          Text(
            isTransfer ? 'Transferencia' : 'Efectivo',
            style: TextStyle(
              fontSize: 10,
              color: isTransfer
                  ? Colors.blue.shade600
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ─────────────────────────────────────────────

  Future<void> _showAddPaymentDialog() async {
    // Obtener clientes sin pago en este día
    final clientsWithoutPayment =
        await _paymentRepository.getClientsWithoutPayment(
      widget.routeId,
      _summary.date,
    );

    if (!mounted) return;

    if (clientsWithoutPayment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Todos los clientes ya tienen pago registrado'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Mostrar lista de clientes disponibles
    final selectedClient = await showModalBottomSheet<ClientModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildClientPickerSheet(ctx, clientsWithoutPayment),
    );

    if (selectedClient == null || !mounted) return;

    final result = await showDialog<PaymentModel?>(
      context: context,
      builder: (_) => PaymentEditDialog(
        client: selectedClient,
        routeId: widget.routeId,
        paymentDate: _summary.date,
      ),
    );

    if (result != null) {
      await _paymentRepository.insertPayment(result);
      await _reloadSummary();
      if (mounted) _showSuccessSnackBar('Pago agregado correctamente');
    }
  }

  Widget _buildClientPickerSheet(
    BuildContext context,
    List<ClientModel> clients,
  ) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Selecciona el cliente',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: clients.length,
              itemBuilder: (ctx, index) {
                final client = clients[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    child: Text(
                      client.name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(client.name),
                  subtitle: Text(Formatters.formatAmount(client.credit)),
                  onTap: () => Navigator.pop(context, client),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showEditPaymentDialog(PaymentWithClient pwc) async {
    // Obtener el cliente
    final clients = await _clientRepository.getClientsByRoute(
      widget.routeId,
    );
    final client = clients.firstWhere(
      (c) => c.id == pwc.payment.clientId,
      orElse: () => ClientModel(
        id: pwc.payment.clientId,
        routeId: widget.routeId,
        name: pwc.clientName,
        credit: pwc.payment.amount,
        paymentType: PaymentType.daily,
        paymentDays: {},
        position: 0,
        isActive: true,
        createdAt: '',
      ),
    );

    if (!mounted) return;

    final result = await showDialog<PaymentModel?>(
      context: context,
      builder: (_) => PaymentEditDialog(
        payment: pwc.payment,
        client: client,
        routeId: widget.routeId,
        paymentDate: pwc.payment.paymentDate,
      ),
    );

    if (result != null) {
      await _paymentRepository.updatePayment(result);
      await _reloadSummary();
      if (mounted) _showSuccessSnackBar('Pago actualizado correctamente');
    }
  }

  Future<void> _deletePayment(PaymentModel payment) async {
    await _paymentRepository.deletePayment(payment.id);
    await _reloadSummary();
    if (mounted) _showSuccessSnackBar('Pago eliminado');
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    String clientName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: Text('¿Eliminar el pago de $clientName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Comprobante'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildReportText() {
    return ReportGenerator.generateFromSummary(
      routeName: widget.routeName,
      summary: _summary,
    );
  }

  Future<void> _copyReport(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _buildReportText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Informe copiado al portapapeles'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _shareReport(BuildContext context) async {
    await Share.share(
      _buildReportText(),
      subject: 'Informe Presto — ${widget.routeName}',
    );
  }
}