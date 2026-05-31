part of '../pages/water_page.dart';

class TodaysLogSection extends StatelessWidget {
  final WaterProvider provider;

  const TodaysLogSection({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final logs = provider.todayIntake?.logs ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's log",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${logs.length} entries',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: themeProvider.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: const EmptyStateWidget(
              message: 'No water logs yet',
              icon: LucideIcons.droplet,
              subMessage: 'Drink water to reach your daily goal.',
            ),
          )
        else
          ...logs.reversed.map(
            (log) => WaterLogItem(
              key: ValueKey(log.id),
              log: log,
              provider: provider,
            ),
          ),
      ],
    );
  }
}
