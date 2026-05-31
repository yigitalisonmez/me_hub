import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/event_category.dart';
import '../providers/calendar_provider.dart';
import '../widgets/add_event_bottom_sheet.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final calendarProvider = context.watch<CalendarProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              PageHeader(
                title: 'Calendar',
                subtitle: 'Month and agenda',
                showBackButton: true,
                actionIcon: LucideIcons.plus,
                onActionTap: () => _addNewEvent(context),
              ),
              const SizedBox(height: 24),
              _MonthSwitcher(provider: calendarProvider),
              const SizedBox(height: 14),
              _CalendarGrid(provider: calendarProvider),
              const SizedBox(height: 22),
              _AgendaSection(
                events: calendarProvider.selectedDayEvents,
                selectedDate: calendarProvider.selectedDate,
                onAdd: () => _addNewEvent(context),
                onTap: (event) => _editEvent(context, event),
                onComplete: calendarProvider.toggleEventCompletion,
                onDelete: (event) => calendarProvider.deleteEvent(event.id),
              ),
              SizedBox(height: LayoutConstants.getNavbarClearance(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addNewEvent(BuildContext context) async {
    final calendarProvider = context.read<CalendarProvider>();
    final result = await EventBottomSheet.showAdd(
      context,
      initialDate: calendarProvider.selectedDate,
    );

    if (!mounted || !context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event added'),
          backgroundColor: AppColors.primaryDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Future<void> _editEvent(BuildContext context, CalendarEvent event) async {
    final result = await EventBottomSheet.showEdit(context, event);
    if (!mounted || !context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event updated'),
          backgroundColor: AppColors.primaryDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }
}

class _MonthSwitcher extends StatelessWidget {
  final CalendarProvider provider;

  const _MonthSwitcher({required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final focusedMonth = provider.focusedMonth;

    return Row(
      children: [
        _RoundIconButton(
          icon: LucideIcons.chevronLeft,
          onTap: provider.goToPreviousMonth,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _monthLabel(focusedMonth),
              key: ValueKey('${focusedMonth.year}-${focusedMonth.month}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        _RoundIconButton(
          icon: LucideIcons.chevronRight,
          onTap: provider.goToNextMonth,
        ),
      ],
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _CalendarGrid extends StatelessWidget {
  final CalendarProvider provider;

  const _CalendarGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final focusedMonth = provider.focusedMonth;
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final leading = firstDay.weekday - 1;
    final totalCells = leading + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return ElevatedCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      borderRadius: 26,
      backgroundColor: themeProvider.cardColor,
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 24,
            ),
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  weekDays[index],
                  style: TextStyle(
                    color: themeProvider.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 43,
              crossAxisSpacing: 2,
              mainAxisSpacing: 3,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              if (dayNumber < 1 || dayNumber > lastDay.day) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                focusedMonth.year,
                focusedMonth.month,
                dayNumber,
              );
              final selected = _isSameDay(date, provider.selectedDate);
              final today = _isSameDay(date, DateTime.now());
              final eventCount = provider.eventCountOnDay(date);

              return _DayCell(
                dayNumber: dayNumber,
                selected: selected,
                today: today,
                eventCount: eventCount,
                onTap: () => provider.selectDate(date),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCell extends StatelessWidget {
  final int dayNumber;
  final bool selected;
  final bool today;
  final int eventCount;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayNumber,
    required this.selected,
    required this.today,
    required this.eventCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryDeep
              : today
              ? AppColors.terraTint
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : today
                    ? AppColors.primaryDeep
                    : themeProvider.textPrimary,
                fontSize: 13,
                fontWeight: selected || today
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(eventCount.clamp(0, 3), (index) {
                  final colors = [
                    AppColors.primary,
                    AppColors.routine,
                    AppColors.water,
                  ];
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? Colors.white : colors[index],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaSection extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final VoidCallback onAdd;
  final ValueChanged<CalendarEvent> onTap;
  final Future<bool> Function(CalendarEvent) onComplete;
  final Future<bool> Function(CalendarEvent) onDelete;

  const _AgendaSection({
    required this.selectedDate,
    required this.events,
    required this.onAdd,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final sorted = [...events]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedDateLabel(selectedDate),
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${events.length} ${events.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          ElevatedCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            onTap: onAdd,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.terraTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: AppColors.primaryDeep,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No agenda items',
                        style: TextStyle(
                          color: themeProvider.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap to add an event for this day.',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...sorted.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AgendaCard(
                event: event,
                onTap: () => onTap(event),
                onComplete: () => onComplete(event),
                onDelete: () => onDelete(event),
              ),
            ),
          ),
      ],
    );
  }

  String _selectedDateLabel(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _AgendaCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final Future<bool> Function() onComplete;
  final Future<bool> Function() onDelete;

  const _AgendaCard({
    required this.event,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final color = _categoryColor(event.categoryId);
    final tag = _categoryLabel(event.categoryId);

    return ElevatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              _formatTime(event.dateTime),
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: event.isCompleted
                        ? themeProvider.textSecondary
                        : themeProvider.textPrimary,
                    decoration: event.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onComplete,
            icon: Icon(
              event.isCompleted ? LucideIcons.circleCheck : LucideIcons.circle,
              color: event.isCompleted ? AppColors.routineDeep : color,
              size: 20,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(
              LucideIcons.x,
              color: themeProvider.textTertiary,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _categoryLabel(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Event';
    return categoryId[0].toUpperCase() + categoryId.substring(1);
  }

  Color _categoryColor(String? categoryId) {
    final normalized = categoryId?.toLowerCase();
    for (final category in PredefinedCategory.values) {
      if (category.name.toLowerCase() == normalized) {
        return category.color;
      }
    }
    if (normalized == 'routine') return AppColors.routine;
    if (normalized == 'task') return AppColors.primaryDeep;
    return AppColors.water;
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: themeProvider.borderColor.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: themeProvider.textSecondary, size: 18),
      ),
    );
  }
}
