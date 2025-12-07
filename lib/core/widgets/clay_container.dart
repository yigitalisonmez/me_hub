import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ClayContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final Color? color;
  final Color? surfaceColor;
  final Color? parentColor;
  final double borderRadius;
  final double depth;
  final double spread;
  final bool emboss;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;
  final VoidCallback? onTap;

  const ClayContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.color,
    this.surfaceColor,
    this.parentColor,
    this.borderRadius = 20,
    this.depth = 8,
    this.spread = 4,
    this.emboss = false,
    this.padding,
    this.margin,
    this.shape = BoxShape.rectangle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color finalColor = color ?? surfaceColor ?? AppColors.surface;

    // Claymorphism shadows
    // Light source top-left:
    // Shadow 1 (Top-Left): Light (White)
    // Shadow 2 (Bottom-Right): Dark (Shadow color)

    final Color shadowColor = Colors.black.withValues(alpha: 0.1);
    final Color lightColor = Colors.white.withValues(alpha: 0.8);

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: finalColor,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
        shape: shape,
        boxShadow: emboss
            ? [
                // Inner Shadow Simulation (Not true inner shadow, but "pressed" look)
                // We can't do true inner shadow easily without custom painter.
                // For now, we'll use a flat look with a border for "pressed"
                // or inverted shadows if we were using a package.
                // Let's simulate "pressed" by removing outer shadows and adding a subtle border
                // and maybe a slightly darker color if not overridden.
              ]
            : [
                // Outer Shadows
                BoxShadow(
                  color: lightColor,
                  offset: Offset(-depth / 2, -depth / 2),
                  blurRadius: spread,
                ),
                BoxShadow(
                  color: shadowColor,
                  offset: Offset(depth / 2, depth / 2),
                  blurRadius: spread,
                ),
              ],
        // For emboss, we can add a subtle border to define edges
        border: emboss
            ? Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}
