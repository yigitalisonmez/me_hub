part of '../pages/water_page.dart';
// ClayContainer is imported in water_page.dart

class WaterStatCard extends StatefulWidget {
  final String value;
  final String label;
  final ThemeData theme;
  final ThemeProvider themeProvider;

  const WaterStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.theme,
    required this.themeProvider,
  });

  @override
  State<WaterStatCard> createState() => _WaterStatCardState();
}

class _WaterStatCardState extends State<WaterStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _previousValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _previousValue = widget.value;
    // Start animation on first render
    _controller.forward();
  }

  @override
  void didUpdateWidget(WaterStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _previousValue) {
      _previousValue = widget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: 16,
      emboss: true,
      color: widget.themeProvider.surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      widget.value,
                      style: widget.theme.textTheme.headlineMedium?.copyWith(
                        color: widget.themeProvider.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.themeProvider.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class WaterStatusCard extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final ThemeProvider themeProvider;

  const WaterStatusCard({
    super.key,
    required this.label,
    required this.theme,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: 16,
      emboss: true,
      color: themeProvider.surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, color: themeProvider.primaryColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: themeProvider.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
