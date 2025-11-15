import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../core/constants/water_constants.dart';
import '../providers/water_provider.dart';
import '../../domain/entities/water_intake.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().loadTodayWaterIntake();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _handleWaterAdded(int amount) async {
    final provider = context.read<WaterProvider>();
    final wasGoalReached = provider.isGoalReached;

    await provider.addWaterAmount(amount);

    if (!wasGoalReached && provider.isGoalReached) {
      _celebrationController.forward().then((_) {
        _celebrationController.reverse();
      });
      _showGoalReachedSnackBar();
    }
  }

  void _showGoalReachedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.partyPopper, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              '🎉 Daily goal reached!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.secondaryCream),
      child: SafeArea(
        child: Consumer<WaterProvider>(
          builder: (context, provider, child) {
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
                  // Quick Add Section
                  _buildQuickAddSection(context, provider),
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
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay hydrated & healthy',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryOrange, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.droplet,
            color: AppColors.primaryOrange,
            size: 20,
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
    final percentage = (provider.todayProgress * 100).toInt();
    final glassCount = provider.todayIntake?.logs.length ?? 0;
    final remaining = WaterConstants.dailyGoalMl - provider.todayAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'TODAY\'S PROGRESS',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryOrange,
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
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'ml',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                    color: AppColors.darkGrey.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Goal
          Text(
            'of ${WaterConstants.dailyGoalMl}ml daily goal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          // Horizontal Progress Bar
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCream,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: provider.todayProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0ml',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.darkGrey.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  Text(
                    '${WaterConstants.dailyGoalMl}ml',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.darkGrey.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Three Stat Cards
          Row(
            children: [
              Expanded(child: _buildStatCard(context, '$glassCount', 'Cups')),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  '${remaining > 0 ? remaining : 0}',
                  'Remaining',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCardWithIcon(context, 'Status')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithIcon(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.flame,
            color: AppColors.primaryOrange,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection(BuildContext context, WaterProvider provider) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(
                LucideIcons.droplet,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'QUICK ADD',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryOrange,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add water to your daily intake',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          // Three Buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickAddButton(context, 250, '1 Glass', provider),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAddButton(context, 500, '1 Bottle', provider),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAddButton(context, 1000, '1 Liter', provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(
    BuildContext context,
    int amount,
    String label,
    WaterProvider provider,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _handleWaterAdded(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
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
    final logs = provider.todayIntake?.logs ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
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
                  const Icon(
                    LucideIcons.clock,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY\'S LOG',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (logs.isNotEmpty)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${logs.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryOrange,
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
                    color: AppColors.darkGrey.withValues(alpha: 0.5),
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
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(log.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.droplet,
              color: AppColors.primaryOrange,
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
                  '${log.amountMl}ml',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGrey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () => _deleteLog(log, provider),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryOrangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: AppColors.primaryOrange,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLog(WaterLog log, WaterProvider provider) async {
    final todayIntake = provider.todayIntake;
    if (todayIntake == null) return;

    if (todayIntake.logs.isNotEmpty && todayIntake.logs.last.id == log.id) {
      await provider.undoLastLog();
      return;
    }

    final updatedLogs = todayIntake.logs.where((l) => l.id != log.id).toList();
    final newTotal = updatedLogs.fold<int>(0, (sum, l) => sum + l.amountMl);

    final updatedIntake = todayIntake.copyWith(
      amountMl: newTotal,
      logs: updatedLogs,
    );

    await provider.updateWaterIntake(updatedIntake);
  }
}
