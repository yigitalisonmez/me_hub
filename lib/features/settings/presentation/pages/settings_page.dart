import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/voice_settings_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const PageHeader(
                title: 'Settings',
                subtitle: 'Preferences for your local Kora',
                showBackButton: true,
              ),
              const SizedBox(height: 24),
              _buildSettingsCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    final themeProvider = context.watch<ThemeProvider>();
    final voiceSettings = context.watch<VoiceSettingsProvider>();
    final theme = Theme.of(context);

    return ElevatedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                color: themeProvider.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Preferences',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust appearance and voice command preferences.',
            style: TextStyle(
              fontSize: 13,
              color: themeProvider.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Dark Mode Toggle
          _SettingsPanel(
            padding: const EdgeInsets.all(16),
            themeProvider: themeProvider,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.palette,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: themeProvider.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Switch to dark theme',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: themeProvider.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.setTheme(value);
                  },
                  activeColor: themeProvider.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Voice Language Selector
          _SettingsPanel(
            padding: const EdgeInsets.all(16),
            themeProvider: themeProvider,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.mic,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Language',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: themeProvider.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Language for voice commands',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: themeProvider.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: VoiceSettingsProvider.availableLocales.map((
                    locale,
                  ) {
                    final isSelected =
                        voiceSettings.selectedLocale == locale['code'];
                    return GestureDetector(
                      onTap: () => voiceSettings.setLocale(locale['code']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeProvider.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? themeProvider.primaryColor
                                : themeProvider.textSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                        ),
                        child: Text(
                          '${locale['flag']} ${locale['name']}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : themeProvider.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final ThemeProvider themeProvider;
  final Widget child;

  const _SettingsPanel({
    required this.padding,
    required this.themeProvider,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }
}
