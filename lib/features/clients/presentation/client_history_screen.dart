import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/client_model.dart';
import '../../today/data/payment_repository.dart';
import '../../today/domain/payment_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/dark_mode_helper.dart';
import '../../today/presentation/widgets/payment_edit_dialog.dart';

class ClientHistoryScreen extends StatefulWidget {
  final ClientModel client;

  const ClientHistoryScreen({super.key, required this.client});

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  final PaymentRepository _repository = PaymentRepository();
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      _payments =
          await _repository.getPaymentsByClient(widget.client.id);
    } catch (e) {
      debugPrint('Error cargando historial: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _totalCollected => _payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0, (sum, p) => sum + p.amount);

  int get _paidCount =>
      _payments.where((p) => p.status == PaymentStatus.paid).length;

  int get _skippedCount =>
      _payments.where((p) => p.status == PaymentStatus.skipped).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.client.name),
            Text(
              'Historial de pagos',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agregar pago'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(context),
                Expanded(
                  child: _payments.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) =>
                              _buildPaymentTile(context, _payments[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context: context,
            label: 'Total cobrado',
            value: Formatters.formatAmount(_totalCollected),
            color: Colors.green.shade700,
          ),
          _buildDivider(context),
          _buildSummaryItem(
            context: context,
            label: 'Pagos',
            value: '$_paidCount',
            color: colorScheme.primary,
          ),
          _buildDivider(context),
          _buildSummaryItem(
            context: context,
            label: 'No dieron',
            value: '$_skippedCount',
            color: Colors.red.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildPaymentTile(BuildContext context, PaymentModel payment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaid = payment.status == PaymentStatus.paid;
    final isTransfer = payment.paymentMethod == PaymentMethod.transfer;
    final date = DateTime.parse(payment.paymentDate);

    return Dismissible(
      key: Key('payment_${payment.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteConfirmation(context, payment),
      onDismissed: (_) => _deletePayment(payment),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        onTap: () => _showEditPaymentDialog(payment),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  // Ícono estado
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? DarkModeHelper.paidIconBackground(context)
                          : DarkModeHelper.skippedIconBackground(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPaid
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: isPaid
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Fecha y nota
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.formatShortDate(date),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (payment.note?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            payment.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Monto y tipo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPaid
                            ? Formatters.formatAmount(payment.amount)
                            : 'No dio',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isPaid
                              ? Colors.green.shade700
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
              if (isPaid && isTransfer && payment.imagePath != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                      _showFullImage(context, payment.imagePath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(payment.imagePath!),
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca para ver completo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 56,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin historial de pagos',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón para agregar el primer pago',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ─────────────────────────────────────────────

  Future<void> _showAddPaymentDialog() async {
    // Seleccionar fecha
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // No permite fechas futuras
      helpText: 'Selecciona la fecha del pago',
    );

    if (date == null || !mounted) return;

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    // Verificar si ya existe un pago en esa fecha
    final existing = await _repository.getPaymentByClientAndDate(
      widget.client.id,
      dateStr,
    );

    if (existing != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ya existe un pago registrado el '
            '${Formatters.formatShortDate(date)}',
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    final result = await showDialog<PaymentModel?>(
      context: context,
      builder: (_) => PaymentEditDialog(
        client: widget.client,
        routeId: widget.client.routeId,
        paymentDate: dateStr,
      ),
    );

    if (result != null) {
      await _repository.insertPayment(result);
      await _loadHistory();
      if (mounted) _showSuccessSnackBar('Pago agregado correctamente');
    }
  }

  Future<void> _showEditPaymentDialog(PaymentModel payment) async {
    final result = await showDialog<PaymentModel?>(
      context: context,
      builder: (_) => PaymentEditDialog(
        payment: payment,
        client: widget.client,
        routeId: widget.client.routeId,
        paymentDate: payment.paymentDate,
      ),
    );

    if (result != null) {
      await _repository.updatePayment(result);
      await _loadHistory();
      if (mounted) _showSuccessSnackBar('Pago actualizado correctamente');
    }
  }

  Future<void> _deletePayment(PaymentModel payment) async {
    await _repository.deletePayment(payment.id);
    await _loadHistory();
    if (mounted) _showSuccessSnackBar('Pago eliminado');
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    PaymentModel payment,
  ) {
    final date = DateTime.parse(payment.paymentDate);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: Text(
          '¿Eliminar el pago del '
          '${Formatters.formatShortDate(date)}?',
        ),
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
}