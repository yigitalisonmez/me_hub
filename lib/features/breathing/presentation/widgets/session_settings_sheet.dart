import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/breathing_provider.dart';

/// Settings sheet for breathing session (background sound, haptic, volume)
class SessionSettingsSheet extends StatelessWidget {
  const SessionSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<BreathingProvider>();

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            // Title
            Text(
              'Settings',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Haptic feedback toggle
            _SettingRow(
              icon: LucideIcons.vibrate,
              label: 'Haptic Feedback',
              trailing: Switch.adaptive(
                value: provider.hapticEnabled,
                onChanged: (value) => provider.setHapticEnabled(value),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Background sound selector
            Text(
              'Background Sound',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoundChip(
                  label: 'Silent',
                  icon: LucideIcons.volumeOff,
                  isSelected: provider.selectedBackground == null,
                  onTap: () => provider.setBackground(null),
                ),
                // Sound options
                ...provider.availableBackgrounds.map(
                  (sound) => _SoundChip(
                    label: sound.name,
                    icon: sound.icon,
                    isSelected: provider.selectedBackground?.id == sound.id,
                    onTap: () => provider.setBackground(sound),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (provider.selectedBackground != null) ...[
              _SettingRow(
                icon: LucideIcons.volume2,
                label: 'Volume',
                trailing: SizedBox(
                  width: 140,
                  child: Slider(
                    value: provider.backgroundVolume,
                    onChanged: (value) => provider.setBackgroundVolume(value),
                    activeColor: const Color(0xFF4DB6AC),
                    inactiveColor: themeProvider.textSecondary.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB6AC),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        Icon(icon, color: themeProvider.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: themeProvider.textPrimary, fontSize: 15),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _SoundChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SoundChip({
    required this.label,
    required this.icon,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4DB6AC)
              : themeProvider.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4DB6AC)
                : themeProvider.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : themeProvider.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : themeProvider.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
