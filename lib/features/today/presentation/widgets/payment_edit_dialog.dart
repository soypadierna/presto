import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/payment_model.dart';
import '../../../../features/clients/domain/client_model.dart';
import '../../../../core/utils/image_helper.dart';

/// Dialog reutilizable para crear o editar un pago histórico.
///
/// Retorna el [PaymentModel] guardado o null si se canceló.
class PaymentEditDialog extends StatefulWidget {
  /// Pago existente a editar. Si es null se crea uno nuevo.
  final PaymentModel? payment;
  final ClientModel client;
  final String routeId;
  final String paymentDate;

  const PaymentEditDialog({
    super.key,
    this.payment,
    required this.client,
    required this.routeId,
    required this.paymentDate,
  });

  @override
  State<PaymentEditDialog> createState() => _PaymentEditDialogState();
}

class _PaymentEditDialogState extends State<PaymentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late PaymentStatus _status;
  late PaymentMethod _method;
  String? _imagePath;
  String? _originalImagePath;

  bool get _isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _status = widget.payment!.status;
      _method = widget.payment!.paymentMethod;
      _imagePath = widget.payment!.imagePath;
      _originalImagePath = widget.payment!.imagePath;
      _amountController.text = widget.payment!.amount > 0
          ? widget.payment!.amount.toStringAsFixed(0)
          : '';
      _noteController.text = widget.payment?.note ?? '';
    } else {
      _status = PaymentStatus.paid;
      _method = PaymentMethod.cash;
      _amountController.text =
          widget.client.credit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        _isEditing
            ? 'Editar pago — ${widget.client.name}'
            : 'Agregar pago — ${widget.client.name}',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado del pago
              Text(
                'Estado',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusButton(
                      label: 'Pagó',
                      icon: Icons.check_circle_outline,
                      status: PaymentStatus.paid,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusButton(
                      label: 'No dio',
                      icon: Icons.cancel_outlined,
                      status: PaymentStatus.skipped,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),

              // Campos solo para pagos
              if (_status == PaymentStatus.paid) ...[
                const SizedBox(height: 14),

                // Monto
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '₡ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Ingresa el monto';
                    }
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
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMethodButton(
                        label: 'Efectivo',
                        icon: Icons.payments_outlined,
                        method: PaymentMethod.cash,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMethodButton(
                        label: 'Transferencia',
                        icon: Icons.phone_android_outlined,
                        method: PaymentMethod.transfer,
                      ),
                    ),
                  ],
                ),

                // Imagen comprobante
                if (_method == PaymentMethod.transfer) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Comprobante',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_imagePath != null)
                    _buildImagePreview()
                  else
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Adjuntar comprobante'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                ],
              ],

              const SizedBox(height: 14),

              // Nota / justificación
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: _status == PaymentStatus.paid
                      ? 'Nota (opcional)'
                      : 'Justificación (opcional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _onCancel,
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required PaymentStatus status,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _status == status;

    return GestureDetector(
      onTap: () => setState(() {
        _status = status;
        // Limpiar imagen si cambia a "no dio"
        if (status == PaymentStatus.skipped && _imagePath != null) {
          _handleImageCleanup(_imagePath!);
          _imagePath = null;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton({
    required String label,
    required IconData icon,
    required PaymentMethod method,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _method == method;

    return GestureDetector(
      onTap: () => setState(() {
        _method = method;
        // Limpiar imagen si cambia a efectivo
        if (method == PaymentMethod.cash && _imagePath != null) {
          _handleImageCleanup(_imagePath!);
          _imagePath = null;
        }
      }),
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

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_imagePath!),
            width: double.infinity,
            height: 140,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => setState(() {
              _handleImageCleanup(_imagePath!);
              _imagePath = null;
            }),
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

  Future<void> _pickImage() async {
    final path = await ImageHelper.showImageSourceDialog(context);
    if (path != null && mounted) {
      setState(() => _imagePath = path);
    }
  }

  /// Elimina la imagen solo si es nueva (no la original).
  void _handleImageCleanup(String path) {
    if (path != _originalImagePath) {
      ImageHelper.deleteImage(path);
    }
  }

  void _onCancel() {
    // Limpiar imagen nueva si se canceló
    if (_imagePath != null && _imagePath != _originalImagePath) {
      ImageHelper.deleteImage(_imagePath!);
    }
    Navigator.pop(context, null);
  }

  void _onSave() {
    if (_status == PaymentStatus.paid &&
        !_formKey.currentState!.validate()) {
      return;
    }

    // Si cambió la imagen original eliminarla
    if (_originalImagePath != null &&
        _originalImagePath != _imagePath) {
      ImageHelper.deleteImage(_originalImagePath!);
    }

    final payment = PaymentModel(
      id: widget.payment?.id ?? const Uuid().v4(),
      clientId: widget.client.id,
      routeId: widget.routeId,
      amount: _status == PaymentStatus.paid
          ? double.parse(_amountController.text)
          : 0,
      status: _status,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      paymentDate: widget.paymentDate,
      createdAt:
          widget.payment?.createdAt ?? DateTime.now().toIso8601String(),
      paymentMethod: _status == PaymentStatus.paid
          ? _method
          : PaymentMethod.cash,
      imagePath: _status == PaymentStatus.paid ? _imagePath : null,
    );

    Navigator.pop(context, payment);
  }
}