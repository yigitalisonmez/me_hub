import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/constants/layout_constants.dart';
import '../providers/calendar_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_bottom_sheet.dart';
import '../../domain/entities/calendar_event.dart';

/// Calendar page with events and reminders
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();

    // FAB animation
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().initialize();
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final calendarProvider = context.watch<CalendarProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with fade in animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PageHeader(
                  title: 'Calendar',
                  subtitle: 'Plan your events',
                  showBackButton: true,
                  actionWidget: IconButton(
                    onPressed: () => calendarProvider.goToToday(),
                    icon: Icon(
                      LucideIcons.calendarCheck,
                      color: themeProvider.primaryColor,
                      size: 22,
                    ),
                    tooltip: 'Go to today',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Month navigation with slide animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildMonthNavigation(
                themeProvider,
                calendarProvider,
                key: ValueKey(calendarProvider.focusedMonth),
              ),
            ),
            const SizedBox(height: 12),

            // Calendar grid with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * value),
                    child: child,
                  ),
                );
              },
              child: _buildCalendarGrid(themeProvider, calendarProvider),
            ),
            const SizedBox(height: 16),

            // Events for selected day
            Expanded(child: _buildEventsList(themeProvider, calendarProvider)),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: () => _addNewEvent(context),
          backgroundColor: themeProvider.primaryColor,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMonthNavigation(
    ThemeProvider themeProvider,
    CalendarProvider calendarProvider, {
    Key? key,
  }) {
    final focusedMonth = calendarProvider.focusedMonth;
    final months = [
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

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: LucideIcons.chevronLeft,
            onPressed: () => calendarProvider.goToPreviousMonth(),
            themeProvider: themeProvider,
          ),
          Text(
            '${months[focusedMonth.month - 1]} ${focusedMonth.year}',
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildNavButton(
            icon: LucideIcons.chevronRight,
            onPressed: () => calendarProvider.goToNextMonth(),
            themeProvider: themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeProvider themeProvider,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: themeProvider.textSecondary, size: 20),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(
    ThemeProvider themeProvider,
    CalendarProvider calendarProvider,
  ) {
    final focusedMonth = calendarProvider.focusedMonth;
    final selectedDate = calendarProvider.selectedDate;

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    );
    final startWeekday = firstDayOfMonth.weekday;
    final daysBeforeMonth = startWeekday - 1;
    final totalDays = daysBeforeMonth + lastDayOfMonth.day;
    final rowCount = (totalDays / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              return SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Days grid with staggered animation
          ...List.generate(rowCount, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (colIndex) {
                  final dayIndex = rowIndex * 7 + colIndex;
                  final dayNumber = dayIndex - daysBeforeMonth + 1;

                  if (dayNumber < 1 || dayNumber > lastDayOfMonth.day) {
                    return const SizedBox(width: 40, height: 40);
                  }

                  final date = DateTime(
                    focusedMonth.year,
                    focusedMonth.month,
                    dayNumber,
                  );
                  final isSelected = _isSameDay(date, selectedDate);
                  final isToday = _isSameDay(date, DateTime.now());
                  final hasEvents = calendarProvider.hasEventsOnDay(date);

                  return _buildDayCell(
                    dayNumber: dayNumber,
                    isSelected: isSelected,
                    isToday: isToday,
                    hasEvents: hasEvents,
                    themeProvider: themeProvider,
                    onTap: () => calendarProvider.selectDate(date),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required int dayNumber,
    required bool isSelected,
    required bool isToday,
    required bool hasEvents,
    required ThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.primaryColor
              : isToday
              ? themeProvider.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeProvider.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              dayNumber.toString(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? themeProvider.primaryColor
                    : themeProvider.textPrimary,
                fontSize: 14,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (hasEvents && !isSelected)
              Positioned(
                bottom: 4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(
    ThemeProvider themeProvider,
    CalendarProvider calendarProvider,
  ) {
    final events = calendarProvider.selectedDayEvents;
    final selectedDate = calendarProvider.selectedDate;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSameDay(selectedDate, DateTime.now())
                    ? "Today's Events"
                    : _formatDateHeader(selectedDate),
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (events.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${events.length} ${events.length == 1 ? 'event' : 'events'}',
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Events list with staggered animation
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState(themeProvider)
                : AnimationLimiter(
                    child: ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: LayoutConstants.getNavbarClearance(context),
                      ),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: EventCard(
                                event: event,
                                onTap: () => _editEvent(context, event),
                                onComplete: () => calendarProvider
                                    .toggleEventCompletion(event),
                                onDelete: () =>
                                    calendarProvider.deleteEvent(event.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendarOff,
              size: 48,
              color: themeProvider.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No events for this day',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add a new event',
              style: TextStyle(
                color: themeProvider.textSecondary.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewEvent(BuildContext context) async {
    final calendarProvider = context.read<CalendarProvider>();
    final selectedDate = calendarProvider.selectedDate;

    // Animate FAB before showing sheet
    await _fabController.reverse();
    if (!mounted || !context.mounted) return;

    final result = await EventBottomSheet.showAdd(
      context,
      initialDate: selectedDate,
    );
    if (!mounted || !context.mounted) return;

    // Animate FAB back
    _fabController.forward();

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event added successfully! 🎉'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
          content: const Text('Event updated successfully! ✨'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}';
  }
}
