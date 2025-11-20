import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/theme_provider.dart';

/// A reusable wave progress bar widget
class WaveProgressBar extends StatefulWidget {
  /// Progress value between 0.0 and 1.0
  final double progress;

  /// Gradient for the progress fill (optional, uses theme gradient if not provided)
  final Gradient? gradient;

  /// Height of the progress bar
  final double height;

  /// Optional text to display in the center (e.g., percentage)
  final String? centerText;

  /// Optional text style for center text
  final TextStyle? centerTextStyle;

  /// Optional bottom text (e.g., "5 / 10 today")
  final String? bottomText;

  /// Optional text style for bottom text
  final TextStyle? bottomTextStyle;

  const WaveProgressBar({
    super.key,
    required this.progress,
    this.gradient,
    this.height = 20,
    this.centerText,
    this.centerTextStyle,
    this.bottomText,
    this.bottomTextStyle,
  });

  @override
  State<WaveProgressBar> createState() => _WaveProgressBarState();
}

class _WaveProgressBarState extends State<WaveProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    
    // Use provided gradient or theme-based gradient
    final effectiveGradient = widget.gradient ?? themeProvider.primaryGradient;
    
    // Center text style - white for visibility in dark mode
    final defaultCenterTextStyle =
        widget.centerTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: themeProvider.textPrimary,
          fontWeight: FontWeight.bold,
        );
    
    // Bottom text style - use textSecondary for better visibility
    final defaultBottomTextStyle =
        widget.bottomTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: themeProvider.textSecondary,
          fontWeight: FontWeight.w500,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedProgress, child) {
            return SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Semantics(
                        label: widget.centerText ?? 'Progress',
                        value: '${(widget.progress * 100).toInt()} percent',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CustomPaint(
                            painter: _WaveProgressPainter(
                              progress: animatedProgress,
                              wavePhase: _waveController.value,
                              gradient: effectiveGradient,
                              backgroundColor: themeProvider.surfaceColor,
                            ),
                            size: Size(double.infinity, widget.height),
                          ),
                        ),
                      );
                    },
                  ),
                  // Center text (e.g., percentage)
                  if (widget.centerText != null)
                    Center(
                      child: Text(
                        widget.centerText!,
                        style: defaultCenterTextStyle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (widget.bottomText != null) ...[
          const SizedBox(height: 8),
          Text(widget.bottomText!, style: defaultBottomTextStyle),
        ],
      ],
    );
  }
}

/// Custom painter for progress bar with gentle wave at right edge
class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Gradient gradient;
  final Color backgroundColor;

  _WaveProgressPainter({
    required this.progress,
    required this.wavePhase,
    required this.gradient,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background - use theme-aware color
    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3);
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

    // Draw base gradient fill
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
