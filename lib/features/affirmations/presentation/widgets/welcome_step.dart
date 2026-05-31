import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/affirmation_provider.dart';

class WelcomeStep extends StatefulWidget {
  final VoidCallback onBegin;
  final VoidCallback? onBack;

  const WelcomeStep({super.key, required this.onBegin, this.onBack});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.mindfulTint, tp.backgroundColor],
          stops: const [0.0, 0.55],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, tp),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    _FloatingHero(anim: _floatAnim),
                    const SizedBox(height: 18),
                    Text(
                      'Fall asleep to your\nown kind words.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tp.textPrimary,
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Record short affirmations and let them play\nsoftly over calming sounds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tp.textSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _FlowSteps(),
                    if (provider.sessionHistory.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SessionHistory(provider: provider, tp: tp),
                    ],
                  ],
                ),
              ),
            ),
            _buildCta(context, tp),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tp.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tp.textSecondary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 19,
                color: tp.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Sleep Affirmations',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tp.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context, ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: widget.onBegin,
          icon: const Icon(LucideIcons.mic, color: Colors.white, size: 18),
          label: const Text(
            'Record your affirmations',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mindfulDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: AppColors.mindful.withValues(alpha: 0.50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating hero ─────────────────────────────
class _FloatingHero extends StatelessWidget {
  final Animation<double> anim;

  const _FloatingHero({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -(anim.value * 10)),
        child: child,
      ),
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blurred glow — large sigma makes it spread wide like CSS blur
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mindful.withValues(alpha: 0.55),
                ),
              ),
            ),
            // Asset on top of glow
            Image.asset(
              'assets/images/affirmation.png',
              width: 172,
              filterQuality: FilterQuality.high,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3 step cards ──────────────────────────────
class _FlowSteps extends StatelessWidget {
  const _FlowSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (LucideIcons.mic, 'Record', 'Up to 3 affirmations in your own voice.'),
      (LucideIcons.wind, 'Set the mood', 'Layer in rain, pads or summer night.'),
      (LucideIcons.moon, 'Drift off', 'Listen on a gentle loop as you sleep.'),
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepCard(
            number: i + 1,
            icon: steps[i].$1,
            title: steps[i].$2,
            subtitle: steps[i].$3,
          ),
          if (i < steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tp.textSecondary.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.mindful,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.mindfulTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.mindfulDeep, size: 18),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tp.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: tp.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

// ── Session history (optional) ─────────────────
class _SessionHistory extends StatelessWidget {
  final AffirmationProvider provider;
  final ThemeProvider tp;

  const _SessionHistory({required this.provider, required this.tp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent sessions',
          style: TextStyle(
            color: tp.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...provider.sessionHistory.take(3).map(
          (log) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tp.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tp.textSecondary.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.moon,
                    color: AppColors.mindfulDeep,
                    size: 18,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      log.formattedDate,
                      style: TextStyle(
                        color: tp.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${log.durationMinutes} min',
                    style: TextStyle(
                      color: tp.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
