import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/wave_progress_bar.dart';
import '../providers/water_provider.dart';
import '../../domain/entities/water_intake.dart';
import '../../data/services/daily_goal_service.dart';
import '../../data/services/quick_add_amounts_service.dart';
import '../../data/models/quick_add_amount.dart';
import 'water_settings_page.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  List<QuickAddAmount> _quickAddAmounts = [];
  final GlobalKey _statCardKey = GlobalKey();
  double? _statCardWidth;
  int _dailyGoal = 2000;

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
      setState(() {
        _dailyGoal = goal;
      });
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
                            '🎉 Daily goal reached!',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  // Today's Progress Section
                  _buildTodaysProgressCard(context, provider),
                  const SizedBox(height: 24),
                  // Today's Log Section
                  _buildTodaysLogSection(context, provider),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Water Tracker',
              style: theme.textTheme.displaySmall?.copyWith(
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay hydrated & healthy',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const WaterSettingsPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  var tween = Tween(begin: begin, end: end).chain(
                    CurveTween(curve: curve),
                  );

                  var offsetAnimation = animation.drive(tween);
                  var fadeAnimation = Tween(begin: 0.0, end: 1.0).chain(
                    CurveTween(curve: curve),
                  ).animate(animation);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
                reverseTransitionDuration: const Duration(milliseconds: 250),
              ),
            );
            // Reload settings if saved
            if (result == true) {
              _loadQuickAddAmounts();
              await _loadDailyGoal();
              // Reload water intake to update progress with new goal
              context.read<WaterProvider>().loadTodayWaterIntake();
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: themeProvider.borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.settings,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysProgressCard(
    BuildContext context,
    WaterProvider provider,
  ) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final progress = provider.todayIntake?.getProgress(dailyGoalMl: _dailyGoal) ?? 0.0;
    final percentage = (progress * 100).toInt();
    final glassCount = provider.todayIntake?.logs.length ?? 0;
    final remaining = _dailyGoal - provider.todayAmount;

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
                  '${provider.todayAmount}',
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
          Text(
            'of ${_dailyGoal}ml daily goal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Horizontal Progress Bar with Wave Effect
          WaveProgressBar(
            progress: progress,
            centerText: '$percentage%',
            bottomText:
                '${provider.todayAmount} / $_dailyGoal ml',
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
                        child: _buildStatCard(context, '$glassCount', 'Cups'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          '${remaining > 0 ? remaining : 0}',
                          'Remaining',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCardWithIcon(context, 'Status'),
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
                        return _buildQuickAddSection(
                          context,
                          provider,
                          _statCardWidth!,
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
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.borderColor,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: themeProvider.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithIcon(BuildContext context, String label) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.borderColor,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.flame,
            color: themeProvider.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: themeProvider.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection(
    BuildContext context,
    WaterProvider provider,
    double cardWidth,
  ) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    // Use amounts from settings (already sorted)
    final allAmounts = _quickAddAmounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              LucideIcons.droplet,
              color: themeProvider.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'QUICK ADD',
              style: theme.textTheme.titleMedium?.copyWith(
                color: themeProvider.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Horizontal Scrollable Buttons
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allAmounts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final quickAddAmount = allAmounts[index];

              return SizedBox(
                width: cardWidth,
                child: _buildAmountButton(
                  context,
                  quickAddAmount.amountMl,
                  quickAddAmount.label,
                  provider,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountButton(
    BuildContext context,
    int amount,
    String label,
    WaterProvider provider,
  ) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: () => context.read<WaterProvider>().addWaterAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: themeProvider.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.droplet, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              '${amount}ml',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysLogSection(BuildContext context, WaterProvider provider) {
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
                .map((log) => _buildLogItem(context, log, provider))
                .toList()
                .reversed, // Show newest first
        ],
      ),
    );
  }

  Widget _buildLogItem(
    BuildContext context,
    WaterLog log,
    WaterProvider provider,
  ) {
    return _AnimatedLogItem(
      key: ValueKey(log.id),
      log: log,
      provider: provider,
    );
  }
}

/// Animated log item with fade out animation on delete
class _AnimatedLogItem extends StatefulWidget {
  final WaterLog log;
  final WaterProvider provider;

  const _AnimatedLogItem({
    super.key,
    required this.log,
    required this.provider,
  });

  @override
  State<_AnimatedLogItem> createState() => _AnimatedLogItemState();
}

class _AnimatedLogItemState extends State<_AnimatedLogItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.5, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Start animation
    await _animationController.forward();

    // Delete after animation completes
    widget.provider.deleteLog(widget.log.id);

    // Show confirmation snackbar
    if (mounted) {
      final themeProvider = context.read<ThemeProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                LucideIcons.check,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.log.amountMl}ml deleted',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeProvider.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          backgroundColor: themeProvider.backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(widget.log.timestamp);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeProvider.borderColor,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.droplet,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Amount and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.log.amountMl}ml',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button with visual feedback
              GestureDetector(
                onTap: _handleDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isDeleting
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
