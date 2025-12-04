part of '../pages/water_page.dart';
// Note: ElevatedCard is imported in water_page.dart part file or needs to be available.
// Since this is a part file, imports are in water_page.dart.

class TodaysProgressCard extends StatefulWidget {
  final WaterProvider provider;
  final int dailyGoal;
  final List<QuickAddAmount> quickAddAmounts;

  const TodaysProgressCard({
    super.key,
    required this.provider,
    required this.dailyGoal,
    required this.quickAddAmounts,
  });

  @override
  State<TodaysProgressCard> createState() => _TodaysProgressCardState();
}

class _TodaysProgressCardState extends State<TodaysProgressCard> {
  final GlobalKey _statCardKey = GlobalKey();
  double? _statCardWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final progress = widget.provider.todayIntake?.getProgress(dailyGoalMl: widget.dailyGoal) ?? 0.0;
    final percentage = (progress * 100).toInt();
    final glassCount = widget.provider.todayIntake?.logs.length ?? 0;
    final remaining = widget.dailyGoal - widget.provider.todayAmount;

    return ElevatedCard(
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              // Section Header
              Row(
                children: [
                  Icon(
                    LucideIcons.trendingUp,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY\'S PROGRESS',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: themeProvider.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Current Amount
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.provider.todayAmount}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ml',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 24,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Goal
              Center(
                child: Text(
                  'of ${widget.dailyGoal}ml daily goal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: themeProvider.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Horizontal Progress Bar with Wave Effect
              WaveProgressBar(
                progress: progress,
                centerText: '$percentage%',
                bottomText:
                    '${widget.provider.todayAmount} / ${widget.dailyGoal} ml',
              ),
              const SizedBox(height: 20),
              // Three Stat Cards
              Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            key: _statCardKey,
                            child: WaterStatCard(
                              value: '$glassCount',
                              label: 'Cups',
                              theme: theme,
                              themeProvider: themeProvider,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: WaterStatCard(
                              value: '${remaining > 0 ? remaining : 0}',
                              label: 'Remaining',
                              theme: theme,
                              themeProvider: themeProvider,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: WaterStatusCard(
                              label: 'Status',
                              theme: theme,
                              themeProvider: themeProvider,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Quick Add Section with same card width
                      Builder(
                        builder: (context) {
                          // Measure stat card width after first frame (only once)
                          if (_statCardWidth == null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _statCardWidth == null) {
                                final RenderBox? renderBox =
                                    _statCardKey.currentContext?.findRenderObject()
                                        as RenderBox?;
                                if (renderBox != null) {
                                  setState(() {
                                    _statCardWidth = renderBox.size.width;
                                  });
                                }
                              }
                            });
                          }

                          if (_statCardWidth != null) {
                            return QuickAddSection(
                              provider: widget.provider,
                              cardWidth: _statCardWidth!,
                              quickAddAmounts: widget.quickAddAmounts,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
