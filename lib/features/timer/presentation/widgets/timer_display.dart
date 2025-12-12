import 'dart:math' as math;
import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final double progress;
  final String time;
  final String statusText;
  final Color? accentColor;
  final bool isRunning;

  const TimerDisplay({
    super.key,
    required this.progress,
    required this.time,
    required this.statusText,
    this.accentColor,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.65;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TimerPainter(
          progress: progress,
          accentColor: accentColor ?? Theme.of(context).primaryColor,
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 12,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: accentColor ?? Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color backgroundColor;
  final double strokeWidth;

  _TimerPainter({
    required this.progress,
    required this.accentColor,
    required this.backgroundColor,
    this.strokeWidth = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
