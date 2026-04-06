import 'package:flutter/material.dart';
import 'package:presto/features/clients/domain/client_model.dart';
import 'package:provider/provider.dart';
import '../../domain/today_client.dart';
import '../../domain/payment_model.dart';
import '../today_provider.dart';
import '../../../../../core/utils/formatters.dart';
import 'payment_bottom_sheet.dart';
import 'skipped_bottom_sheet.dart';
import 'refinance_bottom_sheet.dart';

class TodayClientTile extends StatelessWidget {
  final TodayClient todayClient;
  final VoidCallback? onBeforeAction;
  final VoidCallback? onAfterAction;
  final int orderIndex;

  const TodayClientTile({
    super.key,
    required this.todayClient,
    required this.orderIndex,
    this.onBeforeAction,
    this.onAfterAction,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TodayProvider>();

    if (!todayClient.isPending) {
      return GestureDetector(
        onLongPress: () => _showUndoConfirmation(context, provider),
        child: _buildTile(context),
      );
    }

    return Dismissible(
      key: Key('today_${todayClient.client.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onBeforeAction?.call();
          if (context.mounted) {
            await SkippedBottomSheet.show(
              context,
              todayClient,
              provider: provider,
              onAfterAction: onAfterAction,
            );
          }
        } else {
          onBeforeAction?.call();
          if (context.mounted) {
            await PaymentBottomSheet.show(
              context,
              todayClient,
              provider: provider,
              onAfterAction: onAfterAction,
            );
          }
        }
        return false;
      },
      background: _buildSwipeBg(
        color: const Color(0xFF3B6D11),
        icon: Icons.attach_money,
        label: 'Pagó',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBg(
        color: const Color(0xFFA32D2D),
        icon: Icons.money_off_outlined,
        label: 'No dio',
        alignment: Alignment.centerRight,
      ),
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context, provider),
        child: _buildTile(context),
      ),
    );
  }

  // ── Tile principal ───────────────────────────────────────

  Widget _buildTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _tileBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _tileBorder(context),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            _buildCircle(context),
            const SizedBox(width: 10),
            Expanded(child: _buildCenter(context)),
            const SizedBox(width: 10),
            _buildRight(context),
          ],
        ),
      ),
    );
  }

  // ── Círculo de estado ────────────────────────────────────

  Widget _buildCircle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (todayClient.isPaid) {
      return _circle(
        bg: isDark
            ? const Color(0xFF1A2E10) // dark — verde muy oscuro
            : const Color(0xFF3B6D11), // light — c-green 600
        child: _svgCheck(Colors.white),
      );
    }

    if (todayClient.isSkipped) {
      return _circle(
        bg: isDark
            ? const Color(0xFF2E1212) // dark — rojo muy oscuro
            : const Color(0xFFA32D2D), // light — c-red 600
        child: _svgX(Colors.white),
      );
    }

    if (todayClient.isRefinanced) {
      return _circle(
        bg: isDark
            ? const Color(0xFF2A1E08) // dark — ámbar muy oscuro
            : const Color(0xFF854F0B), // light — c-amber 600
        child: _svgRefresh(Colors.white),
      );
    }

    // Pendiente y reagendado — número de orden
    return _circle(
      bg: isDark
          ? const Color(0xFF444441) // c-gray 700
          : const Color(0xFFE8E6DF),
      child: Text(
        '${_orderNumber()}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark
              ? const Color(0xFFB4B2A9) // c-gray 200
              : const Color(0xFF5F5E5A), // c-gray 600
        ),
      ),
    );
  }

  Widget _circle({required Color bg, required Widget child}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }

  // ── SVG íconos ───────────────────────────────────────────

  Widget _svgCheck(Color color) {
    return CustomPaint(
      size: const Size(14, 14),
      painter: _IconPainter(
        color: color,
        draw: (canvas, paint, size) {
          final path = Path()
            ..moveTo(size.width * 0.15, size.height * 0.52)
            ..lineTo(size.width * 0.42, size.height * 0.78)
            ..lineTo(size.width * 0.85, size.height * 0.22);
          canvas.drawPath(path, paint);
        },
      ),
    );
  }

  Widget _svgX(Color color) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: _IconPainter(
        color: color,
        draw: (canvas, paint, size) {
          canvas.drawLine(
            Offset(size.width * 0.2, size.height * 0.2),
            Offset(size.width * 0.8, size.height * 0.8),
            paint,
          );
          canvas.drawLine(
            Offset(size.width * 0.8, size.height * 0.2),
            Offset(size.width * 0.2, size.height * 0.8),
            paint,
          );
        },
      ),
    );
  }

  Widget _svgRefresh(Color color) {
    return Icon(
      Icons.currency_exchange_outlined,
      size: 15,
      color: color,
    );
  }

  // ── Centro ───────────────────────────────────────────────

  Widget _buildCenter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color del nombre según estado y modo
    final Color nameColor;
    if (todayClient.isPending) {
      nameColor = isDark ? const Color(0xFFEEEEE8) : const Color(0xFF1A1A16);
    } else if (todayClient.isPaid) {
      nameColor = isDark
          ? const Color(0xFF9A9A92) // atenuado en oscuro
          : const Color(0xFF173404); // c-green 900 en claro
    } else if (todayClient.isSkipped) {
      nameColor = isDark
          ? const Color(0xFF9A9A92) // atenuado en oscuro
          : const Color(0xFF501313); // c-red 900 en claro
    } else if (todayClient.isRefinanced) {
      nameColor = isDark
          ? const Color(0xFF9A9A92) // atenuado en oscuro
          : const Color(0xFF412402); // c-amber 900 en claro
    } else {
      nameColor = isDark ? const Color(0xFFEEEEE8) : const Color(0xFF1A1A16);
    }

    // Color del subtexto según estado y modo
    final Color subColor;
    if (todayClient.isPaid) {
      subColor = isDark
          ? const Color(0xFF606058)
          : const Color(0xFF27500A); // c-green 800
    } else if (todayClient.isSkipped) {
      subColor = isDark
          ? const Color(0xFF606058)
          : const Color(0xFF791F1F); // c-red 800
    } else if (todayClient.isRefinanced) {
      subColor = isDark
          ? const Color(0xFF606058)
          : const Color(0xFF633806); // c-amber 800
    } else {
      subColor = isDark ? const Color(0xFF606058) : const Color(0xFF8A8A80);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nombre + badge reagendado
        Row(
          children: [
            Flexible(
              child: Text(
                todayClient.client.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: nameColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (todayClient.isRescheduled) ...[
              const SizedBox(width: 6),
              _buildRescheduledBadge(isDark),
            ],
          ],
        ),
        const SizedBox(height: 2),
        // Subtexto
        Row(
          children: [
            Text(
              _subtextLeft(),
              style: TextStyle(fontSize: 11, color: subColor),
            ),
            if (_showSinpeBadge()) ...[
              const SizedBox(width: 5),
              _buildSinpeBadge(isDark),
            ],
          ],
        ),
      ],
    );
  }

  String _subtextLeft() {
    if (todayClient.isPaid) {
      final method =
          todayClient.payment?.paymentMethod == PaymentMethod.transfer
              ? 'Transferencia'
              : 'Efectivo';
      final time = _formatTime(todayClient.payment?.createdAt);
      return time.isNotEmpty ? '$method · $time' : method;
    }
    if (todayClient.isSkipped) {
      return todayClient.payment?.note?.isNotEmpty == true
          ? todayClient.payment!.note!
          : '${Formatters.formatAmount(todayClient.client.credit)} · ${_paymentTypeLabel()}';
    }
    if (todayClient.isRefinanced) {
      return '${Formatters.formatAmount(todayClient.client.credit)} · Refinanciado';
    }
    return '${Formatters.formatAmount(todayClient.client.credit)} · ${_paymentTypeLabel()}';
  }

  bool _showSinpeBadge() {
    return todayClient.isPaid &&
        todayClient.payment?.paymentMethod == PaymentMethod.transfer;
  }

  Widget _buildSinpeBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A2E10)
            : const Color(0xFF3B6D11), // c-green 600
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A4818)
              : const Color(0xFF27500A), // c-green 800
          width: 0.5,
        ),
      ),
      child: Text(
        'SINPE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRescheduledBadge(bool isDark) {
    final date = DateTime.parse(
      todayClient.scheduledPayment!.scheduledDate,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF181428)
            : const Color(0xFFEEEDFE), // c-purple 50
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E2858)
              : const Color(0xFFAFA9EC), // c-purple 200
          width: 0.5,
        ),
      ),
      child: Text(
        Formatters.formatShortDateNavigator(date).toLowerCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isDark
              ? const Color(0xFFA898E8)
              : const Color(0xFF3C3489), // c-purple 800
        ),
      ),
    );
  }

  // ── Derecha ──────────────────────────────────────────────

  Widget _buildRight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (todayClient.isPaid) {
      return Text(
        Formatters.formatAmount(todayClient.payment?.amount ?? 0),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark
              ? const Color(0xFF6AAF38) // verde claro en oscuro
              : const Color(0xFF173404), // c-green 900 en claro
        ),
      );
    }

    if (todayClient.isSkipped) {
      return Text(
        'No dio',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark
              ? const Color(0xFFC04848) // rojo claro en oscuro
              : const Color(0xFF501313), // c-red 900 en claro
        ),
      );
    }

    if (todayClient.isRefinanced) {
      return Text(
        'Refinanc.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark
              ? const Color(0xFFC08018) // ámbar claro en oscuro
              : const Color(0xFF412402), // c-amber 900 en claro
        ),
      );
    }

    // Pendiente y reagendado
    return Text(
      Formatters.formatAmount(todayClient.client.credit),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFFEEEEE8) : const Color(0xFF1A1A16),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  int _orderNumber() => orderIndex + 1;

  String _paymentTypeLabel() {
    switch (todayClient.client.paymentType) {
      case PaymentType.daily:
        return 'Diario';
      case PaymentType.weekly:
        return 'Semanal';
      case PaymentType.biweekly:
        return 'Quincenal';
      case PaymentType.monthly:
        return 'Mensual';
    }
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final h = dt.hour > 12
          ? dt.hour - 12
          : dt.hour == 0
              ? 12
              : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }

  Widget _buildSwipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUndoConfirmation(
    BuildContext context,
    TodayProvider provider,
  ) async {
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
    if (confirmed == true) await provider.undoPayment(todayClient);
  }

  Future<void> _showContextMenu(
    BuildContext context,
    TodayProvider provider,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    todayClient.client.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2E10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Color(0xFF6AAF38),
                    size: 20,
                  ),
                ),
                title: const Text('Registrar pago'),
                subtitle: const Text('El cliente pagó hoy'),
                onTap: () async {
                  Navigator.pop(ctx);
                  onBeforeAction?.call();
                  await PaymentBottomSheet.show(
                    context,
                    todayClient,
                    provider: provider,
                    onAfterAction: onAfterAction,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1212),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.money_off_outlined,
                    color: Color(0xFFC04848),
                    size: 20,
                  ),
                ),
                title: const Text('No dio'),
                subtitle: const Text('Registrar que no pagó'),
                onTap: () async {
                  Navigator.pop(ctx);
                  onBeforeAction?.call();
                  await SkippedBottomSheet.show(
                    context,
                    todayClient,
                    provider: provider,
                    onAfterAction: onAfterAction,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1E08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.currency_exchange_outlined,
                    color: Color(0xFFC08018),
                    size: 20,
                  ),
                ),
                title: const Text('Refinanciar'),
                subtitle: const Text('Dar dinero o más tiempo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await RefinanceBottomSheet.show(
                    context,
                    todayClient,
                    provider: provider,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Color _tileBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (todayClient.isPaid) {
      return isDark
          ? const Color(0xFF173404) // c-green 900
          : const Color(0xFF97C459); // c-green 200
    }
    if (todayClient.isSkipped) {
      return isDark
          ? const Color(0xFF501313) // c-red 900
          : const Color(0xFFF09595); // c-red 200
    }
    if (todayClient.isRefinanced) {
      return isDark
          ? const Color(0xFF412402) // c-amber 900
          : const Color(0xFFEF9F27); // c-amber 200
    }

    // Pendiente y reagendado
    return isDark ? const Color(0xFF2C2C2A) : const Color(0xFFFFFFFF);
  }

  Color _tileBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (todayClient.isPaid) {
      return isDark
          ? const Color(0xFF3B6D11) // c-green 600
          : const Color(0xFF639922); // c-green 400
    }
    if (todayClient.isSkipped) {
      return isDark
          ? const Color(0xFFA32D2D) // c-red 600
          : const Color(0xFFE24B4A); // c-red 400
    }
    if (todayClient.isRefinanced) {
      return isDark
          ? const Color(0xFF854F0B) // c-amber 600
          : const Color(0xFFBA7517); // c-amber 400
    }

    // Pendiente y reagendado
    return isDark
        ? const Color(0xFF444441)
        : const Color(0xFFD3D1C7); // c-gray 100
  }
}

// ── CustomPainter para íconos SVG ────────────────────────

class _IconPainter extends CustomPainter {
  final Color color;
  final void Function(Canvas, Paint, Size) draw;

  _IconPainter({required this.color, required this.draw});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    draw(canvas, paint, size);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color;
}
