part of '../pages/water_page.dart';

class TodaysProgressCard extends StatelessWidget {
  final WaterProvider provider;
  final int dailyGoal;
  final List<QuickAddAmount> quickAddAmounts;
  final int pulseId;
  final bool showGoalCheer;
  final Future<void> Function(int amountMl) onAddWater;

  const TodaysProgressCard({
    super.key,
    required this.provider,
    required this.dailyGoal,
    required this.quickAddAmounts,
    required this.pulseId,
    required this.showGoalCheer,
    required this.onAddWater,
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
          pulseId: pulseId,
          goalReached: provider.isGoalReached,
          showGoalCheer: showGoalCheer,
        ),
        const SizedBox(height: 12),
        if (provider.isGoalReached)
          _HydroPill(
            icon: LucideIcons.check,
            label:
                'Complete · ${provider.todayIntake?.logs.length ?? 0} entries',
            color: AppColors.waterDeep,
          )
        else
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
        QuickAddSection(
          quickAddAmounts: quickAddAmounts,
          onAddWater: onAddWater,
        ),
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
    ).push(AppRoute(page: const WaterGoalPage()));

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
  final int pulseId;
  final bool goalReached;
  final bool showGoalCheer;

  const _HydroCircle({
    required this.progress,
    required this.amountMl,
    required this.goalMl,
    required this.pulseId,
    required this.goalReached,
    required this.showGoalCheer,
  });

  @override
  State<_HydroCircle> createState() => _HydroCircleState();
}

class _HydroCircleState extends State<_HydroCircle>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.035,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.035,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant _HydroCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseId != widget.pulseId) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _pulseAnimation.value, child: child);
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: widget.progress),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, animatedProgress, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider.isDarkMode
                    ? AppColors.waterTint.withValues(alpha: 0.12)
                    : AppColors.waterTint,
                border: Border.all(
                  color: widget.goalReached
                      ? AppColors.water
                      : themeProvider.isDarkMode
                      ? Colors.white.withValues(alpha: 0.07)
                      : AppColors.textPrimary.withValues(alpha: 0.08),
                  width: widget.goalReached ? 2 : 1,
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
                  if (widget.goalReached)
                    BoxShadow(
                      color: AppColors.water.withValues(alpha: 0.38),
                      blurRadius: 14,
                      spreadRadius: -2,
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
                      Semantics(
                        label: '${_liters(widget.amountMl)} liters consumed',
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedMetricText(
                                value: _animatedLiterValue(widget.amountMl),
                                fractionDigits: _literFractionDigits(
                                  widget.amountMl,
                                ),
                                semanticLabel:
                                    '${_liters(widget.amountMl)} liters',
                                style:
                                    Theme.of(
                                      context,
                                    ).textTheme.displayMedium?.copyWith(
                                      color: themeProvider.isDarkMode
                                          ? const Color(0xFFCFE6F2)
                                          : const Color(0xFF234B63),
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ) ??
                                    const TextStyle(),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  'L',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.waterDeep,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ],
                          ),
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
                  Positioned(
                    bottom: 22,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.45),
                              end: Offset.zero,
                            ).animate(animation),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.7, end: 1).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: widget.showGoalCheer && widget.goalReached
                          ? Container(
                              key: const ValueKey('goal-cheer'),
                              padding: const EdgeInsets.fromLTRB(9, 7, 14, 7),
                              decoration: BoxDecoration(
                                color: AppColors.waterDeep,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.check,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Goal reached!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('goal-cheer-hidden'),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final waterTop = size.height * (1 - clampedProgress);
    const waveHeight = 7.0;
    final edgeBleed = size.width;
    final backWave = _wavePath(
      size: size,
      waterTop: waterTop - 1,
      amplitude: waveHeight * 0.75,
      phase: -wavePhase * math.pi * 1.3 + 0.8,
      edgeBleed: edgeBleed,
    );
    final frontWave = _wavePath(
      size: size,
      waterTop: waterTop,
      amplitude: waveHeight,
      phase: wavePhase * math.pi * 2,
      edgeBleed: edgeBleed,
    );

    final paint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.water, AppColors.waterDeep],
          ).createShader(
            Rect.fromLTWH(
              0,
              waterTop - waveHeight,
              size.width,
              size.height + waveHeight,
            ),
          );

    canvas.drawPath(
      backWave,
      Paint()..color = AppColors.water.withValues(alpha: 0.48),
    );
    canvas.drawPath(frontWave, paint);
    canvas.restore();
  }

  Path _wavePath({
    required Size size,
    required double waterTop,
    required double amplitude,
    required double phase,
    required double edgeBleed,
  }) {
    final path = Path();
    var firstPoint = true;
    for (double x = -edgeBleed; x <= size.width + edgeBleed; x += 3) {
      final y =
          waterTop +
          math.sin((x / size.width) * math.pi * 4 + phase) * amplitude;
      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    return path
      ..lineTo(size.width + edgeBleed, size.height + edgeBleed)
      ..lineTo(-edgeBleed, size.height + edgeBleed)
      ..close();
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
  return liters.toStringAsFixed(_literFractionDigits(ml));
}

int _literFractionDigits(int ml) => ml >= 10000 || ml % 1000 == 0 ? 0 : 2;

num _animatedLiterValue(int ml) {
  final fractionDigits = _literFractionDigits(ml);
  return num.parse((ml / 1000).toStringAsFixed(fractionDigits));
}
