import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/breathing_provider.dart';
import '../widgets/breathing_circle_animation.dart';
import '../widgets/mood_check_widget.dart';
import '../widgets/session_complete_widget.dart';
import '../widgets/session_settings_sheet.dart';

/// Full-screen immersive breathing session page
class BreathingSessionPage extends StatefulWidget {
  const BreathingSessionPage({super.key});

  @override
  State<BreathingSessionPage> createState() => _BreathingSessionPageState();
}

class _BreathingSessionPageState extends State<BreathingSessionPage>
    with TickerProviderStateMixin {
  bool _controlsVisible = true;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..value = 1.0;

    // Start session if not in quick mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BreathingProvider>();
      if (provider.sessionState == SessionState.idle) {
        provider.startSession();
      }
    });

    // Auto-hide controls after 3 seconds during breathing
    _startControlsAutoHide();
  }

  void _startControlsAutoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controlsVisible) {
        final provider = context.read<BreathingProvider>();
        if (provider.sessionState == SessionState.breathing) {
          setState(() => _controlsVisible = false);
          _fadeController.reverse();
        }
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _fadeController.forward();
    _startControlsAutoHide();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();

    return PopScope(
      canPop:
          provider.sessionState == SessionState.idle ||
          provider.sessionState == SessionState.complete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: _getBackgroundColor(provider, themeProvider),
        body: GestureDetector(
          onTap: _showControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Dynamic gradient background
              _AnimatedBackground(
                phase: provider.currentPhase,
                techniqueColor:
                    provider.selectedTechnique?.primaryColor ??
                    const Color(0xFF4DB6AC),
              ),

              // Main content
              SafeArea(child: _buildMainContent(provider, themeProvider)),

              // Fade-out controls
              FadeTransition(
                opacity: _fadeController,
                child: _buildControls(provider, themeProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(
    BreathingProvider provider,
    ThemeProvider themeProvider,
  ) {
    if (provider.selectedTechnique != null) {
      return provider.selectedTechnique!.primaryColor.withValues(alpha: 0.05);
    }
    return themeProvider.backgroundColor;
  }

  Widget _buildMainContent(
    BreathingProvider provider,
    ThemeProvider themeProvider,
  ) {
    switch (provider.sessionState) {
      case SessionState.idle:
      case SessionState.moodCheckBefore:
        return MoodCheckWidget(
          isBefore: true,
          onMoodSelected: (mood) => provider.setMoodBefore(mood),
        );

      case SessionState.preparing:
        return _PreparingView();

      case SessionState.breathing:
        return _BreathingView(onSettingsTap: () => _showSettings(context));

      case SessionState.moodCheckAfter:
        return MoodCheckWidget(
          isBefore: false,
          onMoodSelected: (mood) => provider.setMoodAfter(mood),
          onSkip: () => provider.skipMoodAfter(),
        );

      case SessionState.complete:
        return SessionCompleteWidget(
          onClose: () {
            provider.reset();
            Navigator.of(context).pop();
          },
        );
    }
  }

  Widget _buildControls(
    BreathingProvider provider,
    ThemeProvider themeProvider,
  ) {
    if (provider.sessionState != SessionState.breathing) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton(
              onPressed: _showExitConfirmation,
              icon: Icon(LucideIcons.x, color: themeProvider.textSecondary),
            ),
            // Settings button
            IconButton(
              onPressed: () => _showSettings(context),
              icon: Icon(
                LucideIcons.settings,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SessionSettingsSheet(),
    );
  }

  void _showExitConfirmation() {
    final themeProvider = context.read<ThemeProvider>();
    final provider = context.read<BreathingProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Text(
              'End Session?',
              style: TextStyle(color: themeProvider.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Your current session will be stopped. Are you sure?',
          style: TextStyle(color: themeProvider.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Continue',
              style: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.stopSession();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final BreathingPhase phase;
  final Color techniqueColor;

  const _AnimatedBackground({
    required this.phase,
    required this.techniqueColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            techniqueColor.withValues(alpha: 0.08),
            themeProvider.backgroundColor,
          ],
        ),
      ),
    );
  }
}

class _PreparingView extends StatefulWidget {
  @override
  State<_PreparingView> createState() => _PreparingViewState();
}

class _PreparingViewState extends State<_PreparingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _countdown = 3;
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get into a comfortable position',
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              return Container(
                width: 120 + (_pulseController.value * 20),
                height: 120 + (_pulseController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (provider.selectedTechnique?.primaryColor ??
                              const Color(0xFF4DB6AC))
                          .withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            provider.selectedTechnique?.nameEn ?? '',
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingView extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _BreathingView({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();

    return Column(
      children: [
        const Spacer(),

        // Breathing circle animation
        const BreathingCircleAnimation(),

        const Spacer(),

        // Bottom info
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Remaining time
              Text(
                provider.formattedRemainingTime,
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              // Cycles completed
              Text(
                '${provider.cyclesCompleted} cycles completed',
                style: TextStyle(
                  color: themeProvider.textSecondary.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: provider.sessionProgress,
                  backgroundColor: themeProvider.cardColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    provider.selectedTechnique?.primaryColor ??
                        const Color(0xFF4DB6AC),
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
