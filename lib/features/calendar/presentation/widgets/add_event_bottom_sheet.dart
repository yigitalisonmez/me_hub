import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/reminder_offset.dart';
import '../providers/calendar_provider.dart';

enum _ItemType { task, event, routine }

class EventBottomSheet extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime? initialDate;

  const EventBottomSheet({super.key, this.event, this.initialDate});

  static Future<bool?> showAdd(BuildContext context, {DateTime? initialDate}) {
    return _show(context, null, initialDate: initialDate);
  }

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
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderOffset _selectedReminderOffset;
  late bool _hasReminder;
  bool _showNote = false;
  bool _isLoading = false;
  _ItemType _selectedType = _ItemType.event;

  // Repeat: visual only — CalendarEvent model doesn't support repeat yet
  final List<bool> _repeatDays = List.filled(7, false);

  bool get isEditMode => widget.event != null;

  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  static const _quickReminders = [
    (ReminderOffset.fiveMinutes, 'At time'),
    (ReminderOffset.fifteenMinutes, '15 min'),
    (ReminderOffset.oneHour, '1 hour'),
    (ReminderOffset.oneDay, '1 day'),
  ];

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final e = widget.event!;
      _titleController.text = e.title;
      _noteController.text = e.description ?? '';
      _showNote = e.description?.isNotEmpty == true;
      _selectedDate = e.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(e.dateTime);
      _selectedReminderOffset = e.reminderOffsetEnum;
      _hasReminder = e.hasReminder;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedReminderOffset = ReminderOffset.fifteenMinutes;
      _hasReminder = true;
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final calendarProvider = context.read<CalendarProvider>();
    final note =
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    bool success;

    if (isEditMode) {
      final updated = widget.event!.copyWith(
        title: _titleController.text.trim(),
        description: note,
        dateTime: _combinedDateTime,
        reminderOffset: _selectedReminderOffset.toHiveReminderOffset(),
        hasReminder: _hasReminder,
      );
      success = await calendarProvider.updateEvent(updated);
    } else {
      success = await calendarProvider.addEvent(
        title: _titleController.text.trim(),
        description: note,
        dateTime: _combinedDateTime,
        reminderOffset: _selectedReminderOffset,
        hasReminder: _hasReminder,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      await _animController.reverse();
      if (mounted) Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: child),
      ),
      child: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: themeProvider.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandle(themeProvider),
                const SizedBox(height: 16),
                _buildHeader(themeProvider),
                const SizedBox(height: 16),
                _buildTypeSelector(themeProvider),
                const SizedBox(height: 18),
                _buildTitleField(themeProvider),
                const SizedBox(height: 14),
                _buildDateTimeRow(themeProvider),
                const SizedBox(height: 16),
                _buildRepeatRow(themeProvider),
                const SizedBox(height: 16),
                _buildReminderCard(themeProvider),
                const SizedBox(height: 12),
                _buildAddNoteRow(themeProvider),
                const SizedBox(height: 22),
                _buildSaveButton(themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeProvider themeProvider) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: themeProvider.textSecondary.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await _animController.reverse();
            if (mounted) Navigator.pop(context);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: themeProvider.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              LucideIcons.x,
              size: 17,
              color: themeProvider.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            isEditMode ? 'Edit event' : 'New item',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }

  Widget _buildTypeSelector(ThemeProvider themeProvider) {
    final types = [
      (_ItemType.task, LucideIcons.check, 'Task', AppColors.primary,
          AppColors.primaryDeep),
      (_ItemType.event, LucideIcons.calendar, 'Event', AppColors.waterDeep,
          AppColors.waterDeep),
      (_ItemType.routine, LucideIcons.refreshCw, 'Routine', AppColors.routine,
          AppColors.routineDeep),
    ];

    return Row(
      children: types.map((item) {
        final selected = _selectedType == item.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item == types.last ? 0 : 9,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedType = item.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: selected
                      ? item.$4.withValues(alpha: 0.12)
                      : themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? item.$4
                        : themeProvider.textSecondary.withValues(alpha: 0.14),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$2,
                      size: 18,
                      color: selected ? item.$5 : themeProvider.textSecondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$3,
                      style: TextStyle(
                        color: selected ? item.$5 : themeProvider.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTitleField(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('TITLE', themeProvider),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
          decoration: InputDecoration(
            hintText: 'e.g. Design review',
            hintStyle: TextStyle(
              color: themeProvider.textSecondary.withValues(alpha: 0.50),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: themeProvider.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: themeProvider.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: themeProvider.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.waterDeep,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(ThemeProvider themeProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildPickerTile(
            label: 'DATE',
            value: _formatDate(_selectedDate),
            icon: LucideIcons.calendar,
            onTap: _pickDate,
            themeProvider: themeProvider,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPickerTile(
            label: 'TIME',
            value: _formatTime(_selectedTime),
            icon: LucideIcons.clock,
            onTap: _pickTime,
            themeProvider: themeProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: themeProvider.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Icon(icon, size: 16, color: AppColors.waterDeep),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatRow(ThemeProvider themeProvider) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final anyOn = _repeatDays.any((d) => d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('REPEAT', themeProvider),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final on = _repeatDays[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? 5 : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _repeatDays[i] = !_repeatDays[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 34,
                    decoration: BoxDecoration(
                      color: on
                          ? AppColors.waterDeep.withValues(alpha: 0.12)
                          : themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: on
                            ? AppColors.waterDeep
                            : themeProvider.textSecondary.withValues(
                                alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[i],
                        style: TextStyle(
                          color: on
                              ? AppColors.waterDeep
                              : themeProvider.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        Text(
          anyOn ? 'Repeats on selected days' : 'No repeat · one-time',
          style: TextStyle(
            color: themeProvider.textSecondary.withValues(alpha: 0.65),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(ThemeProvider themeProvider) {
    final previewTime = _hasReminder
        ? _reminderPreviewText()
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: themeProvider.textSecondary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.waterDeep.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.bell,
                  size: 17,
                  color: AppColors.waterDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder',
                      style: TextStyle(
                        color: themeProvider.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Notify me before it starts',
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _hasReminder,
                onChanged: (v) => setState(() => _hasReminder = v),
                activeColor: AppColors.waterDeep,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _hasReminder
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      Row(
                        children: _quickReminders.map((item) {
                          final selected = _selectedReminderOffset == item.$1;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: item == _quickReminders.last ? 0 : 7,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                    () => _selectedReminderOffset = item.$1,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.waterDeep.withValues(
                                            alpha: 0.12,
                                          )
                                        : themeProvider.backgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.waterDeep
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.$2,
                                      style: TextStyle(
                                        color: selected
                                            ? AppColors.waterDeep
                                            : themeProvider.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (previewTime != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.waterDeep.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: themeProvider.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.bell,
                                  size: 13,
                                  color: AppColors.waterDeep,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  previewTime,
                                  style: const TextStyle(
                                    color: AppColors.waterDeep,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNoteRow(ThemeProvider themeProvider) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showNote = !_showNote),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.textSecondary.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.mindfulTint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    LucideIcons.bookmarkCheck,
                    size: 15,
                    color: AppColors.mindfulDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _showNote ? 'Note' : 'Add note',
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _showNote ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 17,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: _showNote
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 14.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a note…',
                      hintStyle: TextStyle(
                        color: themeProvider.textSecondary.withValues(
                          alpha: 0.50,
                        ),
                      ),
                      filled: true,
                      fillColor: themeProvider.cardColor,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: themeProvider.textSecondary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: themeProvider.textSecondary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.mindfulDeep,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.waterDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            : Text(
                isEditMode ? 'Update event' : 'Add to calendar',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _reminderPreviewText() {
    final notifyTime = _combinedDateTime.subtract(
      _selectedReminderOffset.duration,
    );
    final h = notifyTime.hour.toString().padLeft(2, '0');
    final m = notifyTime.minute.toString().padLeft(2, '0');
    final label = _quickReminders
        .firstWhere((r) => r.$1 == _selectedReminderOffset)
        .$2;
    return 'Notification at $h:$m · $label before';
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final ThemeProvider themeProvider;

  const _FieldLabel(this.text, this.themeProvider);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: themeProvider.textSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

// Backward compat alias
typedef AddEventBottomSheet = EventBottomSheet;
