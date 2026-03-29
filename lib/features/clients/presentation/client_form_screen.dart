import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../domain/client_model.dart';
import 'client_provider.dart';
import 'widgets/payment_type_selector.dart';
import 'widgets/payment_config_widget.dart';

class ClientFormScreen extends StatefulWidget {
  final String routeId;
  final ClientModel? client; // null = crear, not null = editar

  const ClientFormScreen({
    super.key,
    required this.routeId,
    this.client,
  });

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _creditController = TextEditingController();

  late PaymentType _selectedType;
  late Map<String, dynamic> _paymentDays;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.client!.name;
      _creditController.text = widget.client!.credit.toString();
      _selectedType = widget.client!.paymentType;
      _paymentDays = Map.from(widget.client!.paymentDays);
    } else {
      _selectedType = PaymentType.daily;
      _paymentDays = {
        'days': ['mon', 'tue', 'wed', 'thu', 'fri', 'sat']
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  void _onPaymentTypeChanged(PaymentType type) {
    setState(() {
      _selectedType = type;
      // Resetear paymentDays con valores por defecto según el tipo
      switch (type) {
        case PaymentType.daily:
          _paymentDays = {
            'days': ['mon', 'tue', 'wed', 'thu', 'fri', 'sat']
          };
          break;
        case PaymentType.weekly:
          _paymentDays = {'day': 'mon'};
          break;
        case PaymentType.biweekly:
          _paymentDays = {
            'dates': [1, 15]
          };
          break;
        case PaymentType.monthly:
          _paymentDays = {'date': 1};
          break;
      }
    });
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClientProvider>();

    final client = ClientModel(
      id: _isEditing ? widget.client!.id : const Uuid().v4(),
      routeId: widget.routeId,
      name: _nameController.text.trim(),
      credit: double.parse(_creditController.text.trim()),
      paymentType: _selectedType,
      paymentDays: _paymentDays,
      position: _isEditing ? widget.client!.position : provider.clients.length,
      isActive: true,
      createdAt: _isEditing
          ? widget.client!.createdAt
          : DateTime.now().toIso8601String(),
    );

    if (_isEditing) {
      await provider.updateClient(client);
    } else {
      await provider.addClient(client);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cliente' : 'Nuevo cliente'),
        actions: [
          TextButton.icon(
            onPressed: _saveClient,
            icon: const Icon(Icons.check),
            label: const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Nombre
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del cliente',
                hintText: 'Ej: Juan Pérez',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Crédito
            TextFormField(
              controller: _creditController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              decoration: InputDecoration(
                labelText: 'Monto del crédito',
                hintText: 'Ej: 50000',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El crédito es requerido';
                }
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Tipo de cobro
            PaymentTypeSelector(
              selected: _selectedType,
              onChanged: _onPaymentTypeChanged,
            ),
            const SizedBox(height: 20),

            // Configuración dinámica
            PaymentConfigWidget(
              paymentType: _selectedType,
              paymentDays: _paymentDays,
              onChanged: (newDays) {
                setState(() => _paymentDays = newDays);
              },
            ),
            const SizedBox(height: 32),

            // Botón guardar
            FilledButton.icon(
              onPressed: _saveClient,
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
              label: Text(_isEditing ? 'Guardar cambios' : 'Crear cliente'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
