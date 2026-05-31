import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/reminder_offset.dart';

/// Event card widget with animations
class EventCard extends StatefulWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnimController;
  late Animation<double> _scaleAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _checkAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  void _onComplete() async {
    await _checkAnimController.forward();
    await _checkAnimController.reverse();
    widget.onComplete?.call();
  }

  void _onDelete() {
    setState(() => _isDeleting = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onDelete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final event = widget.event;
    final isPast = event.isPast && !event.isCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isDeleting ? 0.0 : 1.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isDeleting ? const Offset(1, 0) : Offset.zero,
        child: Dismissible(
          key: Key(event.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _onDelete(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(LucideIcons.trash2, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ElevatedCard(
              onTap: widget.onTap,
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Completion checkbox with animation
                  GestureDetector(
                    onTap: _onComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: event.isCompleted
                            ? themeProvider.primaryColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: event.isCompleted
                              ? themeProvider.primaryColor
                              : themeProvider.textSecondary.withValues(
                                  alpha: 0.4,
                                ),
                          width: 2,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: event.isCompleted ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Icon(
                          LucideIcons.check,
                          size: 16,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Event information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: event.isCompleted
                                ? themeProvider.textSecondary
                                : themeProvider.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: event.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.description != null &&
                            event.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.description!,
                            style: TextStyle(
                              color: themeProvider.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Time indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.red.shade50
                                    : themeProvider.surfaceColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.clock,
                                    size: 12,
                                    color: isPast
                                        ? Colors.red.shade400
                                        : themeProvider.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(event.dateTime),
                                    style: TextStyle(
                                      color: isPast
                                          ? Colors.red.shade400
                                          : themeProvider.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Reminder indicator
                            if (event.hasReminder)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.bell,
                                      size: 12,
                                      color: themeProvider.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.reminderOffsetEnum.shortName,
                                      style: TextStyle(
                                        color: themeProvider.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron with animation
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: event.isCompleted ? 0.3 : 0.5,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
