import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/swipe_to_dismiss_wrapper.dart';
import '../../../../core/widgets/animated_metric_text.dart';
import '../../../../core/widgets/celebration_dialog.dart';
import '../providers/water_provider.dart';
import '../../domain/entities/water_intake.dart';
import '../../data/services/daily_goal_service.dart';
import '../../data/services/quick_add_amounts_service.dart';
import '../../data/models/quick_add_amount.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/utils/app_route.dart';
import 'water_goal_page.dart';
import 'water_settings_page.dart';

part '../widgets/todays_progress_card.dart';
part '../widgets/todays_log_section.dart';
part '../widgets/week_bars_section.dart';
part '../widgets/water_log_item.dart';
part '../widgets/quick_add_section.dart';
part '../widgets/water_amount_button.dart';
part '../widgets/water_stat_card.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage>
    with AutomaticKeepAliveClientMixin {
  List<QuickAddAmount> _quickAddAmounts = [];
  Timer? _goalCheerTimer;
  int _waterPulseId = 0;
  bool _showGoalCheer = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().loadTodayWaterIntake();
      _loadQuickAddAmounts();
      _loadDailyGoal();
    });
  }

  Future<void> _loadQuickAddAmounts() async {
    final amounts = await QuickAddAmountsService.getQuickAddAmounts();
    if (mounted) {
      setState(() {
        _quickAddAmounts = amounts;
      });
    }
  }

  Future<void> _loadDailyGoal() async {
    final goal = await DailyGoalService.getDailyGoal();
    if (mounted) {
      // Update WaterProvider with the daily goal
      context.read<WaterProvider>().setDailyGoal(goal);
    }
  }

  @override
  void dispose() {
    _goalCheerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(color: themeProvider.backgroundColor),
      child: SafeArea(
        child: Consumer<WaterProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      TodaysProgressCard(
                        provider: provider,
                        dailyGoal: provider.dailyGoalMl,
                        quickAddAmounts: _quickAddAmounts,
                        pulseId: _waterPulseId,
                        showGoalCheer: _showGoalCheer,
                        onAddWater: (amountMl) => _addWater(provider, amountMl),
                      ),
                      const SizedBox(height: 22),
                      TodaysLogSection(provider: provider),
                      const SizedBox(height: 22),
                      WeekBarsSection(provider: provider),
                      SizedBox(
                        height: LayoutConstants.getNavbarClearance(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return _WaterTopBar(onSettingsTap: () => _openSettings(context));
  }

  Future<void> _addWater(WaterProvider provider, int amountMl) async {
    final previousAmount = provider.todayAmount;
    final wasGoalReached = provider.isGoalReached;

    HapticFeedback.mediumImpact();
    await provider.addWaterAmount(amountMl);
    if (!mounted || provider.todayAmount <= previousAmount) return;

    final reachedGoalNow =
        provider.justReachedGoal || (!wasGoalReached && provider.isGoalReached);
    setState(() {
      _waterPulseId++;
      _showGoalCheer = reachedGoalNow;
    });

    if (reachedGoalNow) {
      HapticFeedback.heavyImpact();
      _goalCheerTimer?.cancel();
      _goalCheerTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _showGoalCheer = false);
      });
    }

    if (reachedGoalNow) {
      await showCelebrationDialog(
        context: context,
        icon: LucideIcons.droplet,
        color: AppColors.waterDeep,
        eyebrow: 'DAILY GOAL',
        title: 'Hydration goal complete',
        message:
            'You reached ${provider.dailyGoalMl} ml today. Every glass counted.',
        actionLabel: 'Nice',
        metric: CelebrationMetric(
          before: '$previousAmount',
          after: '${provider.todayAmount}',
          label: 'ml today',
        ),
      );
    } else {
      _showWaterAddedMessage(
        amountMl: amountMl,
        remainingMl: (provider.dailyGoalMl - provider.todayAmount).clamp(
          0,
          provider.dailyGoalMl,
        ),
        reachedGoal: false,
      );
    }
  }

  void _showWaterAddedMessage({
    required int amountMl,
    required int remainingMl,
    required bool reachedGoal,
  }) {
    final themeProvider = context.read<ThemeProvider>();
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.waterTint.withValues(
                    alpha: themeProvider.isDarkMode ? 0.16 : 1,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  reachedGoal ? LucideIcons.check : LucideIcons.droplet,
                  size: 18,
                  color: AppColors.waterDeep,
                  fill: reachedGoal ? 0 : 1,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reachedGoal
                          ? 'Daily goal reached!'
                          : '+$amountMl ml added',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeProvider.textPrimary,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      reachedGoal
                          ? "You completed today's water goal."
                          : '$remainingMl ml left today',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: themeProvider.textSecondary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: themeProvider.surfaceColor,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            LayoutConstants.getNavbarClearance(context) + 8,
          ),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.water.withValues(alpha: 0.24)),
          ),
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  Future<void> _openSettings(BuildContext context) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WaterSettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          final offsetAnimation = animation.drive(tween);
          final fadeAnimation = Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve)).animate(animation);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );

    if (result == true) {
      _loadQuickAddAmounts();
      await _loadDailyGoal();
      if (context.mounted) {
        context.read<WaterProvider>().loadTodayWaterIntake();
      }
    }
  }
}

class _WaterTopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _WaterTopBar({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        _WaterRoundButton(
          icon: LucideIcons.chevronLeft,
          onTap: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: Text(
            'Water',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _WaterRoundButton(
          icon: LucideIcons.settings,
          color: AppColors.waterDeep,
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

class _WaterRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _WaterRoundButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      color: themeProvider.cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.textPrimary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: themeProvider.isDarkMode ? 0.18 : 0.04,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? themeProvider.textPrimary,
          ),
        ),
      ),
    );
  }
}
