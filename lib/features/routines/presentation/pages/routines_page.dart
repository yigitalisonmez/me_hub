import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
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

class _RoutinesPageState extends State<RoutinesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final Set<String> _expandedRoutines = {};

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesProvider>().loadRoutines();
    });
  }

  void _toggleRoutineExpansion(String routineId) {
    setState(() {
      if (_expandedRoutines.contains(routineId)) {
        _expandedRoutines.remove(routineId);
      } else {
        _expandedRoutines.add(routineId);
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Consumer<RoutinesProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeroHeader(context, provider),
                  const SizedBox(height: 16),
                  ...provider.routines.map(
                    (r) => _buildRoutineCard(r, provider),
                  ),
                  const SizedBox(height: 16),
                  AddRoutineButton(
                    onPressed: () => RoutineDialogs.showAddRoutine(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
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
            children: const [
              Icon(LucideIcons.repeat, color: AppColors.primaryOrange, size: 24),
              SizedBox(width: 8),
              Text(
                'ROUTINES',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 8),
              Icon(LucideIcons.repeat, color: AppColors.primaryOrange, size: 24),
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
              _buildCircularProgress(completionRate, completedToday, totalItems),
              // Stats Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    LucideIcons.list,
                    '$totalRoutines',
                    'Routines',
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    LucideIcons.circleCheck,
                    '$completedToday',
                    'Completed',
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkGrey.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(double progress, int completed, int total) {
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
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
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

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.darkGrey.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineCard(Routine routine, RoutinesProvider provider) {
    final date = DateTime.now();
    final today = DateTime(date.year, date.month, date.day);
    final done = routine.items.where((i) => i.isCheckedToday(today)).length;
    final total = routine.items.length;
    final pct = total == 0 ? 0.0 : done / total;
    final isExpanded = _expandedRoutines.contains(routine.id);

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
            onTap: () => _toggleRoutineExpansion(routine.id),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      routine.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
          _buildLiquidProgress(pct, done, total),
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

  // Simple progress bar with gentle wave at right edge
  Widget _buildLiquidProgress(double pct, int done, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedProgress, child) {
            return SizedBox(
              height: 20,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: _WaveProgressPainter(
                            progress: animatedProgress,
                            wavePhase: _waveController.value,
                            gradient: AppColors.primaryGradient,
                          ),
                          size: const Size(double.infinity, 20),
                        ),
                      );
                    },
                  ),
                  // Percentage text always centered and visible
                  Center(
                    child: Text(
                      '${(animatedProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppColors.darkGrey.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '$done / $total today',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkGrey.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Custom painter for progress bar with gentle wave at right edge
class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Gradient gradient;

  _WaveProgressPainter({
    required this.progress,
    required this.wavePhase,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: 0.12);
    final bgRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(bgRect, bgPaint);

    if (progress <= 0) return;

    // Fill width
    final fillW = size.width * progress.clamp(0.0, 1.0);
    final useWave = progress > 0.01 && progress < 0.999;

    // Draw fill with gentle wave only at the right edge
    final path = Path();
    path.moveTo(0, 0);

    if (useWave) {
      path.lineTo(math.max(0, fillW - 12), 0); // flat until near end

      // Gentle wave at the right edge (vertical wave on the right side)
      if (fillW > 12) {
        for (double y = 0; y <= size.height; y += 0.5) {
          final waveX =
              fillW +
              2.5 *
                  math.sin((y / 3.5) + (wavePhase * math.pi * 2)) *
                  (1.0 - (y / size.height) * 0.3); // gentle fade
          path.lineTo(waveX, y);
        }
      } else {
        path.lineTo(fillW, 0);
        path.lineTo(fillW, size.height);
      }
    } else {
      // No wave at 0% or 100%
      path.lineTo(fillW, 0);
      path.lineTo(fillW, size.height);
    }

    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipRRect(bgRect);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase;
  }
}
