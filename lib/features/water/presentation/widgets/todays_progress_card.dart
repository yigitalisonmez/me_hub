part of '../pages/water_page.dart';

class TodaysProgressCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final progress =
        provider.todayIntake?.getProgress(dailyGoalMl: dailyGoal) ?? 0.0;
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final remaining = (dailyGoal - provider.todayAmount).clamp(0, dailyGoal);

    return Column(
      children: [
        _HydroCircle(
          progress: safeProgress,
          amountMl: provider.todayAmount,
          goalMl: dailyGoal,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HydroPill(
              icon: LucideIcons.flame,
              label: '${provider.todayIntake?.logs.length ?? 0} entries',
              color: AppColors.moodDeep,
            ),
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: context.watch<ThemeProvider>().textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              '$remaining ml to go',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.watch<ThemeProvider>().textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuickAddSection(provider: provider, quickAddAmounts: quickAddAmounts),
        const SizedBox(height: 14),
        _WaterGoalBanner(
          goalMl: dailyGoal,
          onAdjustTap: () => _openGoalSettings(context),
        ),
      ],
    );
  }

  Future<void> _openGoalSettings(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WaterGoalPage()));

    if (result == true && context.mounted) {
      final goal = await DailyGoalService.getDailyGoal();
      if (!context.mounted) return;
      context.read<WaterProvider>().setDailyGoal(goal);
      context.read<WaterProvider>().loadTodayWaterIntake();
    }
  }
}

class _HydroCircle extends StatefulWidget {
  final double progress;
  final int amountMl;
  final int goalMl;

  const _HydroCircle({
    required this.progress,
    required this.amountMl,
    required this.goalMl,
  });

  @override
  State<_HydroCircle> createState() => _HydroCircleState();
}

class _HydroCircleState extends State<_HydroCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: widget.progress),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, child) {
          return Container(
            width: 188,
            height: 188,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeProvider.isDarkMode
                  ? AppColors.waterTint.withValues(alpha: 0.12)
                  : AppColors.waterTint,
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.textPrimary.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.waterDeep.withValues(
                    alpha: themeProvider.isDarkMode ? 0.18 : 0.12,
                  ),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _HydroFillPainter(
                          progress: animatedProgress,
                          wavePhase: _waveController.value,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      '${(animatedProgress * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.waterDeep,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: themeProvider.isDarkMode
                                  ? const Color(0xFFCFE6F2)
                                  : const Color(0xFF234B63),
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                        children: [
                          TextSpan(text: _liters(widget.amountMl)),
                          TextSpan(
                            text: 'L',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.waterDeep,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'of ${_liters(widget.goalMl)} L',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: themeProvider.isDarkMode
                            ? const Color(0xFFA9C6D6)
                            : const Color(0xFF3A6480),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HydroFillPainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  const _HydroFillPainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.save();
    canvas.clipPath(oval);

    final waterTop = size.height * (1 - progress);
    final waveHeight = 7.0;
    final topWave = Path()..moveTo(0, waterTop);
    for (double x = 0; x <= size.width; x += 4) {
      final y =
          waterTop +
          math.sin((x / size.width) * math.pi * 4 + wavePhase * math.pi * 2) *
              waveHeight;
      topWave.lineTo(x, y);
    }
    final path = Path.from(topWave);
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.water, AppColors.waterDeep],
      ).createShader(Rect.fromLTWH(0, waterTop, size.width, size.height));

    canvas.drawPath(path, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(topWave, highlightPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HydroFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase;
  }
}

class _HydroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HydroPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WaterGoalBanner extends StatelessWidget {
  final int goalMl;
  final VoidCallback onAdjustTap;

  const _WaterGoalBanner({required this.goalMl, required this.onAdjustTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.waterTint.withValues(alpha: 0.12)
            : AppColors.waterTint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/water_tracker.png', width: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily goal',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.waterDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeProvider.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(text: '${_liters(goalMl)} L'),
                      TextSpan(
                        text: ' · ${goalMl ~/ 250} glasses',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: themeProvider.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAdjustTap,
            icon: const Icon(LucideIcons.chevronRight, size: 15),
            label: const Text('Adjust'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.water,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

String _liters(int ml) {
  final liters = ml / 1000;
  return liters.toStringAsFixed(liters >= 10 || ml % 1000 == 0 ? 0 : 2);
}
