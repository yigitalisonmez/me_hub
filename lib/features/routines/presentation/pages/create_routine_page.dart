import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/reminders/presentation/reminder_settings_provider.dart';
import '../../../../core/reminders/presentation/reminder_permission_prompt.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage({super.key});

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Morning ritual',
  );
  final List<_EditableRoutineStep> _steps = [];
  String? _openIconStepId;

  final List<_RoutineIconOption> _icons = const [
    _RoutineIconOption(LucideIcons.sun, 'sun'),
    _RoutineIconOption(LucideIcons.coffee, 'coffee'),
    _RoutineIconOption(LucideIcons.moon, 'moon'),
    _RoutineIconOption(LucideIcons.droplet, 'water'),
    _RoutineIconOption(LucideIcons.heart, 'heart'),
    _RoutineIconOption(LucideIcons.leaf, 'leaf'),
    _RoutineIconOption(LucideIcons.target, 'target'),
    _RoutineIconOption(LucideIcons.lightbulb, 'idea'),
    _RoutineIconOption(LucideIcons.flame, 'streak'),
    _RoutineIconOption(LucideIcons.clipboardList, 'list'),
  ];

  final List<Color> _colors = const [
    AppColors.mood,
    AppColors.water,
    AppColors.routine,
    AppColors.mindful,
    AppColors.primary,
  ];

  late IconData _selectedIcon;
  late Color _selectedColor;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  List<int> _selectedDays = [0, 1, 2, 3, 4];
  bool _remindMe = false;
  int _reminderMinutesBefore = 5;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedIcon = _icons.first.icon;
    _selectedColor = _colors.first;
    _steps.addAll([
      _EditableRoutineStep(
        id: 'preset_bed',
        controller: TextEditingController(text: 'Make the bed'),
        iconCodePoint: LucideIcons.bed.codePoint,
        durationMinutes: 2,
      ),
      _EditableRoutineStep(
        id: 'preset_stretch',
        controller: TextEditingController(text: 'Stretch - 10 min'),
        iconCodePoint: LucideIcons.activity.codePoint,
        durationMinutes: 10,
      ),
      _EditableRoutineStep(
        id: 'preset_pages',
        controller: TextEditingController(text: 'Morning pages'),
        iconCodePoint: LucideIcons.bookOpen.codePoint,
        durationMinutes: 8,
      ),
    ]);
    _nameController.addListener(_refreshPreview);
    for (final step in _steps) {
      step.controller.addListener(_refreshPreview);
    }
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refreshPreview)
      ..dispose();
    for (final step in _steps) {
      step.controller
        ..removeListener(_refreshPreview)
        ..dispose();
    }
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: 20),
              _LivePreview(
                name: _routineName,
                icon: _selectedIcon,
                color: _selectedColor,
                time: _selectedTime,
                repeatLabel: _repeatLabel,
              ),
              _FieldLabel('Name'),
              _NameField(controller: _nameController),
              _FieldLabel('Icon'),
              _IconGrid(
                icons: _icons,
                selectedIcon: _selectedIcon,
                selectedColor: _selectedColor,
                onSelected: (icon) => setState(() => _selectedIcon = icon),
              ),
              _FieldLabel('Color'),
              _ColorPicker(
                colors: _colors,
                selectedColor: _selectedColor,
                onSelected: (color) => setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _InlineLabel('Time'),
                        const SizedBox(height: 8),
                        _TimeField(time: _selectedTime, onTap: _pickTime),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _InlineLabel('Repeat'),
                        const SizedBox(height: 8),
                        _DaySelector(
                          selectedDays: _selectedDays,
                          onChanged: (days) {
                            setState(() => _selectedDays = days);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _FieldLabel('Steps'),
              _StepsEditor(
                steps: _steps,
                onAdd: _addStep,
                onRemove: _removeStep,
                openIconStepId: _openIconStepId,
                onIconTap: _toggleStepIconPicker,
                onIconSelected: _selectStepIcon,
                onDurationChanged: _changeStepDuration,
              ),
              const SizedBox(height: 18),
              _ReminderCard(
                enabled: _remindMe,
                onChanged: _setReminderEnabled,
                minutesBefore: _reminderMinutesBefore,
                onMinutesChanged: (value) =>
                    setState(() => _reminderMinutesBefore = value),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.routineDeep,
                    disabledBackgroundColor: themeProvider.borderColor
                        .withValues(alpha: 0.55),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create routine',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _routineName {
    final value = _nameController.text.trim();
    return value.isEmpty ? 'Morning ritual' : value;
  }

  String get _repeatLabel {
    if (_selectedDays.length == 7) return 'Every day';
    if (_selectedDays.length == 5 &&
        _selectedDays.every((day) => day >= 0 && day <= 4)) {
      return 'Weekdays';
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return _selectedDays.map((day) => labels[day]).join(', ');
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final themeProvider = context.watch<ThemeProvider>();
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.routineDeep,
              surface: themeProvider.cardColor,
              onSurface: themeProvider.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addStep() {
    final controller = TextEditingController();
    controller.addListener(_refreshPreview);
    setState(
      () => _steps.add(
        _EditableRoutineStep(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          controller: controller,
          iconCodePoint: LucideIcons.circleCheck.codePoint,
          durationMinutes: 5,
        ),
      ),
    );
  }

  void _removeStep(int index) {
    if (_steps.length == 1) return;
    final step = _steps.removeAt(index);
    step.controller
      ..removeListener(_refreshPreview)
      ..dispose();
    setState(() {});
  }

  void _toggleStepIconPicker(_EditableRoutineStep step) {
    setState(() {
      _openIconStepId = _openIconStepId == step.id ? null : step.id;
    });
  }

  void _selectStepIcon(_EditableRoutineStep step, int iconCodePoint) {
    setState(() {
      step.iconCodePoint = iconCodePoint;
      _openIconStepId = null;
    });
  }

  void _changeStepDuration(_EditableRoutineStep step, int delta) {
    setState(() {
      step.durationMinutes = (step.durationMinutes + delta)
          .clamp(1, 60)
          .toInt();
    });
  }

  Future<void> _createRoutine() async {
    if (_isCreating) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter a routine name');
      return;
    }

    if (_selectedDays.isEmpty) {
      _showSnack('Please select at least one day');
      return;
    }

    final filledSteps = _steps
        .where((step) => step.controller.text.trim().isNotEmpty)
        .toList();

    setState(() => _isCreating = true);

    try {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final items = filledSteps.asMap().entries.map((entry) {
        final step = entry.value;
        return RoutineItem(
          id: '${timestamp}_${entry.key}',
          title: step.controller.text.trim(),
          iconCodePoint:
              step.iconCodePoint ?? LucideIcons.circleCheck.codePoint,
          durationMinutes: step.durationMinutes,
        );
      }).toList();

      await context.read<RoutinesProvider>().addNewRoutine(
        name,
        iconCodePoint: _selectedIcon.codePoint,
        time: _selectedTime,
        selectedDays: _selectedDays,
        items: items,
        scheduleNotifications: _remindMe,
        reminderMinutesBefore: _reminderMinutesBefore,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showSnack('Error creating routine: $e', error: true);
    }
  }

  Future<void> _setReminderEnabled(bool value) async {
    if (value) {
      final settings = context.read<ReminderSettingsProvider>();
      final explained = await explainReminderPermissionIfNeeded(
        context,
        settings,
      );
      if (!explained || !mounted) return;
      final allowed = await settings.setMasterEnabled(true);
      if (!allowed) {
        _showSnack('Notifications are blocked in system settings', error: true);
      }
    }
    if (mounted) setState(() => _remindMe = value);
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.routineDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeProvider.borderColor.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.x,
                color: themeProvider.textPrimary,
                size: 19,
              ),
            ),
          ),
        ),
        Text(
          'New routine',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LivePreview extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final TimeOfDay time;
  final String repeatLabel;

  const _LivePreview({
    required this.name,
    required this.icon,
    required this.color,
    required this.time,
    required this.repeatLabel,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: themeProvider.textSecondary,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${_formatTime(time)} - $repeatLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 2, bottom: 8),
      child: _InlineLabel(label),
    );
  }
}

class _InlineLabel extends StatelessWidget {
  final String label;

  const _InlineLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: themeProvider.textSecondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: themeProvider.borderColor.withValues(alpha: 0.35),
        ),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        style: TextStyle(
          color: themeProvider.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Routine name',
          hintStyle: TextStyle(color: themeProvider.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final List<_RoutineIconOption> icons;
  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData> onSelected;

  const _IconGrid({
    required this.icons,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: icons.map((option) {
        final selected = option.icon.codePoint == selectedIcon.codePoint;
        return _IconButton(
          icon: option.icon,
          selected: selected,
          color: selectedColor,
          onTap: () => onSelected(option.icon),
        );
      }).toList(),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : themeProvider.borderColor.withValues(alpha: 0.35),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: selected ? Colors.white : themeProvider.textSecondary,
          size: 19,
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  const _ColorPicker({
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Row(
      children: colors.map((color) {
        final selected = color.toARGB32() == selectedColor.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(color),
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: themeProvider.cardColor,
                width: selected ? 4 : 2,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: color.withValues(alpha: 0.42),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: selected
                ? const Icon(LucideIcons.check, color: Colors.white, size: 15)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeField({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeProvider.borderColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              LucideIcons.clock,
              color: themeProvider.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: List.generate(7, (index) {
        final selected = selectedDays.contains(index);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 5),
            child: GestureDetector(
              onTap: () {
                final next = [...selectedDays];
                if (selected) {
                  next.remove(index);
                } else {
                  next.add(index);
                  next.sort();
                }
                onChanged(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? AppColors.routineTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected
                        ? AppColors.routine
                        : context.watch<ThemeProvider>().borderColor.withValues(
                            alpha: 0.35,
                          ),
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected
                          ? AppColors.routineDeep
                          : context.watch<ThemeProvider>().textTertiary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StepsEditor extends StatelessWidget {
  final List<_EditableRoutineStep> steps;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String? openIconStepId;
  final ValueChanged<_EditableRoutineStep> onIconTap;
  final void Function(_EditableRoutineStep step, int iconCodePoint)
  onIconSelected;
  final void Function(_EditableRoutineStep step, int delta) onDurationChanged;

  const _StepsEditor({
    required this.steps,
    required this.onAdd,
    required this.onRemove,
    required this.openIconStepId,
    required this.onIconTap,
    required this.onIconSelected,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...steps.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StepRow(
              step: entry.value,
              canRemove: steps.length > 1,
              iconPickerOpen: openIconStepId == entry.value.id,
              onIconTap: () => onIconTap(entry.value),
              onIconSelected: (iconCodePoint) =>
                  onIconSelected(entry.value, iconCodePoint),
              onDurationChanged: (delta) =>
                  onDurationChanged(entry.value, delta),
              onRemove: () => onRemove(entry.key),
            ),
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.routineTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, color: AppColors.routineDeep, size: 16),
                SizedBox(width: 7),
                Text(
                  'Add step',
                  style: TextStyle(
                    color: AppColors.routineDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final _EditableRoutineStep step;
  final bool canRemove;
  final bool iconPickerOpen;
  final VoidCallback onIconTap;
  final ValueChanged<int> onIconSelected;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onRemove;

  const _StepRow({
    required this.step,
    required this.canRemove,
    required this.iconPickerOpen,
    required this.onIconTap,
    required this.onIconSelected,
    required this.onDurationChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconPickerOpen
              ? AppColors.routine
              : themeProvider.borderColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onIconTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconPickerOpen
                        ? AppColors.routineDeep
                        : AppColors.routineTint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    _iconForStep(step.iconCodePoint),
                    color: iconPickerOpen
                        ? Colors.white
                        : AppColors.routineDeep,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: step.controller,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Step title',
                    hintStyle: TextStyle(color: themeProvider.textTertiary),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DurationStepper(
                minutes: step.durationMinutes,
                onChanged: onDurationChanged,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: canRemove ? onRemove : null,
                icon: Icon(
                  LucideIcons.x,
                  color: canRemove
                      ? themeProvider.textTertiary
                      : themeProvider.textTertiary.withValues(alpha: 0.25),
                  size: 16,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: iconPickerOpen
                ? _InlineStepIconPicker(
                    key: ValueKey('${step.id}_icons'),
                    selectedIconCodePoint: step.iconCodePoint,
                    onSelected: onIconSelected,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DurationStepper extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _DurationStepper({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: themeProvider.borderColor.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: LucideIcons.minus,
            enabled: minutes > 1,
            onTap: () => onChanged(-1),
          ),
          SizedBox(
            width: 34,
            child: Text.rich(
              TextSpan(
                text: '$minutes',
                children: const [
                  TextSpan(
                    text: 'm',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _StepperButton(
            icon: LucideIcons.plus,
            enabled: minutes < 60,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1 : 0.3,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, color: AppColors.routineDeep, size: 13),
        ),
      ),
    );
  }
}

class _InlineStepIconPicker extends StatelessWidget {
  final int? selectedIconCodePoint;
  final ValueChanged<int> onSelected;

  const _InlineStepIconPicker({
    super.key,
    required this.selectedIconCodePoint,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: themeProvider.borderColor.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: _stepIconOptions.length,
        itemBuilder: (context, index) {
          final icon = _stepIconOptions[index].icon;
          final selected = selectedIconCodePoint == icon.codePoint;
          return GestureDetector(
            onTap: () => onSelected(icon.codePoint),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.routineDeep
                    : themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : themeProvider.borderColor.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : themeProvider.textSecondary,
                size: 17,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final int minutesBefore;
  final ValueChanged<int> onMinutesChanged;

  const _ReminderCard({
    required this.enabled,
    required this.onChanged,
    required this.minutesBefore,
    required this.onMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return ElevatedCard(
      padding: const EdgeInsets.all(13),
      borderRadius: 18,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.routineTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.bell,
                  color: AppColors.routineDeep,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Remind me',
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeColor: AppColors.routineDeep,
                onChanged: onChanged,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [0, 5, 10, 15, 30].map((minutes) {
                  final selected = minutes == minutesBefore;
                  return ChoiceChip(
                    label: Text(
                      minutes == 0 ? 'At time' : '$minutes min before',
                    ),
                    selected: selected,
                    onSelected: (_) => onMinutesChanged(minutes),
                    selectedColor: AppColors.routineTint,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.routineDeep
                          : themeProvider.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableRoutineStep {
  final String id;
  final TextEditingController controller;
  int? iconCodePoint;
  int durationMinutes;

  _EditableRoutineStep({
    required this.id,
    required this.controller,
    this.iconCodePoint,
    required this.durationMinutes,
  });
}

class _RoutineIconOption {
  final IconData icon;
  final String name;

  const _RoutineIconOption(this.icon, this.name);
}

const List<_RoutineIconOption> _stepIconOptions = [
  _RoutineIconOption(LucideIcons.sun, 'sun'),
  _RoutineIconOption(LucideIcons.coffee, 'coffee'),
  _RoutineIconOption(LucideIcons.moon, 'moon'),
  _RoutineIconOption(LucideIcons.droplet, 'water'),
  _RoutineIconOption(LucideIcons.heart, 'heart'),
  _RoutineIconOption(LucideIcons.leaf, 'leaf'),
  _RoutineIconOption(LucideIcons.target, 'target'),
  _RoutineIconOption(LucideIcons.lightbulb, 'idea'),
  _RoutineIconOption(LucideIcons.flame, 'streak'),
  _RoutineIconOption(LucideIcons.clipboardList, 'list'),
];

IconData _iconForStep(int? iconCodePoint) {
  if (iconCodePoint == null) return LucideIcons.circleCheck;
  return RoutineIcons.getIconFromCodePoint(iconCodePoint) ??
      LucideIcons.circleCheck;
}
