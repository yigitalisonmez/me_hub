import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../core/constants/water_constants.dart';
import '../providers/water_provider.dart';
import '../widgets/water_jug.dart';
import '../widgets/quick_add_buttons.dart';
import '../widgets/water_stats.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> with SingleTickerProviderStateMixin {
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
    
    // Show celebration animation if goal just reached
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
          children: const [
            Icon(Icons.celebration, color: Colors.white),
            SizedBox(width: 12),
            Text(
              '🎉 Daily goal reached!',
              style: TextStyle(fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Consumer<WaterProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  const SizedBox(height: 30),
                  // Water Jug with liquid animation
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                      CurvedAnimation(
                        parent: _celebrationController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: WaterJug(
                      progress: provider.todayProgress,
                      currentAmount: provider.todayAmount,
                      goalAmount: WaterConstants.dailyGoalMl,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Quick add buttons
                  QuickAddButtons(
                    onAmountSelected: _handleWaterAdded,
                  ),
                  const SizedBox(height: 20),
                  // Undo button
                  if (provider.todayIntake != null && 
                      provider.todayIntake!.logs.isNotEmpty)
                    _buildUndoButton(provider),
                  const SizedBox(height: 20),
                  // Statistics
                  WaterStats(
                    currentAmount: provider.todayAmount,
                    goalAmount: WaterConstants.dailyGoalMl,
                    glassCount: provider.todayIntake?.logs.length ?? 0,
                  ),
                  const SizedBox(height: 20),
                  // Goal reached message
                  if (provider.isGoalReached)
                    _buildGoalReachedMessage(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final today = DateTime.now();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                color: AppColors.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'WATER TRACKER',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = WaterConstants.waterGradient.createShader(
                      const Rect.fromLTWH(0, 0, 200, 50),
                    ),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.water_drop,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ],
          ),
          Container(
            height: 2,
            width: 120,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: WaterConstants.waterGradient,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Icon(
            Icons.local_drink_rounded,
            size: 48,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 12),
          const Text(
            'Stay hydrated throughout the day\nTrack your daily water intake',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${today.day}.${today.month}.${today.year}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUndoButton(WaterProvider provider) {
    return OutlinedButton.icon(
      onPressed: () => provider.undoLastLog(),
      icon: const Icon(Icons.undo, size: 18),
      label: const Text(
        'Undo Last',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryOrange,
        side: BorderSide(
          color: AppColors.primaryOrange.withValues(alpha: 0.5),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildGoalReachedMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.2),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Great job!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'You\'ve reached your daily goal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

