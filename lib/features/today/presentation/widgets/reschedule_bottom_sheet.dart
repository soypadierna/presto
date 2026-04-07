import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/today_client.dart';
import '../today_provider.dart';
import '../../../../../core/utils/formatters.dart';

/// Bottom Sheet para reagendar el cobro de un cliente.
class RescheduleBottomSheet extends StatefulWidget {
  final TodayClient todayClient;

  const RescheduleBottomSheet({
    super.key,
    required this.todayClient,
  });

  static Future<void> show(
    BuildContext context,
    TodayClient todayClient, {
    required TodayProvider provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: RescheduleBottomSheet(todayClient: todayClient),
      ),
    );
  }

  @override
  State<RescheduleBottomSheet> createState() =>
      _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_outlined,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.todayClient.client.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Agendar próximo cobro',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de fecha
                  Text(
                    'Fecha del cobro',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedDate != null
                              ? Colors.amber.shade600
                              : colorScheme.outline.withValues(alpha: 0.4),
                          width: _selectedDate != null ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedDate != null
                            ? Colors.amber.shade50
                            : colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: _selectedDate != null
                                ? Colors.amber.shade700
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? Formatters.formatDate(_selectedDate!)
                                : 'Seleccionar fecha',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _selectedDate != null
                                  ? Colors.amber.shade800
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                              fontWeight: _selectedDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nota opcional
                  Text(
                    '¿Qué dijo el cliente?',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Ej: Dijo que paga el viernes por la tarde...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón agendar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed:
                          _selectedDate == null || _isLoading
                              ? null
                              : _reschedule,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.amber.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.event_available_outlined),
                      label: Text(
                        _isLoading ? 'Agendando...' : 'Agendar cobro',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      // No permitir hoy ni fechas pasadas
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Selecciona la fecha del cobro',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _reschedule() async {
    if (_selectedDate == null) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TodayProvider>();
      await provider.reschedulePayment(
        widget.todayClient,
        _selectedDate!,
        _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}