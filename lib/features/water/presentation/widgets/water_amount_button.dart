part of '../pages/water_page.dart';

class WaterAmountButton extends StatefulWidget {
  final int amount;
  final String label;
  final ThemeData theme;
  final ThemeProvider themeProvider;
  final VoidCallback onTap;

  const WaterAmountButton({
    super.key,
    required this.amount,
    required this.label,
    required this.theme,
    required this.themeProvider,
    required this.onTap,
  });

  @override
  State<WaterAmountButton> createState() => _WaterAmountButtonState();
}

class _WaterAmountButtonState extends State<WaterAmountButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Press animation
    _controller.forward();
    
    // Call the onTap callback
    widget.onTap();
    
    // Wait a bit then reverse
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) => _handleTap(),
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: widget.themeProvider.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.themeProvider.primaryColor.withValues(
                      alpha: 0.3 * _glowAnimation.value,
                    ),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 5 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.droplet, color: Colors.white, size: 28),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.amount}ml',
                    style: widget.theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
