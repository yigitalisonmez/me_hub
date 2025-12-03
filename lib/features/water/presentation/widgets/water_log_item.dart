part of '../pages/water_page.dart';

class WaterLogItem extends StatefulWidget {
  final WaterLog log;
  final WaterProvider provider;

  const WaterLogItem({
    super.key,
    required this.log,
    required this.provider,
  });

  @override
  State<WaterLogItem> createState() => _WaterLogItemState();
}

class _WaterLogItemState extends State<WaterLogItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.5, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Start animation
    await _animationController.forward();

    // Delete after animation completes
    widget.provider.deleteLog(widget.log.id);

    // Show confirmation snackbar
    if (mounted) {
      final themeProvider = context.read<ThemeProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                LucideIcons.check,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.log.amountMl}ml deleted',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeProvider.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          backgroundColor: themeProvider.backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(widget.log.timestamp);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeProvider.borderColor,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.droplet,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Amount and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.log.amountMl}ml',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button with visual feedback
              GestureDetector(
                onTap: _handleDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isDeleting
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
