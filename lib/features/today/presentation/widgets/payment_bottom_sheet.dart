import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/today_client.dart';
import '../../domain/payment_model.dart';
import '../today_provider.dart';
import '../../../../../core/utils/image_helper.dart';
import '../../../../../core/utils/formatters.dart';

/// Bottom Sheet para registrar un pago de un cliente.
class PaymentBottomSheet extends StatefulWidget {
  final TodayClient todayClient;
  final VoidCallback? onAfterAction;

  const PaymentBottomSheet({
    super.key,
    required this.todayClient,
    this.onAfterAction,
  });

  static Future<void> show(
    BuildContext context,
    TodayClient todayClient, {
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
      builder: (_) => PaymentBottomSheet(
        todayClient: todayClient,
        onAfterAction: onAfterAction,
      ),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text =
        widget.todayClient.client.credit.toStringAsFixed(0);
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
            _buildHandle(context),

            // Header
            _buildHeader(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monto
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        prefixText: '₡ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    const SizedBox(height: 20),

                    // Tipo de pago
                    Text(
                      'Forma de pago',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMethodButton(
                            context: context,
                            label: 'Efectivo',
                            icon: Icons.payments_outlined,
                            method: PaymentMethod.cash,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMethodButton(
                            context: context,
                            label: 'Transferencia',
                            icon: Icons.phone_android_outlined,
                            method: PaymentMethod.transfer,
                          ),
                        ),
                      ],
                    ),

                    // Imagen comprobante
                    if (_selectedMethod == PaymentMethod.transfer) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Comprobante',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_imagePath != null)
                        _buildImagePreview(context)
                      else
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Adjuntar comprobante'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 20),

                    // Nota opcional
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Nota (opcional)',
                        hintText: 'Ej: Pagó con billete de 10,000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Botón registrar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _register,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
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
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isLoading ? 'Registrando...' : 'Registrar pago',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.attach_money,
              color: Colors.green.shade600,
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
                  'Crédito: ${Formatters.formatAmount(widget.todayClient.client.credit)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required PaymentMethod method,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedMethod = method;
        if (method == PaymentMethod.cash && _imagePath != null) {
          ImageHelper.deleteImage(_imagePath!);
          _imagePath = null;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildImagePreview(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imagePath!),
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() {
              ImageHelper.deleteImage(_imagePath!);
              _imagePath = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(6),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TodayProvider>();
      await provider.registerPayment(
        widget.todayClient,
        double.parse(_amountController.text),
        _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        paymentMethod: _selectedMethod,
        imagePath: _imagePath,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAfterAction?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}