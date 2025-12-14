import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/breathing_provider.dart';

/// Animated breathing circle with expanding/contracting animation
class BreathingCircleAnimation extends StatefulWidget {
  const BreathingCircleAnimation({super.key});

  @override
  State<BreathingCircleAnimation> createState() =>
      _BreathingCircleAnimationState();
}

class _BreathingCircleAnimationState extends State<BreathingCircleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  void _updateAnimation() {
    final provider = context.read<BreathingProvider>();
    final technique = provider.selectedTechnique;
    if (technique == null) return;

    final phase = provider.currentPhase;

    switch (phase) {
      case BreathingPhase.inhale:
        _scaleController.duration = Duration(seconds: technique.inhaleSeconds);
        _scaleController.forward();
        break;
      case BreathingPhase.holdIn:
        // Stay at max scale
        break;
      case BreathingPhase.exhale:
        _scaleController.duration = Duration(seconds: technique.exhaleSeconds);
        _scaleController.reverse();
        break;
      case BreathingPhase.holdOut:
        // Stay at min scale
        break;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();
    final techniqueColor =
        provider.selectedTechnique?.primaryColor ?? const Color(0xFF4DB6AC);

    // Update animation on phase change
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateAnimation());

    return SizedBox(
      width: 280,
      height: 280,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _glowController]),
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final glowIntensity = 0.3 + (_glowController.value * 0.2);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              ...List.generate(3, (index) {
                final ringScale = scale + (index * 0.08);
                final opacity = (0.15 - (index * 0.04)).clamp(0.0, 1.0);

                return Transform.scale(
                  scale: ringScale,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: techniqueColor.withValues(alpha: opacity),
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),

              // Main circle with gradient
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        techniqueColor.withValues(alpha: 0.3 + glowIntensity),
                        techniqueColor.withValues(alpha: 0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: techniqueColor.withValues(alpha: glowIntensity),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // Inner circle
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: techniqueColor.withValues(alpha: 0.2),
                    border: Border.all(
                      color: techniqueColor.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                ),
              ),

              // Phase text and countdown
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.phaseLabel,
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.phaseSecondsRemaining}',
                    style: TextStyle(
                      color: techniqueColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
