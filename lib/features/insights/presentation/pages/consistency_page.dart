import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';
import '../../data/services/insights_data_service.dart';
import '../../domain/entities/consistency_summary.dart';

/// Consistency screen: GitHub-style habit heatmap with streak hero, tappable
/// day detail, and month stats. Mirrors the redesign board's HeatmapScreen.
class ConsistencyPage extends StatefulWidget {
  const ConsistencyPage({super.key});

  @override
  State<ConsistencyPage> createState() => _ConsistencyPageState();
}

class _ConsistencyPageState extends State<ConsistencyPage> {
  ConsistencySummary? _summary;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await InsightsDataService().loadConsistency();
    if (!mounted) return;
    final today = DateTime.now();
    final todayIndex = summary.days.indexWhere(
      (d) =>
          d.date.year == today.year &&
          d.date.month == today.month &&
          d.date.day == today.day,
    );
    setState(() {
      _summary = summary;
      _selectedIndex = todayIndex >= 0 ? todayIndex : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final summary = _summary;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const PageHeader(
                title: 'Consistency',
                subtitle: 'Every small day counts',
                showBackButton: true,
              ),
              const SizedBox(height: 20),
              if (summary == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _StreakHero(summary: summary),
                const SizedBox(height: 16),
                _HeatmapCard(
                  summary: summary,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
                const SizedBox(height: 14),
                if (_selectedIndex != null)
                  _DayDetail(day: summary.days[_selectedIndex!]),
                const SizedBox(height: 14),
                _StatsRow(summary: summary),
              ],
              SizedBox(height: LayoutConstants.getNavbarClearance(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  final ConsistencySummary summary;

  const _StreakHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final streak = summary.currentStreak;
    final isRecord = streak > 0 && streak >= summary.bestStreak;
    final tint = theme.isDarkMode
        ? Color.alphaBlend(
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.darkCard,
          )
        : AppColors.terraTint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -0.6,
                    ),
                    children: [
                      TextSpan(
                        text: '$streak ',
                        style: const TextStyle(color: AppColors.primaryDeep),
                      ),
                      TextSpan(
                        text: 'day streak',
                        style: TextStyle(color: theme.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak == 0
                      ? 'Log anything today to start a new streak.'
                      : isRecord
                      ? 'Your longest yet. Keep the rhythm.'
                      : 'Best so far: ${summary.bestStreak} days.',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.flame,
              color: AppColors.primaryDeep,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final ConsistencySummary summary;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _HeatmapCard({
    required this.summary,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _dayLetters = ['M', '', 'W', '', 'F', '', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final weeks = summary.days.length ~/ 7;

    return ElevatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _monthLabels(theme, weeks),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  for (final letter in _dayLetters)
                    SizedBox(
                      width: 14,
                      height: 18,
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: theme.textTertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Expanded(child: _grid(theme, weeks)),
            ],
          ),
          const SizedBox(height: 12),
          _legend(theme),
        ],
      ),
    );
  }

  Widget _monthLabels(ThemeProvider theme, int weeks) {
    final labels = List<String>.filled(weeks, '');
    int? lastMonth;
    for (var week = 0; week < weeks; week++) {
      final monday = summary.days[week * 7].date;
      if (lastMonth != monday.month) {
        // Skip a label on the very first column when it would crowd the next.
        labels[week] = _monthNames[monday.month - 1];
        lastMonth = monday.month;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
        ],
      ),
    );
  }

  /// 7 rows (Mon..Sun) by [weeks] columns, matching the design board grid.
  Widget _grid(ThemeProvider theme, int weeks) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return Column(
      children: [
        for (var row = 0; row < 7; row++)
          SizedBox(
            height: 18,
            child: Row(
              children: [
                for (var week = 0; week < weeks; week++)
                  Expanded(child: _cell(theme, week * 7 + row, todayDate)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(ThemeProvider theme, int index, DateTime todayDate) {
    final day = summary.days[index];
    final isFuture = day.date.isAfter(todayDate);
    final isSelected = index == selectedIndex;
    final cell = Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isFuture ? Colors.transparent : _levelColor(theme, day.level),
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? Border.all(color: theme.textPrimary, width: 1.6)
            : day.level == 0 && !isFuture
            ? Border.all(color: _hairline(theme))
            : null,
      ),
    );
    return GestureDetector(
      onTap: isFuture ? null : () => onSelect(index),
      // Design spec: the selected cell scales up 1.25x above its neighbors.
      child: isSelected ? Transform.scale(scale: 1.25, child: cell) : cell,
    );
  }

  /// Design spec: empty cells are surface-2 (a step darker than the card),
  /// levels 1-3 mix terracotta into the surface at 22/46/72%, and level 4 is
  /// solid terracotta-deep.
  static Color _levelColor(ThemeProvider theme, int level) {
    if (level == 0) {
      return theme.isDarkMode ? AppColors.darkSurface : AppColors.surfaceAlt;
    }
    if (level == 4) return AppColors.primaryDeep;
    final t = [0.0, 0.22, 0.46, 0.72][level];
    return Color.lerp(theme.cardColor, AppColors.primary, t)!;
  }

  /// Design hairline token: ink at 8%.
  static Color _hairline(ThemeProvider theme) =>
      theme.textPrimary.withValues(alpha: 0.08);

  Widget _legend(ThemeProvider theme) {
    Widget swatch(int level) => Container(
      width: 11,
      height: 11,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: _levelColor(theme, level),
        borderRadius: BorderRadius.circular(3),
        border: level == 0 ? Border.all(color: _hairline(theme)) : null,
      ),
    );
    final labelStyle = TextStyle(
      color: theme.textTertiary,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: labelStyle),
        const SizedBox(width: 5),
        for (var level = 0; level <= 4; level++) swatch(level),
        const SizedBox(width: 5),
        Text('More', style: labelStyle),
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  final DayConsistency day;

  const _DayDetail({required this.day});

  static const _titles = [
    'Rest day',
    'A light day',
    'A steady day',
    'A strong day',
    'A perfect day',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final percent = [0, 30, 55, 80, 100][day.level];
    return ElevatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.isDarkMode
                  ? Color.alphaBlend(
                      AppColors.primary.withValues(alpha: 0.14),
                      AppColors.darkCard,
                    )
                  : AppColors.terraTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${day.date.day}',
                style: GoogleFonts.bricolageGrotesque(
                  color: AppColors.primaryDeep,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[day.level],
                  style: GoogleFonts.bricolageGrotesque(
                    color: theme.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.habitsCompleted == 0
                      ? 'Nothing logged — that’s okay.'
                      : '${day.habitsCompleted} of 5 habits completed',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$percent%',
            style: GoogleFonts.bricolageGrotesque(
              color: AppColors.primaryDeep,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ConsistencySummary summary;

  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    Widget stat(String value, String label) => Expanded(
      child: ElevatedCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.bricolageGrotesque(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        stat('${(summary.monthCompletion * 100).round()}%', 'This month'),
        const SizedBox(width: 10),
        stat('${summary.bestStreak}', 'Best streak'),
        const SizedBox(width: 10),
        stat('${summary.activeDays}', 'Active days'),
      ],
    );
  }
}
