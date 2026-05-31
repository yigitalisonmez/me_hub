import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';
import '../providers/timer_provider.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ChangeNotifierProvider(
      create: (_) => TimerProvider(),
      child: Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const PageHeader(
                  title: 'Focus Timer',
                  subtitle: 'Pomodoro focus',
                  showBackButton: true,
                  actionIcon: LucideIcons.settings,
                ),
                const SizedBox(height: 22),
                const _ModeSelector(),
                const SizedBox(height: 14),
                const _TaskPill(),
                const SizedBox(height: 16),
                const _TimerStage(),
                const SizedBox(height: 16),
                const _RoundsIndicator(),
                const SizedBox(height: 18),
                const _Controls(),
                const SizedBox(height: 18),
                const _TimerConfig(),
                const _CountdownDurations(),
                SizedBox(height: LayoutConstants.getNavbarClearance(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.all(5),
      borderRadius: 18,
      child: Row(
        children: [
          _ModeTab(
            label: 'Pomodoro',
            icon: LucideIcons.brain,
            mode: TimerMode.pomodoro,
            selected: timer.mode == TimerMode.pomodoro,
            onTap: () => _setMode(context, TimerMode.pomodoro),
          ),
          _ModeTab(
            label: 'Countdown',
            icon: LucideIcons.timer,
            mode: TimerMode.countdown,
            selected: timer.mode == TimerMode.countdown,
            onTap: () => _setMode(context, TimerMode.countdown),
          ),
          _ModeTab(
            label: 'Stopwatch',
            icon: LucideIcons.clock,
            mode: TimerMode.stopwatch,
            selected: timer.mode == TimerMode.stopwatch,
            onTap: () => _setMode(context, TimerMode.stopwatch),
          ),
        ],
      ),
    );
  }

  void _setMode(BuildContext context, TimerMode mode) {
    context.read<TimerProvider>().setMode(mode);
    HapticFeedback.selectionClick();
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimerMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final color = _accentForMode(mode, context.watch<TimerProvider>());

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : themeProvider.textSecondary,
                size: 19,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : themeProvider.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskPill extends StatelessWidget {
  const _TaskPill();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final timer = context.watch<TimerProvider>();
    if (timer.mode != TimerMode.pomodoro) return const SizedBox.shrink();

    return ElevatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 999,
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppColors.primaryDeep,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Finish design review',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: themeProvider.textTertiary,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _TimerStage extends StatelessWidget {
  const _TimerStage();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final timer = context.watch<TimerProvider>();
    final accent = _accentForMode(timer.mode, timer);
    final track = timer.mode == TimerMode.pomodoro
        ? AppColors.terraTint
        : accent.withValues(alpha: 0.14);

    return SizedBox(
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 236,
            height: 236,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeProvider.cardColor,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.20),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 236,
            height: 236,
            child: CircularProgressIndicator(
              value:
                  timer.mode == TimerMode.stopwatch &&
                      timer.state == TimerState.running
                  ? null
                  : timer.progress.clamp(0, 1),
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/pomodoro_timer.png',
                width: 64,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                timer.formattedTime,
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timer.statusText.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundsIndicator extends StatelessWidget {
  const _RoundsIndicator();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final timer = context.watch<TimerProvider>();
    if (timer.mode != TimerMode.pomodoro) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(timer.totalSessions, (index) {
          final active = index < timer.currentSession;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryDeep
                  : themeProvider.borderColor.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'Round ${timer.currentSession} of ${timer.totalSessions}',
          style: TextStyle(
            color: themeProvider.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: LucideIcons.rotateCcw,
          onTap: timer.state == TimerState.idle ? null : timer.reset,
        ),
        const SizedBox(width: 22),
        _ControlButton(
          icon: timer.state == TimerState.running
              ? LucideIcons.pause
              : LucideIcons.play,
          primary: true,
          onTap: () {
            if (timer.state == TimerState.running) {
              timer.pause();
            } else {
              timer.start();
            }
            HapticFeedback.mediumImpact();
          },
        ),
        const SizedBox(width: 22),
        _ControlButton(
          icon: LucideIcons.skipForward,
          onTap: timer.mode == TimerMode.pomodoro ? timer.skip : null,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final timer = context.watch<TimerProvider>();
    final accent = _accentForMode(timer.mode, timer);
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: primary ? 72 : 50,
        height: primary ? 72 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? accent : themeProvider.cardColor,
          border: primary
              ? null
              : Border.all(
                  color: themeProvider.borderColor.withValues(alpha: 0.35),
                ),
          boxShadow: [
            BoxShadow(
              color: primary
                  ? accent.withValues(alpha: 0.36)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: primary ? 24 : 14,
              offset: Offset(0, primary ? 12 : 7),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: primary ? 30 : 20,
          color: disabled
              ? themeProvider.textTertiary.withValues(alpha: 0.55)
              : primary
              ? Colors.white
              : themeProvider.textSecondary,
        ),
      ),
    );
  }
}

class _TimerConfig extends StatelessWidget {
  const _TimerConfig();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    if (timer.mode != TimerMode.pomodoro) return const SizedBox.shrink();

    return Row(
      children: [
        _ConfigCard(value: '${timer.workDuration ~/ 60}', label: 'Focus min'),
        const SizedBox(width: 10),
        _ConfigCard(value: '${timer.breakDuration ~/ 60}', label: 'Break min'),
        const SizedBox(width: 10),
        _ConfigCard(
          value: '${timer.currentSession}/${timer.totalSessions}',
          label: 'Today',
        ),
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final String value;
  final String label;

  const _ConfigCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Expanded(
      child: ElevatedCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        borderRadius: 17,
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownDurations extends StatelessWidget {
  const _CountdownDurations();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    if (timer.mode != TimerMode.countdown || timer.state != TimerState.idle) {
      return const SizedBox.shrink();
    }

    const durations = [5, 10, 15, 20, 30, 45, 60];
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: durations.map((minutes) {
          final selected = timer.remainingSeconds == minutes * 60;
          return GestureDetector(
            onTap: () => timer.setCountdownDuration(minutes),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.water : themeProvider.cardColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.water
                      : themeProvider.borderColor.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '${minutes}m',
                style: TextStyle(
                  color: selected ? Colors.white : themeProvider.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Color _accentForMode(TimerMode mode, TimerProvider timer) {
  switch (mode) {
    case TimerMode.pomodoro:
      return timer.isBreaktime ? AppColors.routineDeep : AppColors.primaryDeep;
    case TimerMode.countdown:
      return AppColors.waterDeep;
    case TimerMode.stopwatch:
      return AppColors.moodDeep;
  }
}
