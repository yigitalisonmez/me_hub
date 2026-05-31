import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/reminder_offset.dart';
import '../providers/calendar_provider.dart';

/// Add or edit event bottom sheet with custom animations
class EventBottomSheet extends StatefulWidget {
  final CalendarEvent? event; // null for new event, non-null for edit
  final DateTime? initialDate; // Initial date for new events

  const EventBottomSheet({super.key, this.event, this.initialDate});

  /// Show the bottom sheet to add a new event
  static Future<bool?> showAdd(BuildContext context, {DateTime? initialDate}) {
    return _show(context, null, initialDate: initialDate);
  }

  /// Show the bottom sheet to edit an existing event
  static Future<bool?> showEdit(BuildContext context, CalendarEvent event) {
    return _show(context, event);
  }

  static Future<bool?> _show(
    BuildContext context,
    CalendarEvent? event, {
    DateTime? initialDate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      builder: (context) =>
          EventBottomSheet(event: event, initialDate: initialDate),
    );
  }

  @override
  State<EventBottomSheet> createState() => _EventBottomSheetState();
}

class _EventBottomSheetState extends State<EventBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderOffset _selectedReminderOffset;
  late bool _hasReminder;
  String? _selectedCategoryId;
  bool _isLoading = false;

  bool get isEditMode => widget.event != null;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize with existing event data if editing
    if (isEditMode) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _selectedDate = event.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(event.dateTime);
      _selectedReminderOffset = event.reminderOffsetEnum;
      _hasReminder = event.hasReminder;
      _selectedCategoryId = event.categoryId;
    } else {
      // Use initial date if provided, otherwise use current date
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedReminderOffset = ReminderOffset.fiveMinutes;
      _hasReminder = true;
      _selectedCategoryId = null;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final calendarProvider = context.read<CalendarProvider>();
    bool success;

    if (isEditMode) {
      // Update existing event
      final updatedEvent = widget.event!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTime: _combinedDateTime,
        reminderOffset: _selectedReminderOffset.toHiveReminderOffset(),
        hasReminder: _hasReminder,
        categoryId: _selectedCategoryId,
      );
      success = await calendarProvider.updateEvent(updatedEvent);
    } else {
      // Add new event
      success = await calendarProvider.addEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTime: _combinedDateTime,
        reminderOffset: _selectedReminderOffset,
        hasReminder: _hasReminder,
        categoryId: _selectedCategoryId,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);

      // Animate out before closing
      await _animationController.reverse();
      if (mounted) {
        Navigator.pop(context, success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: themeProvider.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar with animation
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 40.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Container(
                          width: value,
                          height: 4,
                          decoration: BoxDecoration(
                            color: themeProvider.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header with staggered animation
                  _buildAnimatedItem(
                    delay: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: themeProvider.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEditMode
                                    ? LucideIcons.pencil
                                    : LucideIcons.calendarPlus,
                                color: themeProvider.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditMode ? 'Edit Event' : 'New Event',
                              style: TextStyle(
                                color: themeProvider.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () async {
                            await _animationController.reverse();
                            if (!mounted || !context.mounted) return;
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            LucideIcons.x,
                            color: themeProvider.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title field
                  _buildAnimatedItem(
                    delay: 50,
                    child: _buildInputField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Enter event title',
                      icon: LucideIcons.type,
                      themeProvider: themeProvider,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  _buildAnimatedItem(
                    delay: 100,
                    child: _buildInputField(
                      controller: _descriptionController,
                      label: 'Description (optional)',
                      hint: 'Event details',
                      icon: LucideIcons.fileText,
                      themeProvider: themeProvider,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category chips - neumorphic style
                  _buildAnimatedItem(
                    delay: 125,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.tag,
                              size: 16,
                              color: themeProvider.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Category',
                              style: TextStyle(
                                color: themeProvider.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: EventCategory.predefinedCategories.map((
                            category,
                          ) {
                            final isSelected =
                                _selectedCategoryId == category.id;
                            final isDark = themeProvider.isDarkMode;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = isSelected
                                      ? null
                                      : category.id;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? themeProvider.primaryColor
                                      : themeProvider.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    // Light shadow (top-left)
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.white.withValues(
                                              alpha: isSelected ? 0.3 : 0.6,
                                            ),
                                      offset: const Offset(-2, -2),
                                      blurRadius: 4,
                                    ),
                                    // Dark shadow (bottom-right)
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.3)
                                          : Colors.black.withValues(
                                              alpha: isSelected ? 0.15 : 0.08,
                                            ),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category.icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : themeProvider.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : themeProvider.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date & Time pickers
                  _buildAnimatedItem(
                    delay: 150,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPickerTile(
                            icon: LucideIcons.calendar,
                            label: 'Date',
                            value: _formatDate(_selectedDate),
                            onTap: _pickDate,
                            themeProvider: themeProvider,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPickerTile(
                            icon: LucideIcons.clock,
                            label: 'Time',
                            value: _formatTime(_selectedTime),
                            onTap: _pickTime,
                            themeProvider: themeProvider,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reminder toggle
                  _buildAnimatedItem(
                    delay: 200,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider.textSecondary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: themeProvider.primaryColor
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      LucideIcons.bell,
                                      size: 18,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Reminder',
                                    style: TextStyle(
                                      color: themeProvider.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _hasReminder,
                                onChanged: (value) =>
                                    setState(() => _hasReminder = value),
                                activeColor: themeProvider.primaryColor,
                              ),
                            ],
                          ),

                          // Reminder offset selector with animation
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _hasReminder
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeProvider.backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: themeProvider.textSecondary
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<ReminderOffset>(
                                          value: _selectedReminderOffset,
                                          isExpanded: true,
                                          icon: Icon(
                                            LucideIcons.chevronDown,
                                            color: themeProvider.textSecondary,
                                          ),
                                          dropdownColor:
                                              themeProvider.surfaceColor,
                                          style: TextStyle(
                                            color: themeProvider.textPrimary,
                                            fontSize: 15,
                                          ),
                                          items: ReminderOffset.values.map((
                                            offset,
                                          ) {
                                            return DropdownMenuItem(
                                              value: offset,
                                              child: Text(offset.displayName),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(
                                                () => _selectedReminderOffset =
                                                    value,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button with animation
                  _buildAnimatedItem(
                    delay: 250,
                    child: SizedBox(
                      width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor: themeProvider.primaryColor.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isEditMode
                                          ? LucideIcons.save
                                          : LucideIcons.check,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEditMode
                                          ? 'Update Event'
                                          : 'Save Event',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider themeProvider,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: themeProvider.textPrimary),
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: themeProvider.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(
          color: themeProvider.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, color: themeProvider.primaryColor),
        filled: true,
        fillColor: themeProvider.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: themeProvider.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: themeProvider.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: themeProvider.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: themeProvider.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Backward compatibility alias
typedef AddEventBottomSheet = EventBottomSheet;
