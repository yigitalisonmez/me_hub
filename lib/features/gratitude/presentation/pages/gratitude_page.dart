import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../providers/gratitude_provider.dart';
import 'gratitude_entry_page.dart';

class GratitudePage extends StatefulWidget {
  const GratitudePage({super.key});

  @override
  State<GratitudePage> createState() => _GratitudePageState();
}

class _GratitudePageState extends State<GratitudePage> {
  EntryType _selectedEntryType = EntryType.morning;

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour >= 17) _selectedEntryType = EntryType.evening;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GratitudeProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<GratitudeProvider>();
    final todayEntry = _selectedEntryType == EntryType.morning
        ? provider.todayMorningEntry
        : provider.todayEveningEntry;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              PageHeader(
                title: 'Gratitude',
                subtitle: 'Three good things',
                showBackButton: true,
                actionIcon: LucideIcons.bookmark,
                onActionTap: () => _showStatsSheet(context, provider),
              ),
              const SizedBox(height: 22),
              const _GratitudeHero(),
              const SizedBox(height: 16),
              _EntryTypeSelector(
                selectedType: _selectedEntryType,
                onChanged: (type) => setState(() => _selectedEntryType = type),
              ),
              const SizedBox(height: 16),
              _StatsStrip(
                streak: provider.currentStreak,
                entries: provider.totalEntriesCount,
                topEmotion: provider.topEmotionTag,
              ),
              const SizedBox(height: 18),
              _ThreeThingsCard(
                entry: todayEntry,
                prompt: provider.currentPrompt.content,
                onRefreshPrompt: provider.refreshPrompt,
                onStart: () => _navigateToEntry(context),
              ),
              const SizedBox(height: 24),
              _LookingBack(
                entries: provider.entries,
                randomEntry: provider.randomPastEntry,
                onRefresh: provider.refreshRandomPastEntry,
              ),
              SizedBox(height: LayoutConstants.getNavbarClearance(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEntry(BuildContext context) {
    Navigator.of(context).push(
      AppRoute(page: GratitudeEntryPage(entryType: _selectedEntryType)),
    );
  }

  void _showStatsSheet(BuildContext context, GratitudeProvider provider) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: themeProvider.textSecondary.withValues(
                        alpha: 0.25,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Statistics',
                  style: TextStyle(
                    color: themeProvider.textPrimary,
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

class _GratitudeHero extends StatelessWidget {
  const _GratitudeHero();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.routineTint,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.routine.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/gratitude_2.png',
            width: 78,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Three good things',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A minute of noticing what went well.',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? AppColors.textSecondary
                        : AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _EntryTypeSelector extends StatelessWidget {
  final EntryType selectedType;
  final ValueChanged<EntryType> onChanged;

  const _EntryTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            icon: LucideIcons.sun,
            label: 'Morning',
            selected: selectedType == EntryType.morning,
            onTap: () => onChanged(EntryType.morning),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TypeButton(
            icon: LucideIcons.moon,
            label: 'Evening',
            selected: selectedType == EntryType.evening,
            onTap: () => onChanged(EntryType.evening),
          ),
        ),
      ],
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
    final themeProvider = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.routineDeep : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.routineDeep
                : themeProvider.borderColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : themeProvider.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : themeProvider.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final int streak;
  final int entries;
  final String? topEmotion;

  const _StatsStrip({
    required this.streak,
    required this.entries,
    required this.topEmotion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStat(
          icon: LucideIcons.flame,
          value: '$streak',
          label: 'streak',
          color: AppColors.moodDeep,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          icon: LucideIcons.bookOpen,
          value: '$entries',
          label: 'entries',
          color: AppColors.routineDeep,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          icon: LucideIcons.heart,
          value: topEmotion ?? '-',
          label: 'feeling',
          color: AppColors.waterDeep,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Expanded(
      child: ElevatedCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        borderRadius: 17,
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeThingsCard extends StatelessWidget {
  final GratitudeEntry? entry;
  final String prompt;
  final VoidCallback onRefreshPrompt;
  final VoidCallback onStart;

  const _ThreeThingsCard({
    required this.entry,
    required this.prompt,
    required this.onRefreshPrompt,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final items = entry?.items ?? const [];
    final prompts = [
      prompt,
      'A small moment you enjoyed...',
      'Something about yourself...',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's entry",
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onRefreshPrompt,
              icon: Icon(
                LucideIcons.refreshCw,
                color: themeProvider.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(3, (index) {
          final filled = index < items.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GratitudeLine(
              number: index + 1,
              text: filled ? items[index].content : prompts[index],
              filled: filled,
              onTap: onStart,
            ),
          );
        }),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(
              LucideIcons.feather,
              color: Colors.white,
              size: 17,
            ),
            label: Text(
              entry?.isComplete == true
                  ? 'Edit today\'s entry'
                  : 'Save today\'s entry',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.routineDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GratitudeLine extends StatelessWidget {
  final int number;
  final String text;
  final bool filled;
  final VoidCallback onTap;

  const _GratitudeLine({
    required this.number,
    required this.text,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return ElevatedCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      borderColor: filled
          ? AppColors.routine.withValues(alpha: 0.55)
          : themeProvider.borderColor.withValues(alpha: 0.35),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: filled ? AppColors.routine : AppColors.routineTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: filled ? Colors.white : AppColors.routineDeep,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: filled
                    ? themeProvider.textPrimary
                    : themeProvider.textTertiary,
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (filled)
            const Icon(
              LucideIcons.check,
              color: AppColors.routineDeep,
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _LookingBack extends StatelessWidget {
  final List<GratitudeEntry> entries;
  final GratitudeEntry? randomEntry;
  final Future<void> Function() onRefresh;

  const _LookingBack({
    required this.entries,
    required this.randomEntry,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final recent = entries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Looking back',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${entries.length} days',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (randomEntry != null) ...[
          _MemoryCard(
            entry: randomEntry!,
            highlighted: true,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: 10),
        ],
        if (recent.isEmpty)
          ElevatedCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Text(
              'Your saved gratitude notes will gather here.',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...recent.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemoryCard(entry: entry),
            ),
          ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final GratitudeEntry entry;
  final bool highlighted;
  final Future<void> Function()? onRefresh;

  const _MemoryCard({
    required this.entry,
    this.highlighted = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: highlighted
          ? AppColors.routineTint.withValues(
              alpha: themeProvider.isDarkMode ? 0.10 : 1,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                highlighted ? LucideIcons.sparkles : LucideIcons.leaf,
                color: AppColors.routineDeep,
                size: 15,
              ),
              const SizedBox(width: 7),
              Text(
                highlighted
                    ? 'Memory from ${_formatDate(entry.date)}'
                    : _formatDate(entry.date),
                style: const TextStyle(
                  color: AppColors.routineDeep,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (highlighted && onRefresh != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onRefresh,
                  icon: Icon(
                    LucideIcons.refreshCw,
                    color: themeProvider.textSecondary,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...entry.items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7),
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
                          item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: themeProvider.textPrimary,
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    const months = [
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
    return '${months[date.month - 1]} ${date.day}';
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
    final themeProvider = context.watch<ThemeProvider>();
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
                color: themeProvider.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
