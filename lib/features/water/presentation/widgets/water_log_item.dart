part of '../pages/water_page.dart';

class WaterLogItem extends StatefulWidget {
  final WaterLog log;
  final WaterProvider provider;

  const WaterLogItem({super.key, required this.log, required this.provider});

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.5, 0)).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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

    // Delete the log
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
          backgroundColor: themeProvider.surfaceColor,
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

    return SwipeToDismissWrapper(
      itemId: widget.log.id,
      onDelete: _handleDelete,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ElevatedCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: 16,
            isSurface: true,
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.droplet,
                      color: themeProvider.primaryColor,
                      size: 22,
                    ),
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
                // Swipe hint
                Icon(
                  LucideIcons.chevronLeft,
                  size: 16,
                  color: themeProvider.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
