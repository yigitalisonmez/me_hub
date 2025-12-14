import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../providers/breathing_provider.dart';
import '../../data/models/breathing_technique.dart';
import 'breathing_session_page.dart';

/// Main page for the Breathing Exercise feature
class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BreathingProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final breathingProvider = context.watch<BreathingProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Gradient header - using app's primary color (terracotta)
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: themeProvider.backgroundColor,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Stats button
              IconButton(
                icon: Icon(LucideIcons.chartBar, color: Colors.white),
                onPressed: () => _showStatsSheet(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Breathing',
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
                        LucideIcons.wind,
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

          // Content with staggered animation
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
                    // Stats summary
                    _StatsRow(
                      totalMinutes: breathingProvider.totalMindfulMinutes,
                      streak: breathingProvider.currentStreak,
                      sessions: breathingProvider.sessionHistory.length,
                    ),
                    const SizedBox(height: 24),

                    // Category buttons
                    _CategorySelector(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (category) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Technique cards - filtered by category
                    _TechniqueGrid(
                      techniques: _getFilteredTechniques(),
                      customTechniques: breathingProvider.customTechniques,
                      onTap: (technique) => _startSession(technique),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // SOS Floating Action Button - using app primary color
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startQuickSession(),
        backgroundColor: themeProvider.primaryColor,
        icon: const Icon(LucideIcons.heartPulse, color: Colors.white),
        label: const Text(
          'SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<BreathingTechnique> _getFilteredTechniques() {
    if (_selectedCategory == 'all') {
      return BreathingTechnique.presets;
    }
    return BreathingTechnique.presets
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  void _startSession(BreathingTechnique technique) {
    final provider = context.read<BreathingProvider>();
    provider.selectTechnique(technique);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BreathingSessionPage()));
  }

  void _startQuickSession() {
    final provider = context.read<BreathingProvider>();
    provider.startQuickSession();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BreathingSessionPage()));
  }

  void _showStatsSheet(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final provider = context.read<BreathingProvider>();

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
              icon: LucideIcons.clock,
              label: 'Total Time',
              value: '${provider.totalMindfulMinutes} min',
              color: themeProvider.primaryColor,
            ),
            const SizedBox(height: 12),
            _StatItem(
              icon: LucideIcons.flame,
              label: 'Daily Streak',
              value: '${provider.currentStreak} days',
              color: const Color(0xFFFF7043),
            ),
            const SizedBox(height: 12),
            _StatItem(
              icon: LucideIcons.activity,
              label: 'Total Sessions',
              value: '${provider.sessionHistory.length}',
              color: const Color(0xFF42A5F5),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalMinutes;
  final int streak;
  final int sessions;

  const _StatsRow({
    required this.totalMinutes,
    required this.streak,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: LucideIcons.clock,
            value: '$totalMinutes',
            label: 'minutes',
            color: themeProvider.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
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
            icon: LucideIcons.activity,
            value: '$sessions',
            label: 'sessions',
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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

class _CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final void Function(String) onCategoryChanged;

  const _CategorySelector({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final categories = [
      ('all', 'All', LucideIcons.grid3x3),
      ('sleep', 'Sleep', LucideIcons.moon),
      ('focus', 'Focus', LucideIcons.target),
      ('relax', 'Relax', LucideIcons.heart),
      ('energy', 'Energy', LucideIcons.zap),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (id, label, icon) = categories[index];
          final isSelected = selectedCategory == id;

          return GestureDetector(
            onTap: () => onCategoryChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: themeProvider.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : themeProvider.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : themeProvider.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TechniqueGrid extends StatelessWidget {
  final List<BreathingTechnique> techniques;
  final List<BreathingTechnique> customTechniques;
  final void Function(BreathingTechnique) onTap;

  const _TechniqueGrid({
    required this.techniques,
    required this.customTechniques,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final allTechniques = [...techniques, ...customTechniques];

    if (allTechniques.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No techniques in this category',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final technique in allTechniques) ...[
          _TechniqueCard(technique: technique, onTap: () => onTap(technique)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  final BreathingTechnique technique;
  final VoidCallback onTap;

  const _TechniqueCard({required this.technique, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Format timing pattern
    final pattern = [
      technique.inhaleSeconds,
      if (technique.holdAfterInhaleSeconds > 0)
        technique.holdAfterInhaleSeconds,
      technique.exhaleSeconds,
      if (technique.holdAfterExhaleSeconds > 0)
        technique.holdAfterExhaleSeconds,
    ].join('-');

    return ElevatedCard(
      borderRadius: 20,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: technique.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              technique.icon,
              color: technique.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technique.nameEn,
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  technique.descriptionEn,
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Timing badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: technique.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pattern,
              style: TextStyle(
                color: technique.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
