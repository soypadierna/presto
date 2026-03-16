import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/backup/backup_validator.dart';
import '../../../core/utils/formatters.dart';

enum _BackupState { idle, loading, success, error }

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  _BackupState _exportState = _BackupState.idle;
  _BackupState _importState = _BackupState.idle;
  String? _exportedFilePath;
  String? _exportMessage;
  String? _importMessage;
  String? _exportError;
  String? _importError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo y restauración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info general
          Container(
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
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Los respaldos guardan todos tus datos: rutas, '
                    'clientes, pagos y gastos en un archivo .presto',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle(context, 'Exportar datos'),
          const SizedBox(height: 10),
          _buildExportCard(context),
          const SizedBox(height: 20),

          _buildSectionTitle(context, 'Importar datos'),
          const SizedBox(height: 10),
          _buildImportCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildExportCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.upload_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear respaldo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Guarda una copia de todos tus datos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_exportState == _BackupState.success) ...[
            const SizedBox(height: 14),
            _buildStatusMessage(
              context: context,
              message: _exportMessage ?? 'Respaldo creado exitosamente',
              isError: false,
            ),
          ],
          if (_exportState == _BackupState.error) ...[
            const SizedBox(height: 14),
            _buildStatusMessage(
              context: context,
              message: _exportError ?? 'Error al crear respaldo',
              isError: true,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportState == _BackupState.loading
                      ? null
                      : _createBackup,
                  icon: _exportState == _BackupState.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _exportState == _BackupState.loading
                        ? 'Creando...'
                        : 'Crear respaldo',
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (_exportedFilePath != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareBackup,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Compartir'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.download_outlined,
                  color: Colors.orange.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurar respaldo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Selecciona un archivo .presto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Advertencia
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atención: importar un respaldo reemplazará '
                    'todos los datos actuales. Esta acción no se puede deshacer.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_importState == _BackupState.success) ...[
            const SizedBox(height: 14),
            _buildStatusMessage(
              context: context,
              message: _importMessage ?? 'Datos restaurados exitosamente',
              isError: false,
            ),
          ],
          if (_importState == _BackupState.error) ...[
            const SizedBox(height: 14),
            _buildStatusMessage(
              context: context,
              message: _importError ?? 'Error al importar respaldo',
              isError: true,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _importState == _BackupState.loading
                  ? null
                  : _selectAndImportBackup,
              icon: _importState == _BackupState.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.folder_open_outlined, size: 18),
              label: Text(
                _importState == _BackupState.loading
                    ? 'Validando...'
                    : 'Seleccionar archivo .presto',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage({
    required BuildContext context,
    required String message,
    required bool isError,
  }) {
    final color =
        isError ? Colors.red.shade600 : Colors.green.shade600;
    final bgColor = isError
        ? Colors.red.withValues(alpha: 0.08)
        : Colors.green.withValues(alpha: 0.08);
    final icon =
        isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _exportState = _BackupState.loading;
      _exportError = null;
      _exportMessage = null;
    });

    try {
      final path = await BackupService.exportBackup();
      final fileName = path.split('/').last;
      setState(() {
        _exportState = _BackupState.success;
        _exportedFilePath = path;
        _exportMessage = 'Archivo creado: $fileName';
      });
    } catch (e) {
      setState(() {
        _exportState = _BackupState.error;
        _exportError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _shareBackup() async {
    if (_exportedFilePath == null) return;
    try {
      await BackupService.shareBackup(_exportedFilePath!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al compartir: '
              '${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _selectAndImportBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      // Verificar extensión
      if (!filePath.endsWith('.presto')) {
        setState(() {
          _importState = _BackupState.error;
          _importError =
              'El archivo seleccionado no es un respaldo válido (.presto)';
        });
        return;
      }

      // Validar el archivo ANTES de mostrar la confirmación
      setState(() => _importState = _BackupState.loading);

      final validation = await BackupService.validateOnly(filePath);

      if (!validation.isValid) {
        setState(() {
          _importState = _BackupState.error;
          _importError = validation.errorMessage;
        });
        return;
      }

      // Mostrar confirmación con información del respaldo
      if (!mounted) return;
      final confirmed = await _showImportConfirmation(validation.info!);
      if (!mounted || confirmed != true) {
        setState(() => _importState = _BackupState.idle);
        return;
      }

      setState(() => _importState = _BackupState.loading);
      await BackupService.importBackup(filePath);

      if (mounted) {
        setState(() {
          _importState = _BackupState.success;
          _importMessage =
              'Datos restaurados correctamente. '
              'Reinicia la app para ver los cambios.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importState = _BackupState.error;
          _importError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<bool?> _showImportConfirmation(BackupInfo info) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Restaurar respaldo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción reemplazará TODOS los datos actuales. '
              'No se puede deshacer.',
            ),
            const SizedBox(height: 16),
            // Info del respaldo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contenido del respaldo:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context: ctx,
                    icon: Icons.route_outlined,
                    label: 'Rutas',
                    value: '${info.routeCount}',
                  ),
                  _buildInfoRow(
                    context: ctx,
                    icon: Icons.people_outline,
                    label: 'Clientes activos',
                    value: '${info.clientCount}',
                  ),
                  _buildInfoRow(
                    context: ctx,
                    icon: Icons.payments_outlined,
                    label: 'Pagos registrados',
                    value: '${info.paymentCount}',
                  ),
                  _buildInfoRow(
                    context: ctx,
                    icon: Icons.receipt_outlined,
                    label: 'Gastos',
                    value: '${info.expenseCount}',
                  ),
                  if (info.oldestDate != null &&
                      info.newestDate != null) ...[
                    _buildInfoRow(
                      context: ctx,
                      icon: Icons.calendar_today_outlined,
                      label: 'Período',
                      value:
                          '${Formatters.formatShortDate(DateTime.parse(info.oldestDate!))} '
                          '— ${Formatters.formatShortDate(DateTime.parse(info.newestDate!))}',
                    ),
                  ],
                  _buildInfoRow(
                    context: ctx,
                    icon: Icons.storage_outlined,
                    label: 'Tamaño',
                    value: '${info.fileSizeKb} KB',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}