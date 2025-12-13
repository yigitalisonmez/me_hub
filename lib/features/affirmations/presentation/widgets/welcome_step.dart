import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/affirmation_provider.dart';

/// Welcome step - shows how it works and session history
class WelcomeStep extends StatelessWidget {
  final VoidCallback onBegin;

  const WelcomeStep({super.key, required this.onBegin});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(themeProvider),

                const SizedBox(height: 32),

                // How It Works
                _buildHowItWorks(themeProvider),

                const SizedBox(height: 32),

                // Session History
                if (provider.sessionHistory.isNotEmpty)
                  _buildSessionHistory(themeProvider, provider),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Let's Begin button - fixed at bottom
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _buildBeginButton(themeProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeProvider.primaryColor.withValues(alpha: 0.2),
                themeProvider.primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: themeProvider.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep Affirmations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reprogram your subconscious while you sleep',
                      style: TextStyle(
                        fontSize: 13,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks(ThemeProvider themeProvider) {
    final steps = [
      {
        'icon': LucideIcons.mic,
        'title': 'Record',
        'desc': 'Record up to 3 short affirmations (max 1 min each)',
      },
      {
        'icon': LucideIcons.music,
        'title': 'Choose Music',
        'desc': 'Select calming background sounds',
      },
      {
        'icon': LucideIcons.moon,
        'title': 'Sleep',
        'desc': 'Listen for 30 minutes as you drift off',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.info,
              size: 18,
              color: themeProvider.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'How It Works',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return _buildStepCard(
            themeProvider,
            stepNumber: index + 1,
            icon: step['icon'] as IconData,
            title: step['title'] as String,
            description: step['desc'] as String,
          );
        }),
      ],
    );
  }

  Widget _buildStepCard(
    ThemeProvider themeProvider, {
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: themeProvider.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistory(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.history,
              size: 18,
              color: themeProvider.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Sessions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...provider.sessionHistory.take(5).map((log) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.moon,
                  size: 18,
                  color: themeProvider.primaryColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.formattedDate,
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${log.durationMinutes} min',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBeginButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onBegin,
        icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
        label: const Text(
          "Let's Begin",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: themeProvider.primaryColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
