import 'package:flutter/material.dart';
import '../domain/client_model.dart';
import '../../today/data/payment_repository.dart';
import '../../today/domain/payment_model.dart';
import '../../../core/utils/formatters.dart';

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
      _payments = await _repository.getPaymentsByClient(widget.client.id);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen histórico
                _buildSummaryCard(context),

                // Lista de pagos
                Expanded(
                  child: _payments.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
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
    final isPaid = payment.status == PaymentStatus.paid;
    final date = DateTime.parse(payment.paymentDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícono estado
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isPaid ? Colors.green.shade600 : Colors.red.shade600,
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Monto
          Text(
            isPaid ? Formatters.formatAmount(payment.amount) : 'No dio',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isPaid ? Colors.green.shade700 : Colors.red.shade600,
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
        ],
      ),
    );
  }
}
