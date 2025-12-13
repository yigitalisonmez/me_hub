import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/affirmation_provider.dart';

/// Session completion page - themed with app's terracotta palette
class SessionCompletePage extends StatelessWidget {
  final VoidCallback onClose;

  const SessionCompletePage({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeProvider.primaryColor.withValues(alpha: 0.3),
              themeProvider.backgroundColor,
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Celebration visual
                _buildCelebrationVisual(themeProvider),

                const SizedBox(height: 40),

                // Congratulations text
                Text(
                  'Session Complete! 🌙',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your subconscious mind has absorbed\nyour affirmations. Sweet dreams!',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Stats
                _buildStats(themeProvider, provider),

                const SizedBox(height: 32),

                // Motivational message
                _buildMotivationalCard(themeProvider),

                const Spacer(),

                // Close button
                _buildCloseButton(themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationVisual(ThemeProvider themeProvider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                themeProvider.primaryColor.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Inner circle
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeProvider.primaryColor,
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(LucideIcons.sparkles, size: 60, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            themeProvider,
            icon: LucideIcons.timer,
            value: '30',
            label: 'Minutes',
          ),
          Container(
            height: 50,
            width: 1,
            color: themeProvider.textSecondary.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            themeProvider,
            icon: LucideIcons.trophy,
            value: '${provider.totalCompletedSessions}',
            label: 'Total Sessions',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeProvider themeProvider, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: themeProvider.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: themeProvider.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: themeProvider.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMotivationalCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.quote,
            size: 24,
            color: themeProvider.primaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Consistency is key. Each session strengthens the neural pathways of positivity.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: themeProvider.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onClose,
        icon: const Icon(LucideIcons.house, color: Colors.white),
        label: const Text(
          'Back to Home',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
