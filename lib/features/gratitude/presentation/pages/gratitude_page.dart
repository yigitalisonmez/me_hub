import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_prompt.dart';
import '../providers/gratitude_provider.dart';
import 'gratitude_entry_page.dart';

/// Main page for the Gratitude Journal feature
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
    // Auto-select entry type based on time of day
    final hour = DateTime.now().hour;
    if (hour >= 17) {
      _selectedEntryType = EntryType.evening;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GratitudeProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<GratitudeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Gradient header - matching app style
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: themeProvider.backgroundColor,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Stats button
              IconButton(
                icon: const Icon(LucideIcons.chartBar, color: Colors.white),
                onPressed: () => _showStatsSheet(context, provider),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Gratitude',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.primaryColor,
                      themeProvider.primaryColor.withValues(alpha: 0.7),
                      themeProvider.backgroundColor,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 40,
                      child: Icon(
                        LucideIcons.heart,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 100,
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    // Stats row
                    _StatsRow(
                      streak: provider.currentStreak,
                      entries: provider.totalEntriesCount,
                      topEmotion: provider.topEmotionTag,
                    ),
                    const SizedBox(height: 24),

                    // Entry type toggle
                    _EntryTypeSelector(
                      selectedType: _selectedEntryType,
                      onTypeChanged: (type) {
                        setState(() => _selectedEntryType = type);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Today's status card
                    _TodayStatusCard(
                      entry: _selectedEntryType == EntryType.morning
                          ? provider.todayMorningEntry
                          : provider.todayEveningEntry,
                      entryType: _selectedEntryType,
                      onStartTap: () => _navigateToEntry(context),
                    ),
                    const SizedBox(height: 24),

                    // Random memory (if exists)
                    if (provider.randomPastEntry != null) ...[
                      _RandomMemoryCard(
                        entry: provider.randomPastEntry!,
                        onRefresh: () => provider.refreshRandomPastEntry(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Daily prompt
                    _PromptCard(
                      prompt: provider.currentPrompt,
                      onRefresh: () => provider.refreshPrompt(),
                      onStart: () => _navigateToEntry(context),
                    ),
                    const SizedBox(height: 24),

                    // Recent entries
                    if (provider.entries.isNotEmpty) ...[
                      Text(
                        'Recent Entries',
                        style: TextStyle(
                          color: themeProvider.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...provider.entries
                          .take(5)
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _EntryCard(entry: entry),
                            ),
                          ),
                    ],

                    const SizedBox(height: 80), // FAB clearance
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEntry(context),
        backgroundColor: themeProvider.primaryColor,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'New Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _navigateToEntry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GratitudeEntryPage(entryType: _selectedEntryType),
      ),
    );
  }

  void _showStatsSheet(BuildContext context, GratitudeProvider provider) {
    final themeProvider = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeProvider.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Statistics',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _StatItem(
              icon: LucideIcons.flame,
              label: 'Current Streak',
              value: '${provider.currentStreak} days',
              color: const Color(0xFFFF7043),
            ),
            const SizedBox(height: 12),
            _StatItem(
              icon: LucideIcons.bookOpen,
              label: 'Total Entries',
              value: '${provider.totalEntriesCount}',
              color: themeProvider.primaryColor,
            ),
            const SizedBox(height: 12),
            if (provider.topEmotionTag != null)
              _StatItem(
                icon: LucideIcons.heart,
                label: 'Top Emotion',
                value: provider.topEmotionTag!,
                color: const Color(0xFF42A5F5),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Stats row matching breathing page
class _StatsRow extends StatelessWidget {
  final int streak;
  final int entries;
  final String? topEmotion;

  const _StatsRow({
    required this.streak,
    required this.entries,
    this.topEmotion,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: LucideIcons.flame,
            value: '$streak',
            label: 'day streak',
            color: const Color(0xFFFF7043),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: LucideIcons.bookOpen,
            value: '$entries',
            label: 'entries',
            color: themeProvider.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: LucideIcons.heart,
            value: topEmotion ?? '-',
            label: 'top feeling',
            color: const Color(0xFF42A5F5),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: 16,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EntryTypeSelector extends StatelessWidget {
  final EntryType selectedType;
  final void Function(EntryType) onTypeChanged;

  const _EntryTypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            icon: LucideIcons.sun,
            label: 'Morning',
            isSelected: selectedType == EntryType.morning,
            onTap: () => onTypeChanged(EntryType.morning),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeButton(
            icon: LucideIcons.moon,
            label: 'Evening',
            isSelected: selectedType == EntryType.evening,
            onTap: () => onTypeChanged(EntryType.evening),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.primaryColor
              : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeProvider.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : themeProvider.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : themeProvider.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  final GratitudeEntry? entry;
  final EntryType entryType;
  final VoidCallback onStartTap;

  const _TodayStatusCard({
    required this.entry,
    required this.entryType,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isComplete = entry != null && entry!.isComplete;

    return ElevatedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Progress circle
          _ProgressCircle(
            current: entry?.items.length ?? 0,
            target: 3,
            color: isComplete
                ? const Color(0xFF4CAF50)
                : themeProvider.primaryColor,
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete
                      ? 'Completed! 🎉'
                      : entryType == EntryType.morning
                      ? 'Morning Gratitude'
                      : 'Evening Gratitude',
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                      ? '${entry!.items.length} items recorded'
                      : 'Write 3-5 things you\'re grateful for',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!isComplete)
            IconButton(
              onPressed: onStartTap,
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final int current;
  final int target;
  final Color color;

  const _ProgressCircle({
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);
    final themeProvider = context.watch<ThemeProvider>();

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: themeProvider.textSecondary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$current/$target',
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RandomMemoryCard extends StatelessWidget {
  final GratitudeEntry entry;
  final VoidCallback onRefresh;

  const _RandomMemoryCard({required this.entry, required this.onRefresh});

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
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final firstItem = entry.items.isNotEmpty ? entry.items.first : null;

    return ElevatedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                color: const Color(0xFF9C27B0),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Memory from ${_formatDate(entry.date)}',
                style: TextStyle(
                  color: const Color(0xFF9C27B0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: Icon(
                  LucideIcons.refreshCw,
                  color: themeProvider.textSecondary,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (firstItem != null)
            Text(
              '"${firstItem.content}"',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final GratitudePrompt prompt;
  final VoidCallback onRefresh;
  final VoidCallback onStart;

  const _PromptCard({
    required this.prompt,
    required this.onRefresh,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lightbulb,
                color: themeProvider.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Prompt',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: Icon(
                  LucideIcons.refreshCw,
                  color: themeProvider.textSecondary,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prompt.content,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Writing',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final GratitudeEntry entry;

  const _EntryCard({required this.entry});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

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
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                entry.entryType == EntryType.morning
                    ? LucideIcons.sun
                    : LucideIcons.moon,
                color: entry.entryType == EntryType.morning
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF5C6BC0),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(entry.date),
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${entry.items.length} items',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...entry.items
              .take(2)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.content,
                          style: TextStyle(
                            color: themeProvider.textPrimary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (entry.items.length > 2)
            Text(
              '+${entry.items.length - 2} more',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
