import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/breathing_provider.dart';
import '../../data/models/breathing_technique.dart';
import 'breathing_session_page.dart';

/// Main page for the Breathing Exercise feature.
class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage> {
  BreathingTechnique _selectedTechnique = BreathingTechnique.presets.first;
  String _selectedAmbient = 'rain';

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
    final techniques = [
      ...BreathingTechnique.presets,
      ...breathingProvider.customTechniques,
    ];

    if (!techniques.any((technique) => technique.id == _selectedTechnique.id)) {
      _selectedTechnique = techniques.first;
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      bottomNavigationBar: Container(
        color: themeProvider.backgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: _StartBreathingButton(
            technique: _selectedTechnique,
            onTap: () => _startSession(_selectedTechnique),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeProvider.isDarkMode
                  ? AppColors.mindfulTint.withValues(alpha: 0.12)
                  : AppColors.mindfulTint,
              themeProvider.backgroundColor,
              themeProvider.backgroundColor,
            ],
            stops: const [0, 0.58, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 36,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _BreathingTopBar(
                      onStatsTap: () => _showStatsSheet(context),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BreathStatPill(
                            icon: LucideIcons.clock,
                            value: '${breathingProvider.totalMindfulMinutes}',
                            label: 'min this week',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BreathStatPill(
                            icon: LucideIcons.flame,
                            value: '${breathingProvider.currentStreak}',
                            label: 'day streak',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _BreathingStage(technique: _selectedTechnique),
                    const SizedBox(height: 18),
                    _TechniquePicker(
                      techniques: techniques,
                      selectedTechnique: _selectedTechnique,
                      onSelected: (technique) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTechnique = technique);
                      },
                    ),
                    const SizedBox(height: 16),
                    _AmbientPicker(
                      selectedAmbient: _selectedAmbient,
                      onSelected: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAmbient = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    const _BreathIntent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startSession(BreathingTechnique technique) {
    final provider = context.read<BreathingProvider>();
    provider.selectTechnique(technique);

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
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _StatsSheetRow(
              icon: LucideIcons.clock,
              label: 'Total Time',
              value: '${provider.totalMindfulMinutes} min',
              color: AppColors.mindfulDeep,
            ),
            const SizedBox(height: 12),
            _StatsSheetRow(
              icon: LucideIcons.flame,
              label: 'Daily Streak',
              value: '${provider.currentStreak} days',
              color: AppColors.moodDeep,
            ),
            const SizedBox(height: 12),
            _StatsSheetRow(
              icon: LucideIcons.activity,
              label: 'Total Sessions',
              value: '${provider.sessionHistory.length}',
              color: AppColors.waterDeep,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BreathingTopBar extends StatelessWidget {
  final VoidCallback onStatsTap;

  const _BreathingTopBar({required this.onStatsTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        _BreathRoundButton(
          icon: LucideIcons.chevronLeft,
          onTap: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: Text(
            'Breathing',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _BreathRoundButton(
          icon: LucideIcons.chartBar,
          color: AppColors.mindfulDeep,
          onTap: onStatsTap,
        ),
      ],
    );
  }
}

class _BreathRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _BreathRoundButton({required this.icon, this.onTap, this.color});

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: themeProvider.isDarkMode ? 0.18 : 0.04,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? themeProvider.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _BreathStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _BreathStatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: themeProvider.isDarkMode ? 0.18 : 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.mindfulDeep),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: themeProvider.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingStage extends StatelessWidget {
  final BreathingTechnique technique;

  const _BreathingStage({required this.technique});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BreathingOrb(color: technique.primaryColor),
        const SizedBox(height: 14),
        Text(
          'Breathe in',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.mindfulDeep,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: technique.phases.map((phase) {
            final isFirst = phase == technique.phases.first;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: isFirst
                    ? AppColors.mindfulTint
                    : context.watch<ThemeProvider>().cardColor,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isFirst
                      ? AppColors.mindful
                      : context.watch<ThemeProvider>().textTertiary.withValues(
                          alpha: 0.16,
                        ),
                ),
              ),
              child: Text(
                '${_shortPhase(phase.label)} · ${phase.duration}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isFirst
                      ? AppColors.mindfulDeep
                      : context.watch<ThemeProvider>().textTertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BreathingOrb extends StatefulWidget {
  final Color color;

  const _BreathingOrb({required this.color});

  @override
  State<_BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<_BreathingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: AnimatedBuilder(
        animation: _breathAnim,
        builder: (context, child) {
          final t = _breathAnim.value;
          final scale = 0.78 + (t * 0.24);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mindful.withValues(alpha: 0.32 + t * 0.15),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.72 + (t * 0.18),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mindful.withValues(alpha: 0.20 + t * 0.14),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 152,
                  height: 152,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mindfulTint.withValues(alpha: t * 0.20),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: 34,
                child: _Spark(
                  size: 8,
                  opacity: 0.50 + t * 0.40,
                ),
              ),
              Positioned(
                top: 54,
                right: 24,
                child: _Spark(size: 6, opacity: 0.30 + t * 0.45),
              ),
              Positioned(
                bottom: 42,
                left: 54,
                child: _Spark(
                  size: 5,
                  opacity: 0.25 + t * 0.40,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    'assets/images/breathing.png',
                    width: 162,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  final double size;
  final double opacity;

  const _Spark({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.mindful.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TechniquePicker extends StatelessWidget {
  final List<BreathingTechnique> techniques;
  final BreathingTechnique selectedTechnique;
  final ValueChanged<BreathingTechnique> onSelected;

  const _TechniquePicker({
    required this.techniques,
    required this.selectedTechnique,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (techniques.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      itemCount: techniques.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 78,
      ),
      itemBuilder: (context, index) {
        final technique = techniques[index];
        final selected = technique.id == selectedTechnique.id;
        return _TechniquePickCard(
          technique: technique,
          selected: selected,
          onTap: () => onSelected(technique),
        );
      },
    );
  }
}

class _TechniquePickCard extends StatelessWidget {
  final BreathingTechnique technique;
  final bool selected;
  final VoidCallback onTap;

  const _TechniquePickCard({
    required this.technique,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      color: selected ? AppColors.mindfulTint : themeProvider.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.mindful
                  : themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.textPrimary.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: themeProvider.isDarkMode ? 0.18 : 0.04,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -12,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _pattern(technique),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: themeProvider.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _categoryLabel(technique.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: themeProvider.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientPicker extends StatelessWidget {
  final String selectedAmbient;
  final ValueChanged<String> onSelected;

  const _AmbientPicker({
    required this.selectedAmbient,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('rain', 'Rain', LucideIcons.droplet),
      ('waves', 'Waves', LucideIcons.wind),
      ('forest', 'Forest', LucideIcons.leaf),
      ('off', 'Off', LucideIcons.moon),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AMBIENT SOUND',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.watch<ThemeProvider>().textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: items.map((item) {
            final selected = selectedAmbient == item.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: item == items.last ? 0 : 8),
                child: _AmbientChip(
                  label: item.$2,
                  icon: item.$3,
                  selected: selected,
                  onTap: () => onSelected(item.$1),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AmbientChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AmbientChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Material(
      color: selected ? AppColors.mindfulTint : themeProvider.cardColor,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? AppColors.mindful
                  : themeProvider.textTertiary.withValues(alpha: 0.16),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: selected
                    ? AppColors.mindfulDeep
                    : themeProvider.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? AppColors.mindfulDeep
                        : themeProvider.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathIntent extends StatelessWidget {
  const _BreathIntent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.sparkles,
            size: 14,
            color: AppColors.mindfulDeep,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Let each breath soften the day.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mindfulDeep,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartBreathingButton extends StatelessWidget {
  final BreathingTechnique technique;
  final VoidCallback onTap;

  const _StartBreathingButton({required this.technique, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(LucideIcons.play, size: 18, fill: 1.0),
        label: Text('Start ${technique.cyclesInDuration(3)} cycles'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mindfulDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StatsSheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsSheetRow({
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
            color: color.withValues(alpha: 0.14),
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _pattern(BreathingTechnique technique) {
  return [
    technique.inhaleSeconds,
    if (technique.holdAfterInhaleSeconds > 0) technique.holdAfterInhaleSeconds,
    technique.exhaleSeconds,
    if (technique.holdAfterExhaleSeconds > 0) technique.holdAfterExhaleSeconds,
  ].join('-');
}

String _shortPhase(String phase) {
  return switch (phase) {
    'Breathe In' => 'In',
    'Breathe Out' => 'Out',
    _ => phase,
  };
}

String _categoryLabel(String category) {
  return switch (category) {
    'sleep' => 'Calm',
    'focus' => 'Focus',
    'energy' => 'Energy',
    'relax' => 'Relax',
    _ => 'Custom',
  };
}
