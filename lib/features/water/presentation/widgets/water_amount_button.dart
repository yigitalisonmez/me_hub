part of '../pages/water_page.dart';

class WaterAmountButton extends StatefulWidget {
  final int amount;
  final String label;
  final ThemeData theme;
  final ThemeProvider themeProvider;
  final bool isSelected;
  final VoidCallback onTap;

  const WaterAmountButton({
    super.key,
    required this.amount,
    required this.label,
    required this.theme,
    required this.themeProvider,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<WaterAmountButton> createState() => _WaterAmountButtonState();
}

class _WaterAmountButtonState extends State<WaterAmountButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 160),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: selected ? AppColors.water : widget.themeProvider.cardColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : widget.themeProvider.isDarkMode
                        ? Colors.white.withValues(alpha: 0.07)
                        : AppColors.textPrimary.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? AppColors.water.withValues(alpha: 0.26)
                          : Colors.black.withValues(
                              alpha: widget.themeProvider.isDarkMode
                                  ? 0.20
                                  : 0.04,
                            ),
                      blurRadius: selected ? 18 : 14,
                      offset: const Offset(0, 8),
                      spreadRadius: selected ? -6 : -10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.droplet,
                      color: selected ? Colors.white : AppColors.waterDeep,
                      size: 17,
                      fill: selected ? 1.0 : 0.0,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: widget.theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? Colors.white
                            : widget.themeProvider.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.amount} ml',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.82)
                            : widget.themeProvider.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
