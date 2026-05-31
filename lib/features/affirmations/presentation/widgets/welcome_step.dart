import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../providers/affirmation_provider.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onBegin;

  const WelcomeStep({super.key, required this.onBegin});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AffirmationProvider>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SleepHero(),
                const SizedBox(height: 18),
                const _FlowSteps(),
                if (provider.sessionHistory.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SessionHistory(provider: provider),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBegin,
                icon: const Icon(
                  LucideIcons.mic,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Record your affirmations',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mindfulDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SleepHero extends StatelessWidget {
  const _SleepHero();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.mindful.withValues(alpha: 0.30),
                      AppColors.mindful.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
              Image.asset(
                'assets/images/affirmation.png',
                width: 138,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fall asleep to your own kind words.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Record short affirmations and let them play softly over calming sounds.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: themeProvider.textSecondary,
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FlowSteps extends StatelessWidget {
  const _FlowSteps();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        icon: LucideIcons.mic,
        title: 'Record',
        text: 'Up to 3 affirmations in your own voice.',
      ),
      (
        icon: LucideIcons.wind,
        title: 'Set the mood',
        text: 'Layer in rain, pads or summer night.',
      ),
      (
        icon: LucideIcons.moon,
        title: 'Drift off',
        text: 'Listen on a gentle loop as you sleep.',
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _FlowStep(
            number: i + 1,
            icon: steps[i].icon,
            title: steps[i].title,
            text: steps[i].text,
          ),
          if (i != steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String text;

  const _FlowStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ElevatedCard(
      padding: const EdgeInsets.all(13),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.mindfulTint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.mindfulDeep, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 12,
                    height: 1.25,
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

class _SessionHistory extends StatelessWidget {
  final AffirmationProvider provider;

  const _SessionHistory({required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent sessions',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...provider.sessionHistory
            .take(3)
            .map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 16,
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
                            color: themeProvider.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${log.durationMinutes} min',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
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
