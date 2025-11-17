import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

class RoutineItemWidget extends StatelessWidget {
  final Routine routine;
  final RoutineItem item;
  final RoutinesProvider provider;
  final bool isFirst;
  final bool isLast;
  final bool isEnabled;

  const RoutineItemWidget({
    super.key,
    required this.routine,
    required this.item,
    required this.provider,
    this.isFirst = false,
    this.isLast = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final today = DateTime.now();
    final isToday = item.isCheckedToday(
      DateTime(today.year, today.month, today.day),
    );

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.start,
      lineXY: 0.0,
      indicatorStyle: IndicatorStyle(
        width: 28,
        height: 28,
        indicator: GestureDetector(
          onTap: isEnabled
              ? () => provider.toggleItemCheckedToday(routine.id, item.id)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isToday
                  ? themeProvider.primaryColor
                  : (isEnabled
                      ? themeProvider.cardColor
                      : themeProvider.primaryColor.withValues(alpha: 0.1)),
              border: Border.all(
                color: isToday
                    ? themeProvider.primaryColor
                    : (isEnabled
                        ? themeProvider.borderColor.withValues(alpha: 0.4)
                        : themeProvider.borderColor.withValues(alpha: 0.2)),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isToday
                  ? Icon(LucideIcons.check, color: themeProvider.textPrimary, size: 16)
                  : (isEnabled
                      ? null
                      : Icon(
                          LucideIcons.lock,
                          color: themeProvider.primaryColor.withValues(alpha: 0.3),
                          size: 14,
                        )),
            ),
          ),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: isToday
            ? themeProvider.primaryColor
            : themeProvider.primaryColor.withValues(alpha: 0.2),
        thickness: 2,
      ),
      afterLineStyle: LineStyle(
        color: isToday
            ? themeProvider.primaryColor
            : themeProvider.primaryColor.withValues(alpha: 0.2),
        thickness: 2,
      ),
      endChild: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 12, top: 4),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (item.iconCodePoint != null) ...[
                  Icon(
                    RoutineIcons.getIconFromCodePoint(item.iconCodePoint!) ??
                        LucideIcons.circle,
                    color: isEnabled
                        ? themeProvider.primaryColor
                        : themeProvider.primaryColor.withValues(alpha: 0.3),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? themeProvider.textPrimary
                          : themeProvider.textPrimary.withValues(alpha: 0.4),
                      decoration: isToday ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (!isEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      LucideIcons.lock,
                      color: themeProvider.primaryColor.withValues(alpha: 0.4),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

