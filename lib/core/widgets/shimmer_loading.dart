import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Shimmer loading effect widget for skeleton loading states
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final themeProvider = context.watch<ThemeProvider>();
        final isDark = themeProvider.isDarkMode;

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade700,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
              stops: [0, 0.5 + _animation.value / 4, 1],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton placeholder box
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Dashboard skeleton loader
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            const SkeletonBox(height: 40, width: 200),
            const SizedBox(height: 8),
            const SkeletonBox(height: 20, width: 150),
            const SizedBox(height: 24),

            // Hero card skeleton
            const SkeletonBox(height: 280, borderRadius: 32),
            const SizedBox(height: 24),

            // Section title skeleton
            const SkeletonBox(height: 24, width: 120),
            const SizedBox(height: 16),

            // Cards row skeleton
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 100, borderRadius: 16)),
                const SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 100, borderRadius: 16)),
                const SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 100, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 24),

            // Section cards skeleton
            const SkeletonBox(height: 24, width: 100),
            const SizedBox(height: 16),
            const SkeletonBox(height: 80, borderRadius: 16),
            const SizedBox(height: 12),
            const SkeletonBox(height: 80, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

/// Todo card skeleton loader
class TodoSkeletonLoader extends StatelessWidget {
  const TodoSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: Column(
        children: [
          // Progress header skeleton
          const SkeletonBox(height: 100, borderRadius: 16),
          const SizedBox(height: 20),

          // Todo items skeleton
          for (int i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 72, borderRadius: 16),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
