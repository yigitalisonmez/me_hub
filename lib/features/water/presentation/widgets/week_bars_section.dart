part of '../pages/water_page.dart';

/// "This week" bars from the redesign board's WaterLive: one column per
/// weekday Mon..Sun, heights relative to the daily goal, today emphasized.
class WeekBarsSection extends StatelessWidget {
  final WaterProvider provider;

  const WeekBarsSection({super.key, required this.provider});

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final weekMl = provider.weekMl;
    final goal = provider.dailyGoalMl;
    final todayIndex = DateTime.now().weekday - 1;

    final elapsed = todayIndex + 1;
    final avgLiters =
        weekMl.take(elapsed).fold<int>(0, (sum, ml) => sum + ml) /
        elapsed /
        1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'This week',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${avgLiters.toStringAsFixed(1)} L avg',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: themeProvider.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 88,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            end: goal > 0
                                ? (weekMl[i] / goal).clamp(0.04, 1.0)
                                : 0.04,
                          ),
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutCubic,
                          builder: (context, fraction, _) =>
                              FractionallySizedBox(
                                heightFactor: fraction,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: i == todayIndex
                                        ? AppColors.waterDeep
                                        : i < todayIndex
                                        ? AppColors.water.withValues(
                                            alpha: 0.45,
                                          )
                                        : themeProvider.textTertiary.withValues(
                                            alpha: 0.14,
                                          ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                      bottom: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      if (i != 6) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    Expanded(
                      child: Text(
                        _dayLetters[i],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: i == todayIndex
                              ? AppColors.waterDeep
                              : themeProvider.textTertiary,
                          fontWeight: i == todayIndex
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (i != 6) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
