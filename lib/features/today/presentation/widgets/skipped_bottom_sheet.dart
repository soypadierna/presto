import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/today_client.dart';
import '../today_provider.dart';
import 'reschedule_bottom_sheet.dart';

/// Bottom Sheet para registrar que un cliente no dio.
class SkippedBottomSheet extends StatefulWidget {
  final TodayClient todayClient;
  final VoidCallback? onAfterAction;

  const SkippedBottomSheet({
    super.key,
    required this.todayClient,
    this.onAfterAction,
  });

  static Future<void> show(
    BuildContext context,
    TodayClient todayClient, {
    required TodayProvider provider,
    VoidCallback? onAfterAction,
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
        child: SkippedBottomSheet(
          todayClient: todayClient,
          onAfterAction: onAfterAction,
        ),
      ),
    );
  }

  @override
  State<SkippedBottomSheet> createState() => _SkippedBottomSheetState();
}

class _SkippedBottomSheetState extends State<SkippedBottomSheet> {
  final _justificationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _justificationController.dispose();
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.money_off_outlined,
                    color: Colors.red.shade600,
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
                        'Registrar como no dio',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Justificación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Justificación',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _justificationController,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ej: No estaba en casa, dijo que mañana...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dos botones de acción
                Row(
                  children: [
                    // Solo registrar
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _registerOnly,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text(
                          'Solo registrar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Registrar y agendar
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _registerAndSchedule,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: const Text(
                          'Agendar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Solo registra el "no dio" sin reagendar.
  Future<void> _registerOnly() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<TodayProvider>();
      await provider.registerSkipped(
        widget.todayClient,
        _justificationController.text.trim().isEmpty
            ? null
            : _justificationController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAfterAction?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Registra el "no dio" y luego abre el Bottom Sheet de reagendamiento.
  Future<void> _registerAndSchedule() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<TodayProvider>();
      await provider.registerSkipped(
        widget.todayClient,
        _justificationController.text.trim().isEmpty
            ? null
            : _justificationController.text.trim(),
      );

      if (mounted) {
        // Cerrar este Bottom Sheet
        Navigator.pop(context);
        widget.onAfterAction?.call();

        // Abrir Bottom Sheet de reagendamiento
        await RescheduleBottomSheet.show(
          context,
          widget.todayClient,
          provider: provider,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}
