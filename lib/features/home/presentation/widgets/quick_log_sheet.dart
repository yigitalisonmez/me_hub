import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../mood_tracker/presentation/providers/mood_provider.dart';
import '../../../mood_tracker/presentation/utils/mood_utils.dart';
import '../../../todo/domain/entities/daily_todo.dart';
import '../../../todo/presentation/providers/todo_provider.dart';
import '../../../water/presentation/providers/water_provider.dart';

/// Opens the quick-log bottom sheet from the Home screen's + button.
/// Mirrors the redesign board's QuickLogScreen sheet: water stepper, mood
/// picker, first open tasks, and a single "Log everything" action.
Future<void> showQuickLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<WaterProvider>()),
        ChangeNotifierProvider.value(value: context.read<MoodProvider>()),
        ChangeNotifierProvider.value(value: context.read<TodoProvider>()),
      ],
      child: const _QuickLogSheet(),
    ),
  );
}

class _QuickLogSheet extends StatefulWidget {
  const _QuickLogSheet();

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  static const int _glassMl = 250;

  /// Quick log can only add glasses, so the stepper floor is today's count.
  late int _initialGlasses;
  late int _glasses;
  int? _moodIndex; // 0..4 → scores 2,4,6,8,10
  late List<DailyTodo> _tasks;
  late Set<String> _initiallyDone;
  late Set<String> _done;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final water = context.read<WaterProvider>();
    _initialGlasses = water.todayAmount ~/ _glassMl;
    _glasses = _initialGlasses;

    final moodScore = context.read<MoodProvider>().todayMood?.score;
    _moodIndex = moodScore == null ? null : ((moodScore - 1) ~/ 2).clamp(0, 4);

    final todos = context.read<TodoProvider>().todos;
    _tasks = todos.take(3).toList();
    _initiallyDone = _tasks
        .where((t) => t.isCompleted)
        .map((t) => t.id)
        .toSet();
    _done = {..._initiallyDone};
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);

    final water = context.read<WaterProvider>();
    final mood = context.read<MoodProvider>();
    final todo = context.read<TodoProvider>();

    try {
      final addedGlasses = _glasses - _initialGlasses;
      if (addedGlasses > 0) {
        await water.addWaterAmount(addedGlasses * _glassMl);
      }

      final previousIndex = mood.todayMood?.score == null
          ? null
          : ((mood.todayMood!.score - 1) ~/ 2).clamp(0, 4);
      if (_moodIndex != null && _moodIndex != previousIndex) {
        await mood.saveMood(score: _moodIndex! * 2 + 2);
      }

      for (final task in _tasks) {
        final wasDone = _initiallyDone.contains(task.id);
        final isDone = _done.contains(task.id);
        if (wasDone != isDone) {
          await todo.toggleTodoCompletion(task.id);
        }
      }
    } catch (_) {
      // Individual providers surface their own errors; keep the sheet calm.
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quick log',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 15,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _waterRow(theme),
          _divider(theme),
          _moodRow(theme),
          if (_tasks.isNotEmpty) ...[
            _divider(theme),
            for (final task in _tasks) _taskRow(theme, task),
          ],
          const SizedBox(height: 16),
          _saveButton(theme),
        ],
      ),
    );
  }

  Widget _divider(ThemeProvider theme) => Divider(
    height: 20,
    thickness: 1,
    color: theme.textTertiary.withValues(alpha: 0.14),
  );

  Widget _iconBadge(IconData icon, Color color, Color tint) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: 20),
  );

  Widget _rowText(ThemeProvider theme, String title, String sub) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _waterRow(ThemeProvider theme) {
    Widget stepButton(IconData icon, VoidCallback? onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(color: theme.textTertiary.withValues(alpha: 0.25)),
        ),
        child: Icon(
          icon,
          size: 15,
          color: onTap == null ? theme.textTertiary : theme.textPrimary,
        ),
      ),
    );

    return Row(
      children: [
        _iconBadge(
          LucideIcons.droplet,
          AppColors.waterDeep,
          AppColors.waterTint,
        ),
        const SizedBox(width: 12),
        _rowText(theme, 'Water', 'glasses today'),
        stepButton(
          LucideIcons.minus,
          _glasses > _initialGlasses ? () => setState(() => _glasses--) : null,
        ),
        SizedBox(
          width: 34,
          child: Center(
            child: Text(
              '$_glasses',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        stepButton(
          LucideIcons.plus,
          _glasses < 20 ? () => setState(() => _glasses++) : null,
        ),
      ],
    );
  }

  Widget _moodRow(ThemeProvider theme) {
    return Row(
      children: [
        _iconBadge(LucideIcons.smile, AppColors.moodDeep, AppColors.moodTint),
        const SizedBox(width: 12),
        _rowText(theme, 'Mood', 'how do you feel?'),
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: GestureDetector(
              onTap: () => setState(() => _moodIndex = i),
              child: Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: _moodIndex == i
                      ? MoodUtils.getColorForScore(i * 2 + 2)
                      : theme.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _moodIndex == i
                        ? Colors.transparent
                        : theme.textTertiary.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  MoodUtils.getIconForScore(i * 2 + 2),
                  size: 16,
                  color: _moodIndex == i ? Colors.white : theme.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _taskRow(ThemeProvider theme, DailyTodo task) {
    final isDone = _done.contains(task.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          isDone ? _done.remove(task.id) : _done.add(task.id);
        }),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? AppColors.routineDeep : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone
                      ? AppColors.routineDeep
                      : theme.textTertiary.withValues(alpha: 0.45),
                  width: 1.6,
                ),
              ),
              child: isDone
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: isDone ? 0.55 : 1),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton(ThemeProvider theme) {
    return FilledButton(
      onPressed: _save,
      style: FilledButton.styleFrom(
        backgroundColor: _saved ? AppColors.routineDeep : AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_saved) ...[
                  const Icon(LucideIcons.check, size: 17),
                  const SizedBox(width: 7),
                ],
                Text(
                  _saved ? 'Saved' : 'Log everything',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
    );
  }
}
