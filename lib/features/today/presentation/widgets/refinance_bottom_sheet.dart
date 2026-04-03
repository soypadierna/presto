import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/today_client.dart';
import '../../domain/refinance_model.dart';
import '../today_provider.dart';
import '../../../../../core/utils/image_helper.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../clients/domain/client_model.dart';

/// Bottom Sheet para refinanciar un cliente.
class RefinanceBottomSheet extends StatefulWidget {
  final TodayClient todayClient;

  const RefinanceBottomSheet({
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
        child: RefinanceBottomSheet(todayClient: todayClient),
      ),
    );
  }

  @override
  State<RefinanceBottomSheet> createState() => _RefinanceBottomSheetState();
}

class _RefinanceBottomSheetState extends State<RefinanceBottomSheet> {
  final _amountController = TextEditingController(text: '0');
  final _noteController = TextEditingController();

  RefinanceType _selectedType = RefinanceType.money;
  RefinanceMethod _selectedMethod = RefinanceMethod.cash;
  String? _imagePath;
  bool _isLoading = false;

  // Para "Dar tiempo"
  Map<String, dynamic> _newPaymentDays = {};

  @override
  void initState() {
    super.initState();
    _newPaymentDays = Map.from(widget.todayClient.client.paymentDays);
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
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.currency_exchange_outlined,
                      color: Colors.purple.shade600,
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de refinanciamiento
                  Text(
                    'Tipo de refinanciamiento',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton(
                          label: 'Dar dinero',
                          icon: Icons.payments_outlined,
                          type: RefinanceType.money,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeButton(
                          label: 'Dar tiempo',
                          icon: Icons.schedule_outlined,
                          type: RefinanceType.time,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Contenido según tipo
                  if (_selectedType == RefinanceType.money)
                    _buildMoneyFields(context)
                  else
                    _buildTimeFields(context),

                  const SizedBox(height: 20),

                  // Nota opcional
                  Text(
                    'Nota (opcional)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ej: Cliente solicitó prórroga...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón refinanciar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _refinance,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
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
                          : const Icon(Icons.currency_exchange_outlined),
                      label: Text(
                        _isLoading ? 'Procesando...' : 'Refinanciar',
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

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required RefinanceType type,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade600 : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.purple.shade600
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
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyFields(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Monto
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            labelText: 'Monto entregado',
            prefixText: '₡ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Método de pago
        Text(
          'Forma de entrega',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMethodButton(
                label: 'Efectivo',
                icon: Icons.payments_outlined,
                method: RefinanceMethod.cash,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMethodButton(
                label: 'Transferencia',
                icon: Icons.phone_android_outlined,
                method: RefinanceMethod.transfer,
              ),
            ),
          ],
        ),

        // Imagen comprobante
        if (_selectedMethod == RefinanceMethod.transfer) ...[
          const SizedBox(height: 16),
          if (_imagePath != null)
            _buildImagePreview()
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
      ],
    );
  }

  Widget _buildTimeFields(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final client = widget.todayClient.client;

    if (client.paymentType == PaymentType.daily) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Los clientes diarios no tienen un día fijo de cobro. '
                'Usa "Dar dinero" para registrar un refinanciamiento.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de nueva fecha según tipo
        Text(
          'Nuevo día de cobro',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),

        if (client.paymentType == PaymentType.weekly)
          _buildWeeklySelector()
        else if (client.paymentType == PaymentType.biweekly)
          _buildBiweeklySelector()
        else if (client.paymentType == PaymentType.monthly)
          _buildMonthlySelector(),

        const SizedBox(height: 20),

        // Monto opcional para dar tiempo
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Monto entregado (opcional)',
            prefixText: '₡ ',
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentDay = _newPaymentDays['day'] as String? ?? 'mon';

    const days = [
      {'key': 'mon', 'label': 'Lun'},
      {'key': 'tue', 'label': 'Mar'},
      {'key': 'wed', 'label': 'Mié'},
      {'key': 'thu', 'label': 'Jue'},
      {'key': 'fri', 'label': 'Vie'},
      {'key': 'sat', 'label': 'Sáb'},
      {'key': 'sun', 'label': 'Dom'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final isSelected = currentDay == day['key'];
        return GestureDetector(
          onTap: () => setState(
            () => _newPaymentDays = {'day': day['key']},
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.purple.shade600 : colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.purple.shade600
                    : colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: Text(
                day['label']!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBiweeklySelector() {
    final theme = Theme.of(context);
    final dates = List<int>.from(
      _newPaymentDays['dates'] as List? ?? [1, 15],
    );
    final dayOptions = List.generate(31, (i) => i + 1);

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: dates[0],
            decoration: InputDecoration(
              labelText: 'Primera fecha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: dayOptions
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('Día $d'),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(
                  () => _newPaymentDays = {
                    'dates': [val, dates[1]]
                  },
                );
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: dates[1],
            decoration: InputDecoration(
              labelText: 'Segunda fecha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: dayOptions
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('Día $d'),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(
                  () => _newPaymentDays = {
                    'dates': [dates[0], val]
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySelector() {
    final selectedDate = _newPaymentDays['date'] as int? ?? 1;
    final dayOptions = List.generate(31, (i) => i + 1);

    return DropdownButtonFormField<int>(
      value: selectedDate,
      decoration: InputDecoration(
        labelText: 'Nuevo día del mes',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: dayOptions
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text('Día $d'),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _newPaymentDays = {'date': val});
        }
      },
    );
  }

  Widget _buildMethodButton({
    required String label,
    required IconData icon,
    required RefinanceMethod method,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedMethod = method;
        if (method == RefinanceMethod.cash && _imagePath != null) {
          ImageHelper.deleteImage(_imagePath!);
          _imagePath = null;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
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
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Future<void> _refinance() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<TodayProvider>();
      final amount = double.tryParse(_amountController.text) ?? 0;
      final dateStr = provider.formatDatePublic(provider.selectedDate);

      final refinance = RefinanceModel(
        id: const Uuid().v4(),
        clientId: widget.todayClient.client.id,
        routeId: provider.currentRouteId,
        amount: amount,
        method: _selectedMethod,
        type: _selectedType,
        imagePath: _imagePath,
        newPaymentDate: _selectedType == RefinanceType.time
            ? jsonEncode(_newPaymentDays)
            : null,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        refinanceDate: dateStr,
        createdAt: DateTime.now().toIso8601String(),
      );

      await provider.refinanceClient(
        widget.todayClient,
        refinance,
        newPaymentDays:
            _selectedType == RefinanceType.time ? _newPaymentDays : null,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error refinanciando: $e');
    }
  }
}
