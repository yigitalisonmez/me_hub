import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/widgets/clay_container.dart';
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
        drawGap: true,
        indicator: GestureDetector(
          onTap: isEnabled
              ? () => provider.toggleItemCheckedToday(routine.id, item.id)
              : null,
          child: ClayContainer(
            borderRadius: 50,
            color: isToday
                ? themeProvider.primaryColor
                : themeProvider.surfaceColor,
            emboss: isToday, // Pressed effect when checked
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
          child: ClayContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: 16,
            color: themeProvider.surfaceColor,
            child: Row(
              children: [
                if (item.iconCodePoint != null) ...[
                  ClayContainer(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 10,
                    color: isEnabled
                        ? themeProvider.primaryColor.withValues(alpha: 0.1)
                        : themeProvider.surfaceColor,
                    emboss: true, // Inset icon
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
