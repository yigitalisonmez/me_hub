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
    final isDark = themeProvider.isDarkMode;

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.start,
      lineXY: 0.0,
      indicatorStyle: IndicatorStyle(
        width: 28,
        height: 28,
        drawGap: true,
        indicator: GestureDetector(
          onTap: isEnabled
              ? () => provider.toggleItemCheckedToday(routine.id, item.id)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isToday
                  ? themeProvider.primaryColor
                  : themeProvider.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isToday
                    ? themeProvider.primaryColor
                    : (isEnabled
                          ? themeProvider.primaryColor.withValues(alpha: 0.3)
                          : themeProvider.borderColor.withValues(alpha: 0.3)),
                width: 2,
              ),
              boxShadow: null,
            ),
            child: Center(
              child: isToday
                  ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
                  : (isEnabled
                        ? null
                        : Icon(
                            LucideIcons.lock,
                            color: themeProvider.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                            size: 14,
                          )),
            ),
          ),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: isToday
            ? themeProvider.primaryColor
            : themeProvider.primaryColor.withValues(alpha: 0.15),
        thickness: 2,
      ),
      afterLineStyle: LineStyle(
        color: isToday
            ? themeProvider.primaryColor
            : themeProvider.primaryColor.withValues(alpha: 0.15),
        thickness: 2,
      ),
      endChild: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 12, top: 4),
        child: Opacity(
          opacity: (isEnabled && !isToday) ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                // Bevel Effect for Items (Subtle)
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.white,
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : themeProvider.primaryColor.withValues(alpha: 0.05),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Row(
              children: [
                if (item.iconCodePoint != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? themeProvider.primaryColor.withValues(alpha: 0.1)
                          : themeProvider.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      RoutineIcons.getIconFromCodePoint(item.iconCodePoint!) ??
                          LucideIcons.circle,
                      color: isEnabled
                          ? themeProvider.primaryColor
                          : themeProvider.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? themeProvider.textPrimary
                          : themeProvider.textSecondary,
                      decoration: isToday ? TextDecoration.lineThrough : null,
                      decorationColor: isEnabled
                          ? themeProvider.textPrimary
                          : themeProvider.textSecondary,
                    ),
                  ),
                ),
                if (!isEnabled)
                  Icon(
                    LucideIcons.lock,
                    color: themeProvider.textSecondary.withValues(alpha: 0.3),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
