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
import '../utils/routine_dialogs.dart';

class EditRoutinePage extends StatefulWidget {
  final Routine routine;

  const EditRoutinePage({super.key, required this.routine});

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  static const List<_RoutineIconOption> _baseIconOptions = [
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
    _RoutineIconOption(LucideIcons.showerHead, 'wash'),
    _RoutineIconOption(LucideIcons.bed, 'sleep'),
    _RoutineIconOption(LucideIcons.brush, 'brush'),
    _RoutineIconOption(LucideIcons.bookOpen, 'read'),
    _RoutineIconOption(LucideIcons.dumbbell, 'fitness'),
  ];

  late final TextEditingController _nameController;
  final List<_EditableRoutineStep> _steps = [];
  late int _selectedIconCodePoint;
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late bool _remindMe;
  late int _reminderMinutesBefore;
  String? _openIconStepId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name)
      ..addListener(_refreshPreview);
    _selectedIconCodePoint =
        widget.routine.iconCodePoint ?? LucideIcons.clipboardList.codePoint;
    _selectedTime = widget.routine.time ?? const TimeOfDay(hour: 8, minute: 0);
    _selectedDays = _normalizeDays(widget.routine.selectedDays);
    _remindMe = widget.routine.reminderEnabled;
    _reminderMinutesBefore = widget.routine.reminderMinutesBefore;

    final items = widget.routine.items;
    if (items.isEmpty) {
      _steps.add(_EditableRoutineStep.newStep(onChanged: _refreshPreview));
    } else {
      _steps.addAll(
        items.map(
          (item) =>
              _EditableRoutineStep.fromItem(item, onChanged: _refreshPreview),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refreshPreview)
      ..dispose();
    for (final step in _steps) {
      step.dispose(_refreshPreview);
    }
    super.dispose();
  }

  List<int> _normalizeDays(List<int>? days) {
    if (days == null || days.isEmpty) {
      return List<int>.generate(7, (index) => index);
    }

    final normalized =
        days.where((day) => day >= 0 && day <= 6).toSet().toList()..sort();
    return normalized.isEmpty
        ? List<int>.generate(7, (index) => index)
        : normalized;
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
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditTopBar(
                onBack: () => Navigator.of(context).pop(),
                onDelete: _deleteRoutine,
              ),
              const SizedBox(height: 20),
              _LivePreview(
                name: _routineName,
                icon: _selectedIcon,
                time: _selectedTime,
                repeatLabel: _repeatLabel,
                stepCount: _filledStepCount,
                streakCount: widget.routine.streakCount,
              ),
              const _FieldLabel('Name'),
              _NameField(controller: _nameController),
              const _FieldLabel('Icon'),
              _IconGrid(
                icons: _iconOptions,
                selectedCodePoint: _selectedIconCodePoint,
                onSelected: (icon) {
                  setState(() => _selectedIconCodePoint = icon.codePoint);
                },
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
                          onChanged: (days) =>
                              setState(() => _selectedDays = days),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _EditReminderCard(
                enabled: _remindMe,
                minutesBefore: _reminderMinutesBefore,
                onEnabledChanged: _setReminderEnabled,
                onMinutesChanged: (value) =>
                    setState(() => _reminderMinutesBefore = value),
              ),
              const _FieldLabel('Steps'),
              _StepsEditor(
                steps: _steps,
                openIconStepId: _openIconStepId,
                onIconTap: _toggleStepIconPicker,
                onIconSelected: _selectStepIcon,
                onDurationChanged: _changeStepDuration,
                onAdd: _addStep,
                onRemove: _removeStep,
              ),
              const SizedBox(height: 14),
              const _GuidedFlowHint(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SaveBar(isSaving: _isSaving, onSave: _saveRoutine),
    );
  }

  String get _routineName {
    final value = _nameController.text.trim();
    return value.isEmpty ? 'Routine' : value;
  }

  IconData get _selectedIcon {
    for (final option in _iconOptions) {
      if (option.icon.codePoint == _selectedIconCodePoint) {
        return option.icon;
      }
    }
    return RoutineIcons.getIconFromCodePoint(_selectedIconCodePoint) ??
        LucideIcons.clipboardList;
  }

  List<_RoutineIconOption> get _iconOptions {
    final options = List<_RoutineIconOption>.from(_baseIconOptions);
    final alreadyIncluded = options.any(
      (option) => option.icon.codePoint == _selectedIconCodePoint,
    );
    final currentIcon = RoutineIcons.getIconFromCodePoint(
      _selectedIconCodePoint,
    );

    if (!alreadyIncluded && currentIcon != null) {
      options.insert(0, _RoutineIconOption(currentIcon, 'current'));
    }

    return options;
  }

  int get _filledStepCount {
    return _steps
        .where((step) => step.controller.text.trim().isNotEmpty)
        .length;
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
    setState(() {
      _steps.add(_EditableRoutineStep.newStep(onChanged: _refreshPreview));
    });
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

  void _removeStep(int index) {
    if (_steps.length == 1) {
      _steps.first.controller.clear();
      return;
    }

    final step = _steps.removeAt(index);
    step.dispose(_refreshPreview);
    setState(() {});
  }

  Future<void> _saveRoutine() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter a routine name', error: true);
      return;
    }

    if (_selectedDays.isEmpty) {
      _showSnack('Please select at least one day', error: true);
      return;
    }

    final items = _steps
        .map((step) => step.toRoutineItem())
        .whereType<RoutineItem>()
        .toList();

    if (items.isEmpty) {
      _showSnack('Please add at least one step', error: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<RoutinesProvider>();
      final currentRoutine =
          provider.getRoutineById(widget.routine.id) ?? widget.routine;
      final updatedRoutine = currentRoutine.copyWith(
        name: name,
        items: items,
        iconCodePoint: _selectedIconCodePoint,
        timeHour: _selectedTime.hour,
        timeMinute: _selectedTime.minute,
        selectedDays: _selectedDays,
        reminderEnabled: _remindMe,
        reminderMinutesBefore: _reminderMinutesBefore,
      );

      await provider.updateRoutine(updatedRoutine);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Error saving routine: $e', error: true);
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

  Future<void> _deleteRoutine() async {
    final provider = context.read<RoutinesProvider>();
    final routine =
        provider.getRoutineById(widget.routine.id) ?? widget.routine;
    final confirmed = await RoutineDialogs.showDeleteRoutine(context, routine);

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
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

class _EditTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const _EditTopBar({required this.onBack, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _TopActionButton(
            icon: LucideIcons.arrowLeft,
            color: themeProvider.textPrimary,
            onTap: onBack,
          ),
        ),
        Text(
          'Edit routine',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _TopActionButton(
            icon: LucideIcons.trash2,
            color: AppColors.error,
            onTap: onDelete,
          ),
        ),
      ],
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  final String name;
  final IconData icon;
  final TimeOfDay time;
  final String repeatLabel;
  final int stepCount;
  final int streakCount;

  const _LivePreview({
    required this.name,
    required this.icon,
    required this.time,
    required this.repeatLabel,
    required this.stepCount,
    required this.streakCount,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themeProvider.isDarkMode
              ? [
                  AppColors.routineDeep.withValues(alpha: 0.72),
                  AppColors.darkSurface,
                ]
              : [AppColors.routineDeep, AppColors.routine],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.routineDeep.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/routine_tracker.png',
                  width: 58,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.routineDeep, size: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${_formatTime(time)} - $repeatLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PreviewPill(
                      icon: LucideIcons.listTodo,
                      label: '$stepCount steps',
                    ),
                    _PreviewPill(
                      icon: LucideIcons.flame,
                      label: '$streakCount streak',
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
}

class _PreviewPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 2, bottom: 8),
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
        letterSpacing: 0,
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
  final int selectedCodePoint;
  final ValueChanged<IconData> onSelected;

  const _IconGrid({
    required this.icons,
    required this.selectedCodePoint,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: icons.map((option) {
        final selected = option.icon.codePoint == selectedCodePoint;
        return _IconChoiceButton(
          icon: option.icon,
          selected: selected,
          onTap: () => onSelected(option.icon),
        );
      }).toList(),
    );
  }
}

class _IconChoiceButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoiceButton({
    required this.icon,
    required this.selected,
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
          color: selected ? AppColors.routineDeep : themeProvider.cardColor,
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
}

class _DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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
                        : themeProvider.borderColor.withValues(alpha: 0.35),
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected
                          ? AppColors.routineDeep
                          : themeProvider.textTertiary,
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
  final String? openIconStepId;
  final ValueChanged<_EditableRoutineStep> onIconTap;
  final void Function(_EditableRoutineStep step, int iconCodePoint)
  onIconSelected;
  final void Function(_EditableRoutineStep step, int delta) onDurationChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _StepsEditor({
    required this.steps,
    required this.openIconStepId,
    required this.onIconTap,
    required this.onIconSelected,
    required this.onDurationChanged,
    required this.onAdd,
    required this.onRemove,
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

class _GuidedFlowHint extends StatelessWidget {
  const _GuidedFlowHint();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.all(13),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.routineTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.route,
              color: AppColors.routineDeep,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Guided flow follows this step order.',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveBar({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: themeProvider.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.routineDeep,
              disabledBackgroundColor: themeProvider.borderColor.withValues(
                alpha: 0.55,
              ),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ),
    );
  }
}

class _EditReminderCard extends StatelessWidget {
  final bool enabled;
  final int minutesBefore;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onMinutesChanged;

  const _EditReminderCard({
    required this.enabled,
    required this.minutesBefore,
    required this.onEnabledChanged,
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
              const Icon(
                LucideIcons.bell,
                color: AppColors.routineDeep,
                size: 19,
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
                onChanged: onEnabledChanged,
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
  final DateTime? lastCheckedDate;
  int? iconCodePoint;
  int durationMinutes;

  _EditableRoutineStep({
    required this.id,
    required this.controller,
    this.lastCheckedDate,
    this.iconCodePoint,
    required this.durationMinutes,
  });

  factory _EditableRoutineStep.fromItem(
    RoutineItem item, {
    required VoidCallback onChanged,
  }) {
    final controller = TextEditingController(text: item.title)
      ..addListener(onChanged);

    return _EditableRoutineStep(
      id: item.id,
      controller: controller,
      lastCheckedDate: item.lastCheckedDate,
      iconCodePoint: item.iconCodePoint,
      durationMinutes:
          item.durationMinutes ?? _estimatedMinutesForTitle(item.title),
    );
  }

  factory _EditableRoutineStep.newStep({required VoidCallback onChanged}) {
    final controller = TextEditingController()..addListener(onChanged);
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return _EditableRoutineStep(
      id: timestamp.toString(),
      controller: controller,
      iconCodePoint: LucideIcons.circleCheck.codePoint,
      durationMinutes: 5,
    );
  }

  RoutineItem? toRoutineItem() {
    final title = controller.text.trim();
    if (title.isEmpty) return null;

    return RoutineItem(
      id: id,
      title: title,
      lastCheckedDate: lastCheckedDate,
      iconCodePoint: iconCodePoint ?? LucideIcons.circleCheck.codePoint,
      durationMinutes: durationMinutes,
    );
  }

  void dispose(VoidCallback listener) {
    controller
      ..removeListener(listener)
      ..dispose();
  }
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

int _estimatedMinutesForTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('walk') || lower.contains('yürüy')) return 15;
  if (lower.contains('read') || lower.contains('oku')) return 10;
  if (lower.contains('stretch') || lower.contains('esne')) return 5;
  if (lower.contains('brush') || lower.contains('diş')) return 2;
  if (lower.contains('bed') || lower.contains('yata')) return 2;
  if (lower.contains('wash') || lower.contains('yıka')) return 1;
  if (lower.contains('water') || lower.contains('su')) return 1;
  return 3;
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
