part of '../pages/water_page.dart';

class TodaysLogSection extends StatelessWidget {
  final WaterProvider provider;

  const TodaysLogSection({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final logs = provider.todayIntake?.logs ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY\'S LOG',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: themeProvider.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (logs.isNotEmpty)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${logs.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: themeProvider.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Log Items
          if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No entries yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: themeProvider.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...logs
                .map((log) => WaterLogItem(
                      key: ValueKey(log.id),
                      log: log,
                      provider: provider,
                    ))
                .toList()
                .reversed, // Show newest first
        ],
      ),
    );
  }
}
