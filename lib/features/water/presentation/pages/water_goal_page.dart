import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/daily_goal_service.dart';

class WaterGoalPage extends StatefulWidget {
  const WaterGoalPage({super.key});

  @override
  State<WaterGoalPage> createState() => _WaterGoalPageState();
}

class _WaterGoalPageState extends State<WaterGoalPage> {
  static const int _minGoal = 1000;
  static const int _maxGoal = 4000;
  static const int _step = 250;
  static const List<int> _presets = [1500, 2000, 2500, 3000];

  int _goalMl = 2000;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoal());
  }

  Future<void> _loadGoal() async {
    final goal = await DailyGoalService.getDailyGoal();
    if (!mounted) return;
    setState(() {
      _goalMl = goal.clamp(_minGoal, _maxGoal).toInt();
    });
  }

  Future<void> _saveGoal() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await DailyGoalService.setDailyGoal(_goalMl);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _changeGoal(int delta) {
    setState(() {
      _goalMl = (_goalMl + delta).clamp(_minGoal, _maxGoal).toInt();
    });
  }

  void _setGoalFromSlider(double value) {
    setState(() {
      _goalMl = ((value / _step).round() * _step)
          .clamp(_minGoal, _maxGoal)
          .toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalTopBar(onBackTap: () => Navigator.of(context).pop(false)),
              const SizedBox(height: 18),
              Center(
                child: Image.asset(
                  'assets/images/water_glass_check.png',
                  width: 136,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              _GoalStepper(
                goalMl: _goalMl,
                onDecrease: () => _changeGoal(-_step),
                onIncrease: () => _changeGoal(_step),
              ),
              const SizedBox(height: 22),
              _GoalSlider(
                goalMl: _goalMl,
                min: _minGoal,
                max: _maxGoal,
                onChanged: _setGoalFromSlider,
              ),
              const SizedBox(height: 18),
              _GoalPresets(
                presets: _presets,
                selectedGoal: _goalMl,
                onSelected: (goal) => setState(() => _goalMl = goal),
              ),
              const SizedBox(height: 18),
              const _HydrationNote(),
              const SizedBox(height: 16),
              const _ReminderCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: themeProvider.isDarkMode ? 0.24 : 0.08,
              ),
              blurRadius: 22,
              offset: const Offset(0, -10),
              spreadRadius: -14,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveGoal,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.waterDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save goal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalTopBar extends StatelessWidget {
  final VoidCallback onBackTap;

  const _GoalTopBar({required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        _RoundGoalButton(icon: LucideIcons.chevronLeft, onTap: onBackTap),
        Expanded(
          child: Text(
            'Daily goal',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 38),
      ],
    );
  }
}

class _RoundGoalButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundGoalButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      color: themeProvider.cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(icon, size: 20, color: themeProvider.textPrimary),
        ),
      ),
    );
  }
}

class _GoalStepper extends StatelessWidget {
  final int goalMl;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _GoalStepper({
    required this.goalMl,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        _StepButton(icon: LucideIcons.minus, onTap: onDecrease),
        Expanded(
          child: Column(
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  children: [
                    TextSpan(text: _goalLiters(goalMl)),
                    TextSpan(
                      text: 'L',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.waterDeep,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '≈ ${goalMl ~/ 250} glasses · 250 ml each',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: themeProvider.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _StepButton(icon: LucideIcons.plus, onTap: onIncrease, isPrimary: true),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _StepButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      color: isPrimary ? AppColors.water : themeProvider.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : themeProvider.textTertiary.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? AppColors.water.withValues(alpha: 0.24)
                    : Colors.black.withValues(
                        alpha: themeProvider.isDarkMode ? 0.18 : 0.04,
                      ),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : themeProvider.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _GoalSlider extends StatelessWidget {
  final int goalMl;
  final int min;
  final int max;
  final ValueChanged<double> onChanged;

  const _GoalSlider({
    required this.goalMl,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.water,
            inactiveTrackColor: themeProvider.isDarkMode
                ? AppColors.waterTint.withValues(alpha: 0.14)
                : AppColors.waterTint,
            thumbColor: Colors.white,
            overlayColor: AppColors.water.withValues(alpha: 0.16),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          ),
          child: Slider(
            value: goalMl.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: ((max - min) / 250).round(),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_goalLiters(min)} L',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: themeProvider.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_goalLiters((min + max) ~/ 2)} L',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: themeProvider.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_goalLiters(max)} L',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: themeProvider.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalPresets extends StatelessWidget {
  final List<int> presets;
  final int selectedGoal;
  final ValueChanged<int> onSelected;

  const _GoalPresets({
    required this.presets,
    required this.selectedGoal,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: presets.map((preset) {
        final selected = selectedGoal == preset;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: preset == presets.last ? 0 : 9),
            child: Material(
              color: selected
                  ? (themeProvider.isDarkMode
                        ? AppColors.waterTint.withValues(alpha: 0.12)
                        : AppColors.waterTint)
                  : themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onSelected(preset),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.water
                          : themeProvider.textTertiary.withValues(alpha: 0.16),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${_goalLiters(preset)} L',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.waterDeep
                          : themeProvider.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HydrationNote extends StatelessWidget {
  const _HydrationNote();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.waterTint.withValues(alpha: 0.12)
            : AppColors.waterTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              size: 17,
              color: AppColors.waterDeep,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Based on your activity, 2.0-2.5 L keeps you well hydrated.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: const [
          _ReminderRow(
            icon: LucideIcons.bell,
            label: 'Reminders',
            trailing: _ReminderSwitch(),
          ),
          Divider(height: 1),
          _ReminderRow(
            icon: LucideIcons.clock,
            label: 'Every',
            trailing: _ReminderValue(),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _ReminderRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.waterTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: AppColors.waterDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ReminderSwitch extends StatelessWidget {
  const _ReminderSwitch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 26,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.water,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ReminderValue extends StatelessWidget {
  const _ReminderValue();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '2 hours',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: themeProvider.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          LucideIcons.chevronRight,
          size: 15,
          color: themeProvider.textTertiary,
        ),
      ],
    );
  }
}

String _goalLiters(int ml) {
  final liters = ml / 1000;
  return liters.toStringAsFixed(ml % 1000 == 0 ? 0 : 1);
}
