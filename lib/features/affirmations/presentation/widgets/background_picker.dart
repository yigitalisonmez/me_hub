import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../data/models/background_sound.dart';
import '../providers/affirmation_provider.dart';

/// Widget for selecting background sounds with preview - English names
class BackgroundPicker extends StatelessWidget {
  const BackgroundPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.music,
              size: 18,
              color: themeProvider.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Background Sound',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tap to select, long press to preview',
          style: TextStyle(fontSize: 13, color: themeProvider.textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                provider.availableBackgrounds.length + 1, // +1 for "None"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSoundCard(context, themeProvider, provider, null);
              }
              return _buildSoundCard(
                context,
                themeProvider,
                provider,
                provider.availableBackgrounds[index - 1],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSoundCard(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
    BackgroundSound? sound,
  ) {
    final isSelected =
        (sound == null && provider.selectedBackground == null) ||
        (sound != null && provider.selectedBackground?.id == sound.id);
    final isPreviewing =
        sound != null && provider.previewingSoundId == sound.id;

    final accentColor = themeProvider.primaryColor;

    IconData icon;
    String name;

    if (sound == null) {
      icon = LucideIcons.volumeOff;
      name = 'Silent';
    } else {
      icon = sound.icon;
      name = sound.nameEn; // Use English name
    }

    return GestureDetector(
      onTap: () => provider.setBackground(sound),
      onLongPress: sound != null
          ? () => provider.previewBackgroundSound(sound)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPreviewing
                ? Colors.green
                : (isSelected ? accentColor : Colors.transparent),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.2)
                        : themeProvider.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPreviewing ? LucideIcons.volume2 : icon,
                    size: 22,
                    color: isPreviewing
                        ? Colors.green
                        : (isSelected
                              ? accentColor
                              : themeProvider.textSecondary),
                  ),
                ),
                if (isPreviewing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? accentColor : themeProvider.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(LucideIcons.check, size: 12, color: accentColor),
              ),
          ],
        ),
      ),
    );
  }
}
