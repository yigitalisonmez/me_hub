import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

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
                  _buildAddRoutineButton(context),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.repeat, color: AppColors.primaryOrange, size: 24),
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
              Icon(Icons.repeat, color: AppColors.primaryOrange, size: 24),
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
          const SizedBox(height: 8),
          const Icon(
            Icons.checklist_rtl,
            size: 60,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Build healthy habits with daily routines\nand maintain your streaks',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalRoutines routines • $completedToday/$totalItems today',
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          Row(
            children: [
              Expanded(
                child: InkWell(
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
                        _buildStreakBadge(routine.streakCount),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.7,
                            ),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'delete') {
                    await provider.deleteRoutine(routine.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete Routine')),
                ],
              ),
            ],
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        _buildQuickAddChips(routine, provider),
                        const SizedBox(height: 12),
                        ...routine.items.map(
                          (i) => _buildRoutineItem(routine, i, provider),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final controller = TextEditingController();
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Add Routine Item'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    hintText: 'Item title',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true &&
                                controller.text.trim().isNotEmpty) {
                              final item = RoutineItem(
                                id: DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                                title: controller.text.trim(),
                              );
                              await provider.addItem(routine.id, item);
                            }
                          },
                          icon: const Icon(
                            Icons.add,
                            color: AppColors.primaryOrange,
                          ),
                          label: const Text(
                            'Add Item',
                            style: TextStyle(color: AppColors.primaryOrange),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildStreakBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange.withValues(alpha: 0.15),
            AppColors.primaryOrange.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.primaryOrange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddChips(Routine routine, RoutinesProvider provider) {
    final suggestions = <String>['Drink Water', 'Stretch', 'Meditate'];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: suggestions.map((s) {
        return ActionChip(
          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.08),
          label: Text(
            s,
            style: const TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () async {
            final item = RoutineItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: s,
            );
            await provider.addItem(routine.id, item);
          },
        );
      }).toList(),
    );
  }

  Widget _buildRoutineItem(
    Routine routine,
    RoutineItem item,
    RoutinesProvider provider,
  ) {
    final today = DateTime.now();
    final isToday = item.isCheckedToday(
      DateTime(today.year, today.month, today.day),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.toggleItemCheckedToday(routine.id, item.id),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primaryOrange : Colors.transparent,
                border: Border.all(
                  color: isToday
                      ? AppColors.primaryOrange
                      : AppColors.primaryOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isToday
                  ? const Icon(Icons.check, color: AppColors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isToday ? AppColors.darkGrey : AppColors.darkGrey,
                decoration: isToday ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await provider.deleteItem(routine.id, item.id);
            },
            child: Icon(
              Icons.delete_outline,
              color: AppColors.primaryOrange.withValues(alpha: 0.6),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRoutineButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final controller = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('New Routine'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Routine name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Create'),
                ),
              ],
            ),
          );
          if (ok == true && controller.text.trim().isNotEmpty) {
            await context.read<RoutinesProvider>().addNewRoutine(
              DateTime.now().microsecondsSinceEpoch.toString(),
              controller.text.trim(),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Routine'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
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
