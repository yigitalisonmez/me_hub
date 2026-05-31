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
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.05, 0)).animate(
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
    setState(() => _isDeleting = true);
    HapticFeedback.mediumImpact();
    await _animationController.forward();
    await widget.provider.deleteLog(widget.log.id);

    if (!mounted) return;
    final themeProvider = context.read<ThemeProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.check, color: AppColors.waterDeep, size: 20),
            const SizedBox(width: 12),
            Text(
              '${widget.log.amountMl} ml deleted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: themeProvider.surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final timeString = DateFormat('HH:mm').format(widget.log.timestamp);

    return SwipeToDismissWrapper(
      itemId: widget.log.id,
      onDelete: _handleDelete,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.textPrimary.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: themeProvider.isDarkMode ? 0.20 : 0.04,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? AppColors.waterTint.withValues(alpha: 0.12)
                        : AppColors.waterTint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    LucideIcons.droplet,
                    color: AppColors.waterDeep,
                    size: 16,
                    fill: 1.0,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _labelForAmount(widget.log.amountMl),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeProvider.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  timeString,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: themeProvider.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${widget.log.amountMl} ml',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.waterDeep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: themeProvider.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _labelForAmount(int amountMl) {
  if (amountMl >= 500) return 'Large';
  if (amountMl >= 330) return 'Bottle';
  return 'Glass';
}
