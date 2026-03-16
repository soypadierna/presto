import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:presto/features/report/presentation/stats_provider.dart';
import 'package:presto/features/report/presentation/stats_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/error/error_listener.dart';
import '../../routes/domain/route_model.dart';
import 'report_provider.dart';
import '../../today/presentation/today_provider.dart';
import 'widgets/report_summary_card.dart';
import 'widgets/expense_tile.dart';
import '../domain/report_generator.dart';
import '../../../../core/utils/formatters.dart';

class ReportScreen extends StatefulWidget {
  final RouteModel route;

  const ReportScreen({super.key, required this.route});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with ErrorListenerMixin, AutomaticKeepAliveClientMixin {
  late TextEditingController _baseController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _baseController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReportProvider>();
      if (provider.baseAmount > 0) {
        _baseController.text = provider.baseAmount.toStringAsFixed(0);
      }

      // Escuchar errores
      listenForErrors<ReportProvider>(
        errorSelector: (p) => p.errorMessage,
        clearError: provider.clearError,
      );
    });
  }

  @override
  void dispose() {
    _baseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informe del día'),
            Consumer<ReportProvider>(
              builder: (_, provider, __) => Text(
                Formatters.formatDate(provider.selectedDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Estadísticas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => StatsProvider()..loadStats(widget.route.id),
                  child: StatsScreen(route: widget.route),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Sincronizar base cuando cambie el provider
          if (reportProvider.baseAmount > 0 && _baseController.text.isEmpty) {
            _baseController.text = reportProvider.baseAmount.toStringAsFixed(0);
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _buildBaseSection(context, reportProvider),
              const ReportSummaryCard(),
              _buildExpensesSection(context, reportProvider),
              const SizedBox(height: 24),
              _buildActionButtons(context, reportProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBaseSection(BuildContext context, ReportProvider provider) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Base del día',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _baseController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ingresa la base del día',
                    prefixText: '₡ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(_baseController.text);
                  if (amount != null && amount >= 0) {
                    provider.saveBase(amount);
                    FocusScope.of(context).unfocus();
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection(BuildContext context, ReportProvider provider) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddExpenseDialog(context, provider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        if (provider.expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'Sin gastos registrados',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          ...provider.expenses.map((expense) => ExpenseTile(expense: expense)),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ReportProvider reportProvider,
  ) {
    final todayProvider = context.read<TodayProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () =>
                _copyReport(context, reportProvider, todayProvider),
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copiar informe'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () =>
                _shareReport(context, reportProvider, todayProvider),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartir informe'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateReport(
    ReportProvider reportProvider,
    TodayProvider todayProvider,
  ) {
    return ReportGenerator.generate(
      routeName: widget.route.name,
      date: reportProvider.selectedDate,
      todayClients: todayProvider.todayClients,
      expenses: reportProvider.expenses,
      dailyBase: reportProvider.dailyBase,
    );
  }

  Future<void> _copyReport(
    BuildContext context,
    ReportProvider reportProvider,
    TodayProvider todayProvider,
  ) async {
    final text = _generateReport(reportProvider, todayProvider);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
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

  Future<void> _shareReport(
    BuildContext context,
    ReportProvider reportProvider,
    TodayProvider todayProvider,
  ) async {
    final text = _generateReport(reportProvider, todayProvider);
    await Share.share(text, subject: 'Informe Presto — ${widget.route.name}');
  }

  Future<void> _showAddExpenseDialog(
    BuildContext context,
    ReportProvider provider,
  ) async {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo gasto'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Gasolina',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '₡ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                provider.addExpense(
                  descController.text.trim(),
                  double.parse(amountController.text),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
