import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';
import '../utils/routine_dialogs.dart';

enum _RoutineFlowPhase { detail, run, complete }

class GuidedRoutineFlowPage extends StatefulWidget {
  final String routineId;
  final Color accent;

  const GuidedRoutineFlowPage({
    super.key,
    required this.routineId,
    this.accent = AppColors.routine,
  });

  @override
  State<GuidedRoutineFlowPage> createState() => _GuidedRoutineFlowPageState();
}

class _GuidedRoutineFlowPageState extends State<GuidedRoutineFlowPage>
    with TickerProviderStateMixin {
  _RoutineFlowPhase _phase = _RoutineFlowPhase.detail;
  int _stepIndex = 0;
  int _remainingSeconds = 0;
  int _totalSeconds = 1;
  bool _isRunning = false;
  bool _burst = false;
  DateTime? _startedAt;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<RoutinesProvider>();
    final routine = provider.getRoutineById(widget.routineId);

    if (routine == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: _MissingRoutineState(
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    final effectiveAccent = _toneForRoutine(routine, widget.accent);

    return PopScope(
      canPop: _phase != _RoutineFlowPhase.run,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeaveRun();
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final keyValue = child.key is ValueKey
                  ? ((child.key as ValueKey).value?.toString() ?? '')
                  : '';
              if (keyValue == 'routine_complete') {
                return FadeTransition(opacity: animation, child: child);
              }
              final begin = keyValue.startsWith('routine_run')
                  ? const Offset(0, 1)
                  : const Offset(0.26, 0);
              final offset = Tween<Offset>(begin: begin, end: Offset.zero)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: switch (_phase) {
              _RoutineFlowPhase.detail => _RoutineDetailStartView(
                key: const ValueKey('routine_detail'),
                routine: routine,
                accent: effectiveAccent,
                onBack: () => Navigator.of(context).maybePop(),
                onEdit: () => RoutineDialogs.showEditRoutine(context, routine),
                onStart: () => _startRun(routine),
              ),
              _RoutineFlowPhase.run => _GuidedRoutineRunView(
                key: ValueKey('routine_run_$_stepIndex'),
                routine: routine,
                accent: effectiveAccent,
                stepIndex: _stepIndex,
                remainingSeconds: _remainingSeconds,
                totalSeconds: _totalSeconds,
                isRunning: _isRunning,
                burst: _burst,
                onClose: _confirmLeaveRun,
                onPause: _togglePause,
                onDone: () => _completeCurrentStep(provider, routine),
                onSkip: () => _advanceStep(routine, markComplete: false),
              ),
              _RoutineFlowPhase.complete => _RoutineCompleteView(
                key: const ValueKey('routine_complete'),
                routine: routine,
                accent: effectiveAccent,
                elapsed: _startedAt == null
                    ? Duration.zero
                    : DateTime.now().difference(_startedAt!),
                onFinish: () => Navigator.of(context).maybePop(),
              ),
            },
          ),
        ),
      ),
    );
  }

  void _startRun(Routine routine) {
    HapticFeedback.mediumImpact();
    final firstIncomplete = routine.items.indexWhere(
      (item) => !item.isCheckedToday(_today()),
    );
    final initialIndex = firstIncomplete == -1 ? 0 : firstIncomplete;

    setState(() {
      _phase = _RoutineFlowPhase.run;
      _stepIndex = initialIndex;
      _isRunning = true;
      _burst = false;
      _startedAt = DateTime.now();
    });
    _resetTimer(routine, initialIndex);
    _startTicker();
  }

  void _resetTimer(Routine routine, int index) {
    final seconds = _secondsForItem(routine.items[index]);
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning || _phase != _RoutineFlowPhase.run) return;
      if (_remainingSeconds <= 0) return;
      setState(() => _remainingSeconds -= 1);
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _isRunning = !_isRunning);
  }

  Future<void> _completeCurrentStep(
    RoutinesProvider provider,
    Routine routine,
  ) async {
    if (_burst || routine.items.isEmpty) return;

    final item = routine.items[_stepIndex];
    final isDone = item.isCheckedToday(_today());
    HapticFeedback.lightImpact();

    if (!isDone) {
      await provider.toggleItemCheckedToday(routine.id, item.id);
    }

    if (!mounted) return;
    await _advanceStep(routine, markComplete: true);
  }

  Future<void> _advanceStep(
    Routine routine, {
    required bool markComplete,
  }) async {
    if (_burst) return;

    setState(() => _burst = markComplete);
    if (markComplete) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
    if (!mounted) return;

    if (_stepIndex < routine.items.length - 1) {
      final nextIndex = _stepIndex + 1;
      setState(() {
        _stepIndex = nextIndex;
        _burst = false;
        _isRunning = true;
      });
      _resetTimer(routine, nextIndex);
    } else {
      _timer?.cancel();
      setState(() {
        _phase = _RoutineFlowPhase.complete;
        _isRunning = false;
        _burst = false;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _confirmLeaveRun() async {
    final theme = context.read<ThemeProvider>();
    final shouldLeave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Leave routine?',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed steps stay saved. You can come back and resume from the next step.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Keep going'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.routineDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Leave'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || shouldLeave != true) return;
    _timer?.cancel();
    setState(() {
      _phase = _RoutineFlowPhase.detail;
      _isRunning = false;
      _burst = false;
    });
  }
}

class _RoutineDetailStartView extends StatelessWidget {
  final Routine routine;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onStart;

  const _RoutineDetailStartView({
    super.key,
    required this.routine,
    required this.accent,
    required this.onBack,
    required this.onEdit,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final itemCount = routine.items.length;
    final totalMinutes = _estimatedRoutineMinutes(routine);
    final time = routine.time == null ? null : _formatTime(routine.time!);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlowTopBar(
                title: 'Routine',
                leftIcon: LucideIcons.chevronLeft,
                rightIcon: LucideIcons.ellipsis,
                accent: accent,
                onLeft: onBack,
                onRight: onEdit,
              ),
              const SizedBox(height: 16),
              _RoutineStartHero(
                routine: routine,
                accent: accent,
                totalMinutes: totalMinutes,
                timeLabel: time,
              ),
              const SizedBox(height: 22),
              _SectionHeading(
                title: "What's inside",
                trailing: '$itemCount steps',
              ),
              const SizedBox(height: 12),
              if (routine.items.isEmpty)
                _NoStepsPanel(theme: theme)
              else
                ...routine.items.asMap().entries.map((entry) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 340 + entry.key * 60),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset((1 - value) * 18, 0),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _RoutineDetailStepRow(
                        item: entry.value,
                        index: entry.key,
                        accent: accent,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.backgroundColor.withValues(alpha: 0),
                  theme.backgroundColor,
                  theme.backgroundColor,
                ],
              ),
            ),
            child: FilledButton.icon(
              onPressed: routine.items.isEmpty ? null : onStart,
              icon: const Icon(LucideIcons.play, size: 18),
              label: const Text('Start routine'),
              style: FilledButton.styleFrom(
                backgroundColor: accent == AppColors.routine
                    ? AppColors.routineDeep
                    : accent,
                disabledBackgroundColor: theme.borderColor.withValues(
                  alpha: 0.28,
                ),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuidedRoutineRunView extends StatelessWidget {
  final Routine routine;
  final Color accent;
  final int stepIndex;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool burst;
  final VoidCallback onClose;
  final VoidCallback onPause;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  const _GuidedRoutineRunView({
    super.key,
    required this.routine,
    required this.accent,
    required this.stepIndex,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.burst,
    required this.onClose,
    required this.onPause,
    required this.onDone,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final item = routine.items[stepIndex];
    final progress = totalSeconds == 0
        ? 0.0
        : 1 - (remainingSeconds / totalSeconds);
    final nextItem = stepIndex < routine.items.length - 1
        ? routine.items[stepIndex + 1]
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _tintFor(theme, accent),
            theme.backgroundColor,
            theme.backgroundColor,
          ],
          stops: const [0, 0.52, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
        child: Column(
          children: [
            Row(
              children: [
                _CircleAction(
                  icon: LucideIcons.chevronLeft,
                  color: theme.textSecondary,
                  onTap: onClose,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: List.generate(routine.items.length, (index) {
                      final segmentProgress = index < stepIndex
                          ? 1.0
                          : index == stepIndex
                          ? progress
                          : 0.0;
                      return Expanded(
                        child: Container(
                          height: 5,
                          margin: EdgeInsets.only(
                            right: index == routine.items.length - 1 ? 0 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.26),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: segmentProgress.clamp(0.0, 1.0),
                            child: Container(color: accent),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${stepIndex + 1}/${routine.items.length}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.12, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _RunStage(
                  key: ValueKey(item.id),
                  item: item,
                  routineName: routine.name,
                  accent: accent,
                  progress: progress,
                  remainingSeconds: remainingSeconds,
                  estimatedMinutes: _estimatedMinutesForItem(item),
                  isRunning: isRunning,
                  burst: burst,
                ),
              ),
            ),
            if (nextItem != null)
              _NextStepPill(item: nextItem, accent: accent)
            else
              _NextStepPill.complete(accent: accent),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.textTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    child: Text(
                      stepIndex < routine.items.length - 1 ? 'Skip' : 'Finish',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _PauseButton(
                  isRunning: isRunning,
                  accent: accent,
                  onTap: onPause,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(
                stepIndex < routine.items.length - 1
                    ? 'Mark done & next'
                    : 'Complete routine',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent == AppColors.routine
                    ? AppColors.routineDeep
                    : accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunStage extends StatelessWidget {
  final RoutineItem item;
  final String routineName;
  final Color accent;
  final double progress;
  final int remainingSeconds;
  final int estimatedMinutes;
  final bool isRunning;
  final bool burst;

  const _RunStage({
    super.key,
    required this.item,
    required this.routineName,
    required this.accent,
    required this.progress,
    required this.remainingSeconds,
    required this.estimatedMinutes,
    required this.isRunning,
    required this.burst,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final icon = _iconForItem(item);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'NOW · $routineName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 22),
        _RoutineOrb(
          icon: burst ? LucideIcons.check : icon,
          accent: accent,
          progress: progress,
          paused: !isRunning,
          burst: burst,
        ),
        const SizedBox(height: 26),
        SelectableText(
          item.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 27,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock, size: 13, color: theme.textSecondary),
            const SizedBox(width: 5),
            Text(
              '$estimatedMinutes min · ${_formatDuration(remainingSeconds)} left',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SelectableText(
            _cueForItem(item.title),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineCompleteView extends StatelessWidget {
  final Routine routine;
  final Color accent;
  final Duration elapsed;
  final VoidCallback onFinish;

  const _RoutineCompleteView({
    super.key,
    required this.routine,
    required this.accent,
    required this.elapsed,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final checkedToday = routine.items
        .where((item) => item.isCheckedToday(_today()))
        .length;
    final displayedElapsed = math.max(1, elapsed.inMinutes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _tintFor(theme, accent),
            theme.backgroundColor,
            theme.backgroundColor,
          ],
          stops: const [0, 0.56, 1],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: _CompletionCheck(accent: accent),
          ),
          const SizedBox(height: 24),
          Text(
            'Routine complete',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${routine.name} · Beautifully done. That is your momentum.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _CompletionStat(
                  value: '$checkedToday/${routine.items.length}',
                  label: 'steps',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompletionStat(
                  value: '~$displayedElapsed',
                  label: 'min',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompletionStat(
                  value: '${routine.streakCount}',
                  label: 'streak',
                  icon: LucideIcons.flame,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onFinish,
            style: FilledButton.styleFrom(
              backgroundColor: accent == AppColors.routine
                  ? AppColors.routineDeep
                  : accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Back to routines'),
          ),
        ],
      ),
    );
  }
}

class _RoutineStartHero extends StatelessWidget {
  final Routine routine;
  final Color accent;
  final int totalMinutes;
  final String? timeLabel;

  const _RoutineStartHero({
    required this.routine,
    required this.accent,
    required this.totalMinutes,
    this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final icon = routine.iconCodePoint != null
        ? RoutineIcons.getIconFromCodePoint(routine.iconCodePoint!)
        : LucideIcons.repeat;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.92), _deepen(accent)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -52,
              top: -66,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
            ),
            Positioned(
              left: -48,
              bottom: -72,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 13),
                Text(
                  routine.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${timeLabel ?? 'Anytime'} · ${_selectedDaysLabel(routine)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _HeroStat(value: '${routine.items.length}', label: 'steps'),
                    const SizedBox(width: 10),
                    _HeroStat(value: '~$totalMinutes', label: 'minutes'),
                    const SizedBox(width: 10),
                    _HeroStat(
                      value: '${routine.streakCount}',
                      label: 'streak',
                      icon: LucideIcons.flame,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const _HeroStat({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 14),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineDetailStepRow extends StatelessWidget {
  final RoutineItem item;
  final int index;
  final Color accent;

  const _RoutineDetailStepRow({
    required this.item,
    required this.index,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final icon = _iconForItem(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.22)),
        boxShadow: _softShadow(theme),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _tintFor(theme, accent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  item.title,
                  maxLines: 1,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _cueForItem(item.title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _tintFor(theme, accent),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${_estimatedMinutesForItem(item)} min',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineOrb extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final double progress;
  final bool paused;
  final bool burst;

  const _RoutineOrb({
    required this.icon,
    required this.accent,
    required this.progress,
    required this.paused,
    required this.burst,
  });

  @override
  State<_RoutineOrb> createState() => _RoutineOrbState();
}

class _RoutineOrbState extends State<_RoutineOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    if (!widget.paused) {
      _breathController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _RoutineOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused && _breathController.isAnimating) {
      _breathController.stop();
    } else if (!widget.paused && !_breathController.isAnimating) {
      _breathController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SizedBox(
      width: 198,
      height: 198,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 198,
            height: 198,
            child: CircularProgressIndicator(
              value: widget.progress.clamp(0.0, 1.0),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.borderColor.withValues(alpha: 0.24),
              valueColor: AlwaysStoppedAnimation(_deepen(widget.accent)),
            ),
          ),
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_breathController.value);
              final orbScale = widget.paused ? 0.96 : 0.96 + (0.08 * t);
              final haloScale = widget.paused ? 1.0 : 1.0 + (0.10 * t);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: haloScale,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.accent.withValues(alpha: 0.36),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: orbScale,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.24),
                          colors: [
                            Color.alphaBlend(
                              widget.accent.withValues(alpha: 0.30),
                              theme.cardColor,
                            ),
                            theme.cardColor,
                          ],
                        ),
                        boxShadow: _softShadow(theme, lift: true),
                      ),
                      child: AnimatedScale(
                        scale: widget.burst ? 1.18 : 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          widget.icon,
                          color: _deepen(widget.accent),
                          size: widget.burst ? 56 : 48,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NextStepPill extends StatelessWidget {
  final RoutineItem? item;
  final Color accent;
  final bool isComplete;

  const _NextStepPill({required this.item, required this.accent})
    : isComplete = false;

  const _NextStepPill.complete({required this.accent})
    : item = null,
      isComplete = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final leadingIcon = isComplete ? LucideIcons.sparkles : _iconForItem(item!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _tintFor(theme, accent),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(leadingIcon, size: 16, color: _deepen(accent)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isComplete ? 'Next: completion' : 'Next: ${item!.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _deepen(accent),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final bool isRunning;
  final Color accent;
  final VoidCallback onTap;

  const _PauseButton({
    required this.isRunning,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Material(
      color: theme.cardColor,
      shape: const CircleBorder(),
      elevation: theme.isDarkMode ? 0 : 5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            isRunning ? LucideIcons.pause : LucideIcons.play,
            color: _deepen(accent),
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _CompletionCheck extends StatelessWidget {
  final Color accent;

  const _CompletionCheck({required this.accent});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pop = Curves.elasticOut.transform((value / 0.42).clamp(0, 1));
        return Transform.scale(
          scale: 0.62 + (0.38 * pop),
          child: CustomPaint(
            size: const Size(92, 92),
            painter: _CompletionCheckPainter(
              accent: accent,
              ringProgress: (value / 0.72).clamp(0, 1),
              tickProgress: ((value - 0.58) / 0.42).clamp(0, 1),
            ),
          ),
        );
      },
    );
  }
}

class _CompletionCheckPainter extends CustomPainter {
  final Color accent;
  final double ringProgress;
  final double tickProgress;

  _CompletionCheckPainter({
    required this.accent,
    required this.ringProgress,
    required this.tickProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 7) / 2;
    final deep = _deepen(accent);

    final basePaint = Paint()
      ..color = accent.withValues(alpha: 0.23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, basePaint);

    final ringPaint = Paint()
      ..color = deep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * ringProgress,
      false,
      ringPaint,
    );

    final path = Path()
      ..moveTo(size.width * 0.33, size.height * 0.51)
      ..lineTo(size.width * 0.46, size.height * 0.64)
      ..lineTo(size.width * 0.69, size.height * 0.37);
    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(0, metric.length * tickProgress);
    final tickPaint = Paint()
      ..color = deep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(visiblePath, tickPaint);
  }

  @override
  bool shouldRepaint(covariant _CompletionCheckPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.ringProgress != ringProgress ||
        oldDelegate.tickProgress != tickProgress;
  }
}

class _CompletionStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const _CompletionStat({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.22)),
        boxShadow: _softShadow(theme),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.moodDeep, size: 15),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowTopBar extends StatelessWidget {
  final String title;
  final IconData leftIcon;
  final IconData rightIcon;
  final Color accent;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _FlowTopBar({
    required this.title,
    required this.leftIcon,
    required this.rightIcon,
    required this.accent,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Row(
      children: [
        _CircleAction(icon: leftIcon, color: theme.textPrimary, onTap: onLeft),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _CircleAction(icon: rightIcon, color: accent, onTap: onRight),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Material(
      color: theme.cardColor,
      shape: const CircleBorder(),
      elevation: theme.isDarkMode ? 0 : 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeading({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              color: theme.textTertiary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _NoStepsPanel extends StatelessWidget {
  final ThemeProvider theme;

  const _NoStepsPanel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.22)),
      ),
      child: Text(
        'Add steps to turn this routine into a guided flow.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MissingRoutineState extends StatelessWidget {
  final VoidCallback onBack;

  const _MissingRoutineState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, color: theme.textTertiary, size: 42),
            const SizedBox(height: 12),
            Text(
              'Routine not found',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onBack, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

Color _toneForRoutine(Routine routine, Color fallback) {
  final name = routine.name.toLowerCase();
  if (name.contains('water') || name.contains('su')) return AppColors.water;
  if (name.contains('mood') || name.contains('duygu')) return AppColors.mood;
  if (name.contains('mind') ||
      name.contains('breath') ||
      name.contains('nefes') ||
      name.contains('medit')) {
    return AppColors.mindful;
  }
  return fallback;
}

Color _deepen(Color color) {
  if (color == AppColors.water) return AppColors.waterDeep;
  if (color == AppColors.mood) return AppColors.moodDeep;
  if (color == AppColors.mindful) return AppColors.mindfulDeep;
  if (color == AppColors.primary) return AppColors.primaryDeep;
  return AppColors.routineDeep;
}

Color _tintFor(ThemeProvider theme, Color color) {
  final lightTint = color == AppColors.water
      ? AppColors.waterTint
      : color == AppColors.mood
      ? AppColors.moodTint
      : color == AppColors.mindful
      ? AppColors.mindfulTint
      : color == AppColors.primary
      ? AppColors.terraTint
      : AppColors.routineTint;

  if (!theme.isDarkMode) return lightTint;
  return Color.alphaBlend(color.withValues(alpha: 0.16), theme.cardColor);
}

List<BoxShadow>? _softShadow(ThemeProvider theme, {bool lift = false}) {
  if (theme.isDarkMode) return null;
  return [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: AppColors.primaryDeep.withValues(alpha: lift ? 0.12 : 0.07),
      blurRadius: lift ? 32 : 22,
      offset: Offset(0, lift ? 16 : 8),
      spreadRadius: lift ? -10 : -14,
    ),
  ];
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

int _estimatedRoutineMinutes(Routine routine) {
  if (routine.items.isEmpty) return 0;
  return routine.items.map(_estimatedMinutesForItem).reduce((a, b) => a + b);
}

int _estimatedMinutesForItem(RoutineItem item) {
  if (item.durationMinutes != null) {
    return item.durationMinutes!.clamp(1, 60).toInt();
  }
  final title = item.title.toLowerCase();
  if (title.contains('walk') || title.contains('yürüy')) return 15;
  if (title.contains('read') || title.contains('oku')) return 10;
  if (title.contains('stretch') || title.contains('esne')) return 5;
  if (title.contains('brush') || title.contains('diş')) return 2;
  if (title.contains('bed') || title.contains('yata')) return 2;
  if (title.contains('wash') || title.contains('yıka')) return 1;
  if (title.contains('water') || title.contains('su')) return 1;
  return 3;
}

int _secondsForItem(RoutineItem item) {
  final minutes = _estimatedMinutesForItem(item);
  return math.max(15, math.min(90, minutes * 18));
}

IconData _iconForItem(RoutineItem item) {
  if (item.iconCodePoint == null) return LucideIcons.circleCheck;
  return RoutineIcons.getIconFromCodePoint(item.iconCodePoint!) ??
      LucideIcons.circleCheck;
}

String _cueForItem(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('wash') || lower.contains('yıka')) {
    return 'Take this one slowly. Finish it, then come back for the next step.';
  }
  if (lower.contains('bed') || lower.contains('yata')) {
    return 'Smooth the space around you. This is a small win you can see.';
  }
  if (lower.contains('brush') || lower.contains('diş')) {
    return 'Stay with the simple action. Clean, steady, done.';
  }
  if (lower.contains('water') || lower.contains('su')) {
    return 'Hydrate first. Let this reset the next part of your day.';
  }
  if (lower.contains('walk') || lower.contains('yürüy')) {
    return 'Step away for a moment. Let your body lead the reset.';
  }
  return 'One calm step at a time. Complete this, then move forward.';
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String _selectedDaysLabel(Routine routine) {
  final days = routine.selectedDays;
  if (days == null || days.isEmpty || days.length == 7) return 'Every day';
  if (days.length == 5 &&
      days.contains(0) &&
      days.contains(1) &&
      days.contains(2) &&
      days.contains(3) &&
      days.contains(4)) {
    return 'Weekdays';
  }
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map((day) => labels[day]).join(', ');
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}
