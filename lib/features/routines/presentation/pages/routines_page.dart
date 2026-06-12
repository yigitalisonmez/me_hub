import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_route.dart';
import '../../domain/entities/routine.dart';
import 'guided_routine_flow_page.dart';
import '../providers/routines_provider.dart';
import '../utils/routine_dialogs.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _collapsedRoutines = {};
  final Set<String> _expandedRoutines = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => RoutineDialogs.showAddRoutine(context),
        backgroundColor: AppColors.routine,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: SafeArea(
        child: Consumer<RoutinesProvider>(
          builder: (context, provider, child) {
            final weekday = DateTime.now().weekday - 1;
            final activeRoutines = provider.getActiveRoutinesForDay(weekday);
            final inactiveRoutines = provider.getInactiveRoutinesForDay(
              weekday,
            );

            final completedRoutineName = provider.justCompletedRoutineName;
            if (completedRoutineName != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showRoutineCompletedOverlay(completedRoutineName);
              });
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                LayoutConstants.getNavbarClearance(context),
              ),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 36,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      _RoutineTopBar(
                        onAddTap: () => RoutineDialogs.showAddRoutine(context),
                      ),
                      const SizedBox(height: 16),
                      _RoutineHero(routines: activeRoutines),
                      const SizedBox(height: 16),
                      _RoutineWeekStrip(routines: provider.routines),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        title: 'Your routines',
                        actionLabel: 'Edit',
                        onActionTap: activeRoutines.isNotEmpty
                            ? () => RoutineDialogs.showEditRoutine(
                                context,
                                activeRoutines.first,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (provider.isLoading)
                        const _RoutineLoadingBlock()
                      else if (provider.error != null)
                        _RoutineErrorBlock(
                          message: provider.error!,
                          onRetry: provider.loadRoutines,
                        )
                      else if (activeRoutines.isEmpty)
                        _RoutineEmptyState(
                          onAddTap: () =>
                              RoutineDialogs.showAddRoutine(context),
                        )
                      else
                        ...activeRoutines.asMap().entries.map((entry) {
                          final expanded = _isRoutineExpanded(
                            entry.value,
                            isInactive: false,
                          );
                          return _RoutineCard(
                            routine: entry.value,
                            provider: provider,
                            accent: _routineAccent(entry.key),
                            isExpanded: expanded,
                            onOpen: () => _openGuidedFlow(
                              entry.value,
                              _routineAccent(entry.key),
                            ),
                            onToggleExpanded: () =>
                                _toggleRoutineExpansion(entry.value, expanded),
                          );
                        }),
                      if (inactiveRoutines.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const _SectionHeader(title: 'Upcoming'),
                        const SizedBox(height: 12),
                        ...inactiveRoutines.asMap().entries.map(
                          (entry) => _RoutineCard(
                            routine: entry.value,
                            provider: provider,
                            accent: AppColors.mindful,
                            isInactive: true,
                            isExpanded: false,
                            onOpen: null,
                            onToggleExpanded: () {},
                          ),
                        ),
                      ],
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

  bool _isRoutineExpanded(Routine routine, {required bool isInactive}) {
    if (isInactive) return false;
    if (_collapsedRoutines.contains(routine.id)) return false;
    if (_expandedRoutines.contains(routine.id)) return true;

    final today = _today();
    if (routine.items.isEmpty) return true;
    return !routine.items.every((item) => item.isCheckedToday(today));
  }

  void _toggleRoutineExpansion(Routine routine, bool isExpanded) {
    HapticFeedback.selectionClick();
    setState(() {
      if (isExpanded) {
        _collapsedRoutines.add(routine.id);
        _expandedRoutines.remove(routine.id);
      } else {
        _collapsedRoutines.remove(routine.id);
        _expandedRoutines.add(routine.id);
      }
    });
  }

  void _openGuidedFlow(Routine routine, Color accent) {
    if (routine.items.isEmpty) {
      RoutineDialogs.showAddItem(context, routine);
      return;
    }
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      AppRoute(
        page: GuidedRoutineFlowPage(routineId: routine.id, accent: accent),
      ),
    );
  }

  void _showRoutineCompletedOverlay(String routineName) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'streak_fire',
                      child: SizedBox(
                        height: 300,
                        width: 300,
                        child: Lottie.asset(
                          'assets/animations/streak.json',
                          repeat: false,
                          fit: BoxFit.contain,
                          onLoaded: (composition) {
                            Future.delayed(composition.duration, () {
                              if (context.mounted) Navigator.of(context).pop();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Streak Increased!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You completed "$routineName"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoutineTopBar extends StatelessWidget {
  final VoidCallback onAddTap;

  const _RoutineTopBar({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        _RoundIconButton(
          icon: LucideIcons.chevronLeft,
          onTap: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: Text(
            'Routines',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _RoundIconButton(
          icon: LucideIcons.plus,
          color: AppColors.routine,
          onTap: onAddTap,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _RoundIconButton({required this.icon, this.onTap, this.color});

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

class _RoutineHero extends StatelessWidget {
  final List<Routine> routines;

  const _RoutineHero({required this.routines});

  @override
  Widget build(BuildContext context) {
    final today = _today();
    final total = routines.length;
    final completed = routines
        .where((routine) => routine.allItemsCheckedToday(today))
        .length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.routine, AppColors.routineDeep],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.routineDeep.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -42,
            top: -54,
            child: Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Image.asset(
                'assets/images/routine_tracker.png',
                width: 78,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'No routines today'
                          : '$completed of $total routines',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _MiniRing(progress: progress, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineWeekStrip extends StatelessWidget {
  final List<Routine> routines;

  const _RoutineWeekStrip({required this.routines});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = _today();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: themeProvider.isDarkMode ? 0.22 : 0.04,
            ),
            blurRadius: 22,
            offset: const Offset(0, 12),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'This week',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.flame, size: 14, color: AppColors.moodDeep),
              const SizedBox(width: 5),
              Text(
                '${_bestStreak(routines)} days',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.moodDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final date = monday.add(Duration(days: index));
              final active = routines
                  .where((routine) => routine.isActiveOnDay(index))
                  .length;
              final completed = routines.where((routine) {
                if (!routine.isActiveOnDay(index)) return false;
                if (_isSameDay(date, today)) {
                  return routine.allItemsCheckedToday(today);
                }
                final last = routine.lastStreakDate;
                return last != null && _isSameDay(last, date);
              }).length;

              return Expanded(
                child: _WeekColumn(
                  label: labels[index],
                  activeCount: math.min(active, 4),
                  completedCount: math.min(completed, 4),
                  isToday: _isSameDay(date, today),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WeekColumn extends StatelessWidget {
  final String label;
  final int activeCount;
  final int completedCount;
  final bool isToday;

  const _WeekColumn({
    required this.label,
    required this.activeCount,
    required this.completedCount,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(4, (index) {
              final segment = 3 - index;
              final isActive = segment < activeCount;
              final isDone = segment < completedCount;
              return Container(
                width: 20,
                height: 9,
                margin: EdgeInsets.only(top: index == 0 ? 0 : 3),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.routine
                      : isActive
                      ? AppColors.routine.withValues(alpha: 0.16)
                      : themeProvider.textTertiary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? AppColors.routineTint : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isToday
                  ? AppColors.routineDeep
                  : themeProvider.textTertiary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeProvider.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: themeProvider.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final RoutinesProvider provider;
  final Color accent;
  final bool isExpanded;
  final bool isInactive;
  final VoidCallback? onOpen;
  final VoidCallback onToggleExpanded;

  const _RoutineCard({
    required this.routine,
    required this.provider,
    required this.accent,
    required this.isExpanded,
    required this.onOpen,
    required this.onToggleExpanded,
    this.isInactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final today = _today();
    final total = routine.items.length;
    final done = routine.items
        .where((item) => item.isCheckedToday(today))
        .length;
    final icon = routine.iconCodePoint != null
        ? RoutineIcons.getIconFromCodePoint(routine.iconCodePoint!)
        : null;
    final time = routine.time == null ? null : _formatTime(routine.time!);
    final tint = accent.withValues(
      alpha: themeProvider.isDarkMode ? 0.18 : 0.15,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isInactive
            ? (themeProvider.isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.surfaceAlt)
            : themeProvider.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isInactive
              ? themeProvider.textTertiary.withValues(alpha: 0.18)
              : (themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.textPrimary.withValues(alpha: 0.08)),
          style: isInactive ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: isInactive
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: themeProvider.isDarkMode ? 0.22 : 0.04,
                  ),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                  spreadRadius: -14,
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isInactive ? null : onOpen,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          icon ?? LucideIcons.repeat,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routine.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isInactive
                                        ? themeProvider.textPrimary.withValues(
                                            alpha: 0.62,
                                          )
                                        : themeProvider.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (time != null) ...[
                                  Icon(
                                    LucideIcons.clock,
                                    size: 12,
                                    color: themeProvider.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: themeProvider.textSecondary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '·',
                                    style: TextStyle(
                                      color: themeProvider.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    isInactive
                                        ? 'Starts later today'
                                        : '$done of $total done',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: themeProvider.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isInactive) ...[
                const SizedBox(width: 10),
                _RoutinePlayButton(accent: accent, onTap: onOpen),
              ],
              if (isInactive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mindfulTint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: AppColors.mindfulDeep,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Soon',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.mindfulDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.ellipsisVertical,
                  color: themeProvider.textTertiary,
                  size: 18,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    RoutineDialogs.showEditRoutine(context, routine);
                  } else if (value == 'delete') {
                    RoutineDialogs.showDeleteRoutine(context, routine);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              if (!isInactive)
                GestureDetector(
                  onTap: onToggleExpanded,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      LucideIcons.chevronDown,
                      color: themeProvider.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          if (routine.selectedDays != null && routine.selectedDays!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _RoutineDaysPills(days: routine.selectedDays!),
            ),
          if (!isInactive)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _RoutineSteps(
                routine: routine,
                provider: provider,
                accent: accent,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
        ],
      ),
    );
  }
}

class _RoutinePlayButton extends StatelessWidget {
  final Color accent;
  final VoidCallback? onTap;

  const _RoutinePlayButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(LucideIcons.play, color: Colors.white, size: 15),
        ),
      ),
    );
  }
}

class _RoutineDaysPills extends StatelessWidget {
  final List<int> days;

  const _RoutineDaysPills({required this.days});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;

    return Row(
      children: List.generate(7, (index) {
        final selected = days.contains(index);
        final today = index == todayIndex;
        return Expanded(
          child: Container(
            height: 32,
            margin: EdgeInsets.only(right: index == 6 ? 0 : 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.routineTint
                  : themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: today && selected
                    ? AppColors.routine
                    : selected
                    ? AppColors.routine.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              labels[index],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? AppColors.routineDeep
                    : themeProvider.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _RoutineSteps extends StatelessWidget {
  final Routine routine;
  final RoutinesProvider provider;
  final Color accent;

  const _RoutineSteps({
    required this.routine,
    required this.provider,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final today = _today();

    return Column(
      children: [
        const SizedBox(height: 12),
        Divider(color: themeProvider.textTertiary.withValues(alpha: 0.16)),
        const SizedBox(height: 4),
        if (routine.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No steps yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...routine.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isDone = item.isCheckedToday(today);
            final isEnabled =
                index == 0 ||
                routine.items[index - 1].isCheckedToday(today) ||
                isDone;

            return _RoutineStepRow(
              title: item.title,
              isDone: isDone,
              isEnabled: isEnabled,
              accent: accent,
              onTap: isEnabled
                  ? () {
                      HapticFeedback.selectionClick();
                      provider.toggleItemCheckedToday(routine.id, item.id);
                    }
                  : null,
            );
          }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => RoutineDialogs.showAddItem(context, routine),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add step'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.routineDeep,
              backgroundColor: AppColors.routineTint,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineStepRow extends StatelessWidget {
  final String title;
  final bool isDone;
  final bool isEnabled;
  final Color accent;
  final VoidCallback? onTap;

  const _RoutineStepRow({
    required this.title,
    required this.isDone,
    required this.isEnabled,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isDone
                      ? accent
                      : themeProvider.textTertiary.withValues(alpha: 0.42),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(LucideIcons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isEnabled
                      ? (isDone
                            ? themeProvider.textTertiary
                            : themeProvider.textPrimary)
                      : themeProvider.textTertiary.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  decoration: isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            if (!isEnabled)
              Icon(
                LucideIcons.lock,
                size: 14,
                color: themeProvider.textTertiary.withValues(alpha: 0.65),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineEmptyState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _RoutineEmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Image.asset('assets/images/routine_tracker.png', width: 116),
          const SizedBox(height: 12),
          Text(
            'No routines today',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a small rhythm you can repeat.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddTap,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('New routine'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.routine,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineLoadingBlock extends StatelessWidget {
  const _RoutineLoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: AppColors.routine),
      ),
    );
  }
}

class _RoutineErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RoutineErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: themeProvider.textPrimary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  final double progress;
  final Color color;

  const _MiniRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SizedBox(
      width: 42,
      height: 42,
      child: CustomPaint(
        painter: _MiniRingPainter(
          progress: progress.clamp(0.0, 1.0).toDouble(),
          color: color,
          trackColor: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.textPrimary.withValues(alpha: 0.11),
        ),
        child: Center(
          child: Text(
            '${(progress * 100).round()}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _MiniRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - 6) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

Color _routineAccent(int index) {
  const colors = [
    AppColors.mood,
    AppColors.water,
    AppColors.mindful,
    AppColors.routine,
    AppColors.primary,
  ];
  return colors[index % colors.length];
}

int _bestStreak(List<Routine> routines) {
  if (routines.isEmpty) return 0;
  return routines
      .map((routine) => routine.streakCount)
      .fold<int>(0, (best, streak) => math.max(best, streak));
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
