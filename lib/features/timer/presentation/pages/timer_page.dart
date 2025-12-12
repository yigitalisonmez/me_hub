import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../providers/timer_provider.dart';
import '../widgets/timer_display.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
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
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildModeSelector(themeProvider),
                const SizedBox(height: 32),
                _buildTimerCard(themeProvider),
                const SizedBox(height: 24),
                _buildControls(themeProvider),
                const SizedBox(height: 24),
                _buildSessionInfo(themeProvider),
                SizedBox(height: LayoutConstants.getNavbarClearance(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            LucideIcons.arrowLeft,
            color: context.watch<ThemeProvider>().textPrimary,
          ),
        ),
        const Expanded(
          child: PageHeader(
            title: 'Timer',
            subtitle: 'Stay focused & productive',
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ThemeProvider themeProvider) {
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        return ElevatedCard(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _buildModeTab(
                themeProvider,
                timer,
                TimerMode.pomodoro,
                'Pomodoro',
                LucideIcons.brain,
              ),
              _buildModeTab(
                themeProvider,
                timer,
                TimerMode.countdown,
                'Countdown',
                LucideIcons.timer,
              ),
              _buildModeTab(
                themeProvider,
                timer,
                TimerMode.stopwatch,
                'Stopwatch',
                LucideIcons.clock,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTab(
    ThemeProvider themeProvider,
    TimerProvider timer,
    TimerMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = timer.mode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          timer.setMode(mode);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? themeProvider.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : themeProvider.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : themeProvider.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard(ThemeProvider themeProvider) {
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        Color accentColor;
        if (timer.mode == TimerMode.pomodoro) {
          accentColor = timer.isBreaktime
              ? const Color(0xFF4CAF50) // Green for break
              : themeProvider.primaryColor; // Primary for work
        } else if (timer.mode == TimerMode.countdown) {
          accentColor = const Color(0xFF2196F3); // Blue
        } else {
          accentColor = const Color(0xFFFF9800); // Orange
        }

        return ElevatedCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              TimerDisplay(
                progress: timer.progress,
                time: timer.formattedTime,
                statusText: timer.statusText,
                accentColor: accentColor,
                isRunning: timer.state == TimerState.running,
              ),
              if (timer.mode == TimerMode.countdown &&
                  timer.state == TimerState.idle) ...[
                const SizedBox(height: 24),
                _buildDurationSelector(themeProvider, timer),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDurationSelector(
    ThemeProvider themeProvider,
    TimerProvider timer,
  ) {
    final durations = [5, 10, 15, 20, 30, 45, 60];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: durations.map((minutes) {
        final isSelected = timer.remainingSeconds == minutes * 60;
        return GestureDetector(
          onTap: () => timer.setCountdownDuration(minutes),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeProvider.primaryColor
                  : themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.borderColor,
              ),
            ),
            child: Text(
              '${minutes}m',
              style: TextStyle(
                color: isSelected ? Colors.white : themeProvider.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControls(ThemeProvider themeProvider) {
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset button
            _buildControlButton(
              themeProvider,
              icon: LucideIcons.rotateCcw,
              onPressed: timer.state != TimerState.idle ? timer.reset : null,
              isSecondary: true,
            ),
            const SizedBox(width: 24),
            // Play/Pause button
            _buildControlButton(
              themeProvider,
              icon: timer.state == TimerState.running
                  ? LucideIcons.pause
                  : LucideIcons.play,
              onPressed: () {
                if (timer.state == TimerState.running) {
                  timer.pause();
                } else {
                  timer.start();
                }
                HapticFeedback.mediumImpact();
              },
              isPrimary: true,
            ),
            const SizedBox(width: 24),
            // Skip button (only for Pomodoro)
            _buildControlButton(
              themeProvider,
              icon: LucideIcons.skipForward,
              onPressed:
                  timer.mode == TimerMode.pomodoro &&
                      timer.state != TimerState.idle
                  ? timer.reset
                  : null,
              isSecondary: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton(
    ThemeProvider themeProvider, {
    required IconData icon,
    VoidCallback? onPressed,
    bool isPrimary = false,
    bool isSecondary = false,
  }) {
    final size = isPrimary ? 72.0 : 52.0;
    final iconSize = isPrimary ? 32.0 : 24.0;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary
              ? themeProvider.primaryColor
              : themeProvider.surfaceColor,
          shape: BoxShape.circle,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: themeProvider.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: onPressed == null
                ? themeProvider.textSecondary.withValues(alpha: 0.3)
                : (isPrimary ? Colors.white : themeProvider.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo(ThemeProvider themeProvider) {
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        if (timer.mode != TimerMode.pomodoro) {
          return const SizedBox.shrink();
        }

        return ElevatedCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                themeProvider,
                'Session',
                '${timer.currentSession}/${timer.totalSessions}',
                LucideIcons.target,
              ),
              Container(width: 1, height: 40, color: themeProvider.borderColor),
              _buildInfoItem(
                themeProvider,
                'Work',
                '${timer.workDuration ~/ 60}m',
                LucideIcons.brain,
              ),
              Container(width: 1, height: 40, color: themeProvider.borderColor),
              _buildInfoItem(
                themeProvider,
                'Break',
                '${timer.breakDuration ~/ 60}m',
                LucideIcons.coffee,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(
    ThemeProvider themeProvider,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: themeProvider.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: themeProvider.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: themeProvider.textSecondary),
        ),
      ],
    );
  }
}
