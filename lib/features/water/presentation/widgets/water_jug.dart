import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../core/constants/water_constants.dart';

class WaterJug extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int currentAmount;
  final int goalAmount;

  const WaterJug({
    super.key,
    required this.progress,
    required this.currentAmount,
    required this.goalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glass with SVG outline and animated water fill
          SizedBox(
            width: 240,
            height: 320,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // SVG glass outline
                SvgPicture.asset(
                  'assets/svg/empty-glass.svg',
                  width: 240,
                  height: 320,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                // Animated water fill (clipped to glass shape)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, child) {
                    // SVG viewBox is 64x64, glass dimensions (after transform):
                    // Top: y = 5.407 (1.657 + 3.75 transform)
                    // Bottom: y = 58.158 (54.408 + 3.75 transform)
                    // Scaled to 240x320 widget:
                    final scaleY = 320.0 / 64.0;
                    final glassTop = 5.407 * scaleY;
                    final glassBottom = 58.158 * scaleY;
                    final glassHeight = glassBottom - glassTop;
                    final waterHeight = glassHeight * animatedProgress;
                    final waterTop = glassBottom - waterHeight;
                    
                    return ClipPath(
                      clipper: GlassClipper(),
                      child: Stack(
                        children: [
                          // Water fill from bottom
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            top: waterTop,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    WaterConstants.waterBlueLight,
                                    WaterConstants.waterBlue,
                                    WaterConstants.waterBlueDark,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Percentage and icon overlay
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.0,
                          end: progress.clamp(0.0, 1.0),
                        ),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedProgress, child) {
                          return Text(
                            '${(animatedProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: animatedProgress > 0.4
                                  ? AppColors.white
                                  : AppColors.primaryOrangeDark,
                              shadows: animatedProgress > 0.4
                                  ? [
                                      Shadow(
                                        color: WaterConstants.waterBlueDark
                                            .withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        offset: const Offset(2, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.0,
                          end: progress.clamp(0.0, 1.0),
                        ),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedProgress, child) {
                          return Icon(
                            LucideIcons.droplet,
                            color: animatedProgress > 0.4
                                ? AppColors.white
                                : WaterConstants.waterBlueDark,
                            size: 32,
                            shadows: animatedProgress > 0.4
                                ? [
                                    Shadow(
                                      color: WaterConstants.waterBlueDark
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      offset: const Offset(2, 2),
                                    ),
                                  ]
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Amount display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$currentAmount ml / $goalAmount ml',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper that matches the interior shape of the glass from the SVG
/// SVG viewBox: 64x64, glass path coordinates (after transform translate(10.395, 3.75)):
/// - Top left: (12.055, 5.407) = (1.66 + 10.395, 1.657 + 3.75)
/// - Top right: (50.754, 5.407) = (40.359 + 10.395, 1.657 + 3.75)
/// - Bottom left: (16.746, 58.158) = (6.351 + 10.395, 54.408 + 3.75)
/// - Bottom right: (46.063, 58.158) = (35.668 + 10.395, 54.408 + 3.75)
/// The glass is a trapezoid with straight sides
class GlassClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // SVG viewBox: 64x64, scale to widget size
    final scaleX = size.width / 64.0;
    final scaleY = size.height / 64.0;
    
    // Glass coordinates in SVG (after transform):
    final topLeftX = 12.055 * scaleX;
    final topRightX = 50.754 * scaleX;
    final topY = 5.407 * scaleY;
    final bottomLeftX = 16.746 * scaleX;
    final bottomRightX = 46.063 * scaleX;
    final bottomY = 58.158 * scaleY;
    
    // Account for stroke width (1.8 in SVG, scaled and inset by half)
    final strokeOffsetX = 1.8 * scaleX / 2;
    final strokeOffsetY = 1.8 * scaleY / 2;
    
    // Create path matching glass interior (inset for stroke)
    // Start from bottom left
    path.moveTo(bottomLeftX + strokeOffsetX, bottomY - strokeOffsetY);
    
    // Left side (straight line from bottom to top)
    path.lineTo(topLeftX + strokeOffsetX, topY + strokeOffsetY);
    
    // Top edge (horizontal)
    path.lineTo(topRightX - strokeOffsetX, topY + strokeOffsetY);
    
    // Right side (straight line from top to bottom)
    path.lineTo(bottomRightX - strokeOffsetX, bottomY - strokeOffsetY);
    
    // Bottom edge (horizontal, back to start)
    path.lineTo(bottomLeftX + strokeOffsetX, bottomY - strokeOffsetY);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
