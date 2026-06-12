import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../core/widgets/celebration_dialog.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_item.dart';
import '../models/gratitude_day_summary.dart';
import '../providers/gratitude_provider.dart';
import 'gratitude_entry_page.dart';

class GratitudePage extends StatefulWidget {
  final String? sourceRoutineName;
  final int? sourceRoutineStep;

  const GratitudePage({
    super.key,
    this.sourceRoutineName,
    this.sourceRoutineStep,
  });

  @override
  State<GratitudePage> createState() => _GratitudePageState();
}

class _GratitudePageState extends State<GratitudePage> {
  final _controllers = List.generate(3, (_) => TextEditingController());
  final _focusNodes = List.generate(3, (_) => FocusNode());
  EntryType _selectedEntryType = EntryType.morning;
  String? _boundEntrySignature;
  bool _isSaving = false;
  int? _gardenSignature;
  List<GratitudeDaySummary> _gardenCache = const [];

  int get _filledCount => _controllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  @override
  void initState() {
    super.initState();
    if (DateTime.now().hour >= 17) {
      _selectedEntryType = EntryType.evening;
    }
    for (final controller in _controllers) {
      controller.addListener(_onFormChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GratitudeProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_onFormChanged)
        ..dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<GratitudeProvider>();
    final todayEntry = _entryForType(provider, _selectedEntryType);
    final garden = _gardenFor(provider.entries);
    _queueEntryHydration(todayEntry);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              PageHeader(
                title: 'Gratitude',
                subtitle: 'Notice what is already good',
                showBackButton: true,
                actionIcon: LucideIcons.bookmark,
                onActionTap: () => _showStatsSheet(provider),
              ),
              if (widget.sourceRoutineName != null &&
                  widget.sourceRoutineStep != null) ...[
                const SizedBox(height: 14),
                _RoutineContextChip(
                  routineName: widget.sourceRoutineName!,
                  step: widget.sourceRoutineStep!,
                ),
              ],
              const SizedBox(height: 20),
              _GratitudeHero(
                streak: provider.currentStreak,
                completed: _filledCount,
              ),
              const SizedBox(height: 16),
              _EntryTypeSelector(
                selectedType: _selectedEntryType,
                onChanged: (type) {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _selectedEntryType = type;
                    _boundEntrySignature = null;
                  });
                },
              ),
              const SizedBox(height: 22),
              _WritingSectionHeader(onRefresh: provider.refreshPrompt),
              const SizedBox(height: 12),
              _GratitudeInputCard(
                icon: LucideIcons.heart,
                label: 'Someone',
                hint: provider.currentPrompt.content,
                controller: _controllers[0],
                focusNode: _focusNodes[0],
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _focusNodes[1].requestFocus(),
              ),
              const SizedBox(height: 11),
              _GratitudeInputCard(
                icon: LucideIcons.sun,
                label: 'A moment',
                hint: 'A small moment that felt good...',
                controller: _controllers[1],
                focusNode: _focusNodes[1],
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _focusNodes[2].requestFocus(),
              ),
              const SizedBox(height: 11),
              _GratitudeInputCard(
                icon: LucideIcons.sparkles,
                label: 'Yourself',
                hint: 'Something you appreciate about yourself...',
                controller: _controllers[2],
                focusNode: _focusNodes[2],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_filledCount == 3) {
                    _saveEntry(provider, todayEntry);
                  }
                },
              ),
              const SizedBox(height: 14),
              _SaveEntryButton(
                count: _filledCount,
                isSaving: _isSaving,
                isEditing: todayEntry != null,
                onPressed: _filledCount == 3 && !_isSaving
                    ? () => _saveEntry(provider, todayEntry)
                    : null,
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    AppRoute(
                      page: GratitudeEntryPage(entryType: _selectedEntryType),
                    ),
                  ),
                  icon: const Icon(LucideIcons.feather, size: 15),
                  label: const Text('Open guided journal'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.textSecondary,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _GardenSection(garden: garden, onDayTap: _showDaySheet),
              const SizedBox(height: 22),
              _RecentBlooms(garden: garden, onDayTap: _showDaySheet),
              SizedBox(height: LayoutConstants.getNavbarClearance(context)),
            ],
          ),
        ),
      ),
    );
  }

  GratitudeEntry? _entryForType(
    GratitudeProvider provider,
    EntryType entryType,
  ) {
    return entryType == EntryType.morning
        ? provider.todayMorningEntry
        : provider.todayEveningEntry;
  }

  List<GratitudeDaySummary> _gardenFor(List<GratitudeEntry> entries) {
    final signature = Object.hashAll(
      entries.map(
        (entry) => Object.hash(
          entry.id,
          entry.dateTimestamp,
          Object.hashAll(entry.items.map((item) => item.content)),
        ),
      ),
    );
    if (signature == _gardenSignature) return _gardenCache;
    _gardenSignature = signature;
    _gardenCache = buildGratitudeGarden(entries);
    return _gardenCache;
  }

  void _queueEntryHydration(GratitudeEntry? entry) {
    final contents = entry?.items.map((item) => item.content).join('|') ?? '';
    final signature =
        '${_selectedEntryType.name}:${entry?.id ?? 'new'}:$contents';
    if (_boundEntrySignature == signature) return;
    _boundEntrySignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _boundEntrySignature != signature) return;
      for (var index = 0; index < _controllers.length; index++) {
        final value = index < (entry?.items.length ?? 0)
            ? entry!.items[index].content
            : '';
        if (_controllers[index].text != value) {
          _controllers[index].text = value;
        }
      }
    });
  }

  Future<void> _saveEntry(
    GratitudeProvider provider,
    GratitudeEntry? existingEntry,
  ) async {
    final values = _controllers
        .map((controller) => controller.text.trim())
        .toList();
    final firstEmpty = values.indexWhere((value) => value.isEmpty);
    if (firstEmpty != -1) {
      _focusNodes[firstEmpty].requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    final previousStreak = provider.currentStreak;
    setState(() => _isSaving = true);

    final items = List.generate(3, (index) {
      if (existingEntry != null && index < existingEntry.items.length) {
        return existingEntry.items[index].copyWith(content: values[index]);
      }
      return GratitudeItem.create(content: values[index]);
    });

    final saved = existingEntry == null
        ? await provider.addEntry(items: items, entryType: _selectedEntryType)
        : await provider.updateEntry(existingEntry.copyWith(items: items));

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not save your entry'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    final currentStreak = provider.currentStreak;
    await showCelebrationDialog(
      context: context,
      icon: LucideIcons.leaf,
      color: AppColors.routineDeep,
      eyebrow: existingEntry == null ? 'GARDEN GROWTH' : 'ENTRY UPDATED',
      title: existingEntry == null
          ? 'Added to your garden'
          : 'Your garden is refreshed',
      message: existingEntry == null
          ? 'You noticed three good things and gave today a place to grow.'
          : "Today's reflection has been gently updated.",
      actionLabel: 'Back to my garden',
      metric: currentStreak != previousStreak
          ? CelebrationMetric(
              before: '$previousStreak',
              after: '$currentStreak',
              label: 'day streak',
            )
          : null,
    );
  }

  void _showDaySheet(GratitudeDaySummary summary) {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d').format(summary.date),
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summary.isComplete
                                ? 'A full day in your garden'
                                : 'A small beginning',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CountBadge(count: summary.progressCount),
                  ],
                ),
                const SizedBox(height: 18),
                for (final entry in summary.entries) ...[
                  _DayEntryBlock(entry: entry),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.routineDeep,
                      side: BorderSide(
                        color: AppColors.routine.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatsSheet(GratitudeProvider provider) {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 20),
                Text(
                  'Your gratitude practice',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _SheetStat(
                  icon: LucideIcons.flame,
                  label: 'Current streak',
                  value: '${provider.currentStreak} days',
                  color: AppColors.moodDeep,
                ),
                _SheetStat(
                  icon: LucideIcons.bookOpen,
                  label: 'Total entries',
                  value: '${provider.totalEntriesCount}',
                  color: AppColors.routineDeep,
                ),
                if (provider.topEmotionTag != null)
                  _SheetStat(
                    icon: LucideIcons.heart,
                    label: 'Top feeling',
                    value: provider.topEmotionTag!,
                    color: AppColors.waterDeep,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoutineContextChip extends StatelessWidget {
  final String routineName;
  final int step;

  const _RoutineContextChip({required this.routineName, required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.mindfulTint.withValues(
          alpha: theme.isDarkMode ? 0.12 : 1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.moon, color: AppColors.mindfulDeep, size: 15),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$routineName · step $step',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.mindfulDeep,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GratitudeHero extends StatelessWidget {
  final int streak;
  final int completed;

  const _GratitudeHero({required this.streak, required this.completed});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(20, 19, 16, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF829D72), Color(0xFF4E6847)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.routineDeep.withValues(alpha: 0.30),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -26,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            right: -2,
            top: 18,
            child: Image.asset(
              'assets/images/gratitude_2.png',
              width: 126,
              height: 126,
              fit: BoxFit.contain,
            ),
          ),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  today.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 210,
                  child: Text(
                    'Three good\nthings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _HeroBadge(
                      icon: LucideIcons.flame,
                      label: '$streak day streak',
                    ),
                    const SizedBox(width: 8),
                    _HeroBadge(
                      icon: LucideIcons.leaf,
                      label: '$completed/3 today',
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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTypeSelector extends StatelessWidget {
  final EntryType selectedType;
  final ValueChanged<EntryType> onChanged;

  const _EntryTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              icon: LucideIcons.sun,
              label: 'Morning',
              selected: selectedType == EntryType.morning,
              onTap: () => onChanged(EntryType.morning),
            ),
          ),
          Expanded(
            child: _TypeButton(
              icon: LucideIcons.moon,
              label: 'Evening',
              selected: selectedType == EntryType.evening,
              onTap: () => onChanged(EntryType.evening),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected && !theme.isDarkMode
              ? [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.routineDeep : theme.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? theme.textPrimary : theme.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WritingSectionHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _WritingSectionHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's good today?",
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Short and honest is enough.',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'New prompt',
          onPressed: onRefresh,
          icon: Icon(
            LucideIcons.refreshCw,
            color: theme.textSecondary,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _GratitudeInputCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;

  const _GratitudeInputCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.textInputAction,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final filled = controller.text.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 11),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: filled
              ? AppColors.routine.withValues(alpha: 0.65)
              : theme.borderColor.withValues(alpha: 0.34),
          width: filled ? 1.3 : 1,
        ),
        boxShadow: !theme.isDarkMode
            ? [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.routineDeep
                  : AppColors.routineTint.withValues(
                      alpha: theme.isDarkMode ? 0.12 : 1,
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                filled ? LucideIcons.check : icon,
                key: ValueKey(filled),
                color: filled ? Colors.white : AppColors.routineDeep,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.routineDeep,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.05,
                  ),
                ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: textInputAction,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 180,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintMaxLines: 2,
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 5, bottom: 2),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: theme.textTertiary,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveEntryButton extends StatelessWidget {
  final int count;
  final bool isSaving;
  final bool isEditing;
  final VoidCallback? onPressed;

  const _SaveEntryButton({
    required this.count,
    required this.isSaving,
    required this.isEditing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.leaf, size: 17),
        label: Text(
          isSaving
              ? 'Saving...'
              : '${isEditing ? 'Update' : 'Save'} · $count/3',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.routineDeep,
          disabledBackgroundColor: AppColors.routine.withValues(alpha: 0.32),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.78),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _GardenSection extends StatelessWidget {
  final List<GratitudeDaySummary> garden;
  final ValueChanged<GratitudeDaySummary> onDayTap;

  const _GardenSection({required this.garden, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your garden',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'The last 14 days of noticing.',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.leaf,
              color: AppColors.routineDeep,
              size: 21,
            ),
          ],
        ),
        const SizedBox(height: 13),
        ElevatedCard(
          padding: const EdgeInsets.all(13),
          borderRadius: 23,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemCount: garden.length,
            itemBuilder: (context, index) {
              final day = garden[index];
              return _GardenDay(
                summary: day,
                onTap: day.progressCount > 0 ? () => onDayTap(day) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GardenDay extends StatelessWidget {
  final GratitudeDaySummary summary;
  final VoidCallback? onTap;

  const _GardenDay({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final today = DateTime.now();
    final isToday =
        summary.date.year == today.year &&
        summary.date.month == today.month &&
        summary.date.day == today.day;
    final color = summary.isComplete
        ? AppColors.routineDeep
        : summary.progressCount > 0
        ? AppColors.routine.withValues(alpha: 0.62)
        : theme.surfaceColor;

    return Semantics(
      button: onTap != null,
      label:
          '${DateFormat('MMMM d').format(summary.date)}, ${summary.progressCount} of 3 gratitude notes',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isToday
                    ? AppColors.routineDeep
                    : theme.borderColor.withValues(alpha: 0.25),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: summary.isComplete
                  ? const Icon(LucideIcons.leaf, color: Colors.white, size: 15)
                  : Text(
                      summary.progressCount > 0
                          ? '${summary.progressCount}'
                          : '${summary.date.day}',
                      style: TextStyle(
                        color: summary.progressCount > 0
                            ? Colors.white
                            : theme.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentBlooms extends StatelessWidget {
  final List<GratitudeDaySummary> garden;
  final ValueChanged<GratitudeDaySummary> onDayTap;

  const _RecentBlooms({required this.garden, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final recent = garden
        .where((day) => day.progressCount > 0)
        .toList()
        .reversed
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent blooms',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 11),
        if (recent.isEmpty)
          ElevatedCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Row(
              children: [
                const Icon(LucideIcons.leaf, color: AppColors.routineDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your saved reflections will begin growing here.',
                    style: TextStyle(
                      color: theme.textSecondary,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final day in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedCard(
                padding: const EdgeInsets.all(15),
                borderRadius: 19,
                onTap: () => onDayTap(day),
                child: Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: AppColors.routineTint.withValues(
                          alpha: theme.isDarkMode ? 0.13 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.leaf,
                        color: AppColors.routineDeep,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(day.date),
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.items.first.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CountBadge(count: day.progressCount),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.routineTint.withValues(
          alpha: context.watch<ThemeProvider>().isDarkMode ? 0.14 : 1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count/3',
        style: const TextStyle(
          color: AppColors.routineDeep,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DayEntryBlock extends StatelessWidget {
  final GratitudeEntry entry;

  const _DayEntryBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                entry.entryType == EntryType.morning
                    ? LucideIcons.sun
                    : LucideIcons.moon,
                color: AppColors.routineDeep,
                size: 15,
              ),
              const SizedBox(width: 7),
              Text(
                entry.entryType == EntryType.morning ? 'Morning' : 'Evening',
                style: const TextStyle(
                  color: AppColors.routineDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          for (var index = 0; index < entry.items.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == entry.items.length - 1 ? 0 : 9,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.routine,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      entry.items[index].content,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.textSecondary.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SheetStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
