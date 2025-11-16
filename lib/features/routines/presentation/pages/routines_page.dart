import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wave_progress_bar.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';
import '../widgets/streak_badge.dart';
import '../widgets/routine_item_widget.dart';
import '../widgets/add_item_button.dart';
import '../widgets/add_routine_button.dart';
import '../utils/routine_dialogs.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Consumer<RoutinesProvider>(
          builder: (context, provider, child) {
            // Check if all routines are completed today
            final date = DateTime.now();
            final today = DateTime(date.year, date.month, date.day);
            bool allRoutinesCompleted =
                provider.routines.isNotEmpty &&
                provider.routines.every(
                  (r) => r.items.isNotEmpty && r.allItemsCheckedToday(today),
                );

            // Show celebration message if all routines completed
            if (allRoutinesCompleted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
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
                          '🎉 All routines completed today!',
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
                  // Hero Header
                  _buildHeroHeader(context, provider),
                  const SizedBox(height: 24),
                  // Routine Cards
                  ...provider.routines.map(
                    (r) => _buildRoutineCard(context, r, provider),
                  ),
                  const SizedBox(height: 24),
                  // Add Routine Button
                  AddRoutineButton(
                    onPressed: () => RoutineDialogs.showAddRoutine(context),
                  ),
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
              'Routines',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Build habits & stay consistent',
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
            LucideIcons.repeat,
            color: AppColors.primaryOrange,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context, RoutinesProvider provider) {
    final date = DateTime.now();
    final today = DateTime(date.year, date.month, date.day);
    int totalItems = 0;
    int completedToday = 0;
    for (final r in provider.routines) {
      totalItems += r.items.length;
      completedToday += r.items.where((i) => i.isCheckedToday(today)).length;
    }
    final totalRoutines = provider.routines.length;
    final completionRate = totalItems == 0 ? 0.0 : completedToday / totalItems;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.repeat,
                color: AppColors.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'ROUTINES',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryOrange,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.repeat,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ],
          ),
          Container(
            height: 2,
            width: 100,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          // Circular Progress with stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Progress
              _buildCircularProgress(
                context,
                completionRate,
                completedToday,
                totalItems,
              ),
              SizedBox(width: 12),
              // Stats Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    context,
                    LucideIcons.list,
                    '$totalRoutines',
                    'Routines',
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    context,
                    LucideIcons.circleCheck,
                    '$completedToday',
                    'Completed',
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    context,
                    LucideIcons.clock,
                    '${totalItems - completedToday}',
                    'Remaining',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Date
          Text(
            '${today.day}.${today.month}.${today.year}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(
    BuildContext context,
    double progress,
    int completed,
    int total,
  ) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 10,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange.withValues(alpha: 0.15),
                  ),
                ),
              ),
              // Progress circle with gradient effect
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: animatedProgress,
                  strokeWidth: 10,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(animatedProgress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.darkGrey.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryOrange, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.darkGrey,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkGrey.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    Routine routine,
    RoutinesProvider provider,
  ) {
    final theme = Theme.of(context);
    final date = DateTime.now();
    final today = DateTime(date.year, date.month, date.day);
    final done = routine.items.where((i) => i.isCheckedToday(today)).length;
    final total = routine.items.length;
    final pct = total == 0 ? 0.0 : done / total;
    final isExpanded = provider.isRoutineExpanded(routine.id);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryOrange, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => provider.toggleRoutineExpansion(routine.id),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      routine.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                  StreakBadge(count: routine.streakCount),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      LucideIcons.ellipsisVertical,
                      color: AppColors.primaryOrange.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        RoutineDialogs.showEditRoutine(context, routine);
                      } else if (v == 'delete') {
                        RoutineDialogs.showDeleteRoutine(context, routine);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.pencil, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.primaryOrange.withValues(alpha: 0.7),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Progress bar always visible
          WaveProgressBar(
            progress: pct,
            centerText: '${(pct * 100).toStringAsFixed(0)}%',
            bottomText: '$done / $total today',
          ),
          // Expandable content
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        ...routine.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isFirst = index == 0;
                          final isLast = index == routine.items.length - 1;

                          // Check if this item is enabled:
                          // First item is always enabled
                          // Subsequent items are enabled only if previous item is checked
                          bool isEnabled = true;
                          if (index > 0) {
                            final previousItem = routine.items[index - 1];
                            isEnabled = previousItem.isCheckedToday(today);
                          }

                          return RoutineItemWidget(
                            routine: routine,
                            item: item,
                            provider: provider,
                            isFirst: isFirst,
                            isLast: isLast,
                            isEnabled: isEnabled,
                          );
                        }),
                        const SizedBox(height: 12),
                        AddItemButton(
                          onPressed: () =>
                              RoutineDialogs.showAddItem(context, routine),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
