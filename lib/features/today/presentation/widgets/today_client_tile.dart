import 'dart:io';

import 'package:flutter/material.dart';
import 'package:presto/core/utils/image_helper.dart';
import 'package:provider/provider.dart';
import '../../domain/payment_model.dart';
import '../../domain/today_client.dart';
import '../today_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/dark_mode_helper.dart';

class TodayClientTile extends StatelessWidget {
  final TodayClient todayClient;

  const TodayClientTile({super.key, required this.todayClient});

  @override
  Widget build(BuildContext context) {
    // Si ya está registrado solo permitir long press para deshacer
    if (!todayClient.isPending) {
      return GestureDetector(
        onLongPress: () => _showUndoConfirmation(context),
        child: _buildTileContent(context),
      );
    }

    // Pendiente: habilitar swipe
    return Dismissible(
      key: Key('today_${todayClient.client.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _showSkippedDialog(context);
        } else {
          await _showPaymentDialog(context);
        }
        return false;
      },
      background: _buildSwipeBackground(
        color: Colors.green.shade500,
        icon: Icons.attach_money,
        label: 'Pagó',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Colors.red.shade500,
        icon: Icons.money_off_outlined,
        label: 'No dio',
        alignment: Alignment.centerRight,
      ),
      child: _buildTileContent(context),
    );
  }

  Widget _buildTileContent(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _borderColor(context),
          width: 1.5,
        ),
        color: _backgroundColor(context),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Ícono estado
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconBackgroundColor(context),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _statusIcon(),
                color: _iconColor(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayClient.client.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildSubtitle(context),
                ],
              ),
            ),

            // Badge de estado
            _buildStatusBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    if (todayClient.isPaid) {
      return Text(
        todayClient.payment?.note?.isNotEmpty == true
            ? todayClient.payment!.note!
            : 'Cobro registrado',
        style: subtitleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (todayClient.isSkipped) {
      return Text(
        todayClient.payment?.note?.isNotEmpty == true
            ? todayClient.payment!.note!
            : 'Sin justificación',
        style: subtitleStyle?.copyWith(fontStyle: FontStyle.italic),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      Formatters.formatAmount(todayClient.client.credit),
      style: subtitleStyle,
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (todayClient.isPending) return const SizedBox.shrink();

    if (todayClient.isPaid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.formatAmount(todayClient.payment!.amount),
            style: TextStyle(
              color: Colors.green.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Text(
            'hold para deshacer',
            style: TextStyle(
              color: Colors.green.shade400,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'No dio',
          style: TextStyle(
            color: Colors.red.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          'hold para deshacer',
          style: TextStyle(
            color: Colors.red.shade400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
  final provider = context.read<TodayProvider>();
  final amountController = TextEditingController(
    text: todayClient.client.credit.toStringAsFixed(0),
  );
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Estado local del dialog
  PaymentMethod selectedMethod = PaymentMethod.cash;
  String? selectedImagePath;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text('Cobro — ${todayClient.client.name}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monto
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '₡ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa el monto';
                    if (double.tryParse(v) == null ||
                        double.parse(v) <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Tipo de pago
                Text(
                  'Tipo de pago',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodButton(
                        ctx: ctx,
                        label: 'Efectivo',
                        icon: Icons.payments_outlined,
                        method: PaymentMethod.cash,
                        selected: selectedMethod,
                        onTap: () => setDialogState(() {
                          selectedMethod = PaymentMethod.cash;
                          // Limpiar imagen si cambia a efectivo
                          if (selectedImagePath != null) {
                            ImageHelper.deleteImage(selectedImagePath!);
                            selectedImagePath = null;
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPaymentMethodButton(
                        ctx: ctx,
                        label: 'Transferencia',
                        icon: Icons.phone_android_outlined,
                        method: PaymentMethod.transfer,
                        selected: selectedMethod,
                        onTap: () => setDialogState(() {
                          selectedMethod = PaymentMethod.transfer;
                        }),
                      ),
                    ),
                  ],
                ),

                // Adjuntar imagen (solo para transferencia)
                if (selectedMethod == PaymentMethod.transfer) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Comprobante',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Preview de imagen o botón para adjuntar
                  if (selectedImagePath != null)
                    _buildImagePreview(
                      ctx: ctx,
                      imagePath: selectedImagePath!,
                      onDelete: () => setDialogState(() {
                        ImageHelper.deleteImage(selectedImagePath!);
                        selectedImagePath = null;
                      }),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path =
                            await ImageHelper.showImageSourceDialog(ctx);
                        if (path != null) {
                          setDialogState(() => selectedImagePath = path);
                        }
                      },
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Adjuntar comprobante'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                ],

                const SizedBox(height: 12),

                // Nota opcional
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Limpiar imagen si se cancela
              if (selectedImagePath != null) {
                ImageHelper.deleteImage(selectedImagePath!);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                provider.registerPayment(
                  todayClient,
                  double.parse(amountController.text),
                  noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                  paymentMethod: selectedMethod,
                  imagePath: selectedImagePath,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPaymentMethodButton({
  required BuildContext ctx,
  required String label,
  required IconData icon,
  required PaymentMethod method,
  required PaymentMethod selected,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(ctx);
  final colorScheme = theme.colorScheme;
  final isSelected = selected == method;

  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildImagePreview({
  required BuildContext ctx,
  required String imagePath,
  required VoidCallback onDelete,
}) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(imagePath),
          width: double.infinity,
          height: 140,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    ],
  );
}

  Future<void> _showSkippedDialog(BuildContext context) async {
    final provider = context.read<TodayProvider>();
    final justificationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('No dio — ${todayClient.client.name}'),
        content: TextField(
          controller: justificationController,
          decoration: const InputDecoration(
            labelText: 'Justificación (opcional)',
            hintText: 'Ej: No estaba en casa',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              provider.registerSkipped(
                todayClient,
                justificationController.text.trim().isEmpty
                    ? null
                    : justificationController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUndoConfirmation(BuildContext context) async {
    final provider = context.read<TodayProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deshacer registro'),
        content: Text(
          '¿Deshacer el registro de ${todayClient.client.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deshacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.undoPayment(todayClient);
    }
  }

  // Colores adaptados al modo oscuro
  Color _borderColor(BuildContext context) {
    if (todayClient.isPaid) return DarkModeHelper.paidBorder(context);
    if (todayClient.isSkipped) return DarkModeHelper.skippedBorder(context);
    return Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);
  }

  Color _backgroundColor(BuildContext context) {
    if (todayClient.isPaid) return DarkModeHelper.paidBackground(context);
    if (todayClient.isSkipped) return DarkModeHelper.skippedBackground(context);
    return Theme.of(context).colorScheme.surface;
  }

  Color _iconBackgroundColor(BuildContext context) {
    if (todayClient.isPaid) return DarkModeHelper.paidIconBackground(context);
    if (todayClient.isSkipped) {
      return DarkModeHelper.skippedIconBackground(context);
    }
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
  }

  Color _iconColor(BuildContext context) {
    if (todayClient.isPaid) return Colors.green.shade400;
    if (todayClient.isSkipped) return Colors.red.shade400;
    return Theme.of(context).colorScheme.primary;
  }

  IconData _statusIcon() {
    if (todayClient.isPaid) return Icons.check_circle_outline;
    if (todayClient.isSkipped) return Icons.cancel_outlined;
    return Icons.person_outline;
  }
}
