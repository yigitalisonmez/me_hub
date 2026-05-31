import 'package:flutter/material.dart';
import 'dart:math' as math;

/// An animated circular progress ring with customizable appearance.
///
/// Used for displaying progress in Todo, Routines, and other features.
///
/// Example:
/// ```dart
/// ProgressRing(
///   progress: 0.75,
///   size: 64,
///   color: themeProvider.primaryColor,
///   centerWidget: Text('75%'),
/// )
/// ```
class ProgressRing extends StatelessWidget {
  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Overall size of the ring
  final double size;

  /// Width of the progress stroke
  final double strokeWidth;

  /// Color of the progress arc
  final Color color;

  /// Background track color (defaults to color at 20% opacity)
  final Color? backgroundColor;

  /// Widget to display in the center
  final Widget? centerWidget;

  /// Animation duration
  final Duration animationDuration;

  /// Animation curve
  final Curve animationCurve;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 6,
    required this.color,
    this.backgroundColor,
    this.centerWidget,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                backgroundColor ?? color.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Animated progress arc
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: animationDuration,
              curve: animationCurve,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: value,
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                );
              },
            ),
          ),
          // Center content
          if (centerWidget != null) centerWidget!,
        ],
      ),
    );
  }
}

/// Custom painter for the progress arc
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A progress ring with percentage text in the center
class PercentageRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final double strokeWidth;
  final TextStyle? textStyle;

  const PercentageRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 64,
    this.strokeWidth = 6,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return ProgressRing(
      progress: progress,
      size: size,
      strokeWidth: strokeWidth,
      color: color,
      centerWidget: Text(
        '$percentage%',
        style:
            textStyle ??
            TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    );
  }
}
