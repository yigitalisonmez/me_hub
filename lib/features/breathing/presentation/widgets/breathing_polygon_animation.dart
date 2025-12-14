import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/breathing_provider.dart';

/// Polygon-based breathing animation where:
/// - Number of sides = number of active phases
/// - A dot slides along edges at varying speeds based on phase duration
/// - All edges are visually equal length
class BreathingPolygonAnimation extends StatefulWidget {
  const BreathingPolygonAnimation({super.key});

  @override
  State<BreathingPolygonAnimation> createState() =>
      _BreathingPolygonAnimationState();
}

class _BreathingPolygonAnimationState extends State<BreathingPolygonAnimation>
    with TickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();
    final technique = provider.selectedTechnique;

    if (technique == null) return const SizedBox.shrink();

    final techniqueColor = technique.primaryColor;
    final phases = technique.phases;
    final phaseCount = phases.length;

    // Calculate current position on polygon based on phase progress
    final currentPhaseIndex = _getCurrentPhaseIndex(provider, phases);
    final phaseProgress = provider.phaseProgress;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use maximum available space
        final size = constraints.maxWidth.clamp(200.0, 400.0);

        return SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return CustomPaint(
                painter: _PolygonPainter(
                  sides: phaseCount,
                  phases: phases,
                  currentPhaseIndex: currentPhaseIndex,
                  phaseProgress: phaseProgress,
                  color: techniqueColor,
                  glowIntensity: 0.3 + (_glowController.value * 0.2),
                  backgroundColor: themeProvider.cardColor,
                  labelColor: techniqueColor, // Use technique color for labels
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.phaseLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${provider.phaseSecondsRemaining}',
                        style: TextStyle(
                          color: techniqueColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  int _getCurrentPhaseIndex(
    BreathingProvider provider,
    List<({String label, int duration})> phases,
  ) {
    final currentPhase = provider.currentPhase;
    switch (currentPhase) {
      case BreathingPhase.inhale:
        return 0;
      case BreathingPhase.holdIn:
        return phases.indexWhere(
          (p) => p.label == 'Hold' && phases.indexOf(p) == 1,
        );
      case BreathingPhase.exhale:
        return phases.indexWhere((p) => p.label == 'Breathe Out');
      case BreathingPhase.holdOut:
        return phases.length - 1;
    }
  }
}

class _PolygonPainter extends CustomPainter {
  final int sides;
  final List<({String label, int duration})> phases;
  final int currentPhaseIndex;
  final double phaseProgress;
  final Color color;
  final double glowIntensity;
  final Color backgroundColor;
  final Color labelColor;

  _PolygonPainter({
    required this.sides,
    required this.phases,
    required this.currentPhaseIndex,
    required this.phaseProgress,
    required this.color,
    required this.glowIntensity,
    required this.backgroundColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 35; // Smaller margin for bigger polygon

    // Calculate polygon vertices
    final vertices = _getPolygonVertices(center, radius, sides);

    // Draw background polygon with glow
    _drawPolygonGlow(canvas, vertices, color, glowIntensity);

    // Draw polygon edges
    _drawPolygonEdges(canvas, vertices, color, backgroundColor);

    // Draw phase labels at edge midpoints (outside the polygon)
    _drawPhaseLabels(canvas, center, vertices, phases, labelColor);

    // Draw the sliding dot
    _drawSlidingDot(canvas, vertices, currentPhaseIndex, phaseProgress, color);
  }

  List<Offset> _getPolygonVertices(Offset center, double radius, int sides) {
    final vertices = <Offset>[];

    // Special case for 2 sides: create a vertical line (top and bottom)
    if (sides == 2) {
      vertices.add(Offset(center.dx, center.dy - radius)); // Top
      vertices.add(Offset(center.dx, center.dy + radius)); // Bottom
      return vertices;
    }

    // Start from top (-90 degrees) and go clockwise
    final startAngle = -math.pi / 2;

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + (2 * math.pi * i / sides);
      vertices.add(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
      );
    }
    return vertices;
  }

  void _drawPolygonGlow(
    Canvas canvas,
    List<Offset> vertices,
    Color color,
    double intensity,
  ) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: intensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();

    canvas.drawPath(path, glowPaint);
  }

  void _drawPolygonEdges(
    Canvas canvas,
    List<Offset> vertices,
    Color color,
    Color bgColor,
  ) {
    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < vertices.length; i++) {
      final start = vertices[i];
      final end = vertices[(i + 1) % vertices.length];
      canvas.drawLine(start, end, edgePaint);
    }
  }

  void _drawPhaseLabels(
    Canvas canvas,
    Offset center,
    List<Offset> vertices,
    List<({String label, int duration})> phases,
    Color labelColor,
  ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < vertices.length && i < phases.length; i++) {
      final start = vertices[i];
      final end = vertices[(i + 1) % vertices.length];
      final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      // Calculate outward direction from center to midpoint
      final outwardDir = midpoint - center;
      final normalizedOutward = outwardDir / outwardDir.distance;
      // For 2-sided (line), place labels to the left and right
      Offset labelOffset;
      if (sides == 2) {
        // For vertical line: place labels to the side
        labelOffset = Offset(midpoint.dx + (i == 0 ? -50 : 50), midpoint.dy);
      } else {
        labelOffset = midpoint + normalizedOutward * 45;
      }

      // Draw only duration (e.g., "4s")
      textPainter.text = TextSpan(
        text: '${phases[i].duration}s',
        style: TextStyle(
          color: labelColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelOffset.dx - textPainter.width / 2,
          labelOffset.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawSlidingDot(
    Canvas canvas,
    List<Offset> vertices,
    int phaseIndex,
    double progress,
    Color color,
  ) {
    if (phaseIndex < 0 || phaseIndex >= vertices.length) return;

    final start = vertices[phaseIndex];
    final end = vertices[(phaseIndex + 1) % vertices.length];

    // Calculate dot position based on progress
    final dotPosition = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    // Draw glow behind dot
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(dotPosition, 14, glowPaint);

    // Draw main dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotPosition, 10, dotPaint);

    // Draw white center
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotPosition, 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PolygonPainter oldDelegate) {
    return oldDelegate.currentPhaseIndex != currentPhaseIndex ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}
