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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _celebrationController;
  List<QuickAddAmount> _quickAddAmounts = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

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
    _celebrationController.dispose();
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
            // Check if goal was just reached and trigger celebration
            if (provider.justReachedGoal) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _celebrationController.forward().then((_) {
                    if (mounted) {
                      _celebrationController.reverse();
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            LucideIcons.partyPopper,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Daily goal reached!',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            }

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
                      ),
                      const SizedBox(height: 22),
                      TodaysLogSection(provider: provider),
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
