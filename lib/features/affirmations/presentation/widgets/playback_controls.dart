import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/affirmation_provider.dart';

/// Widget for controlling playback - themed with app's terracotta palette
class PlaybackControls extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const PlaybackControls({
    super.key,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer display
          _buildTimerDisplay(themeProvider, provider),

          const SizedBox(height: 20),

          // Progress indicator
          _buildProgressBar(themeProvider, provider),

          const SizedBox(height: 28),

          // Playback buttons
          _buildPlaybackButtons(context, themeProvider, provider),

          const SizedBox(height: 28),

          // Volume controls
          _buildVolumeControls(context, themeProvider, provider),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Column(
      children: [
        Text(
          provider.formattedRemainingTime,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w300,
            fontFamily: 'monospace',
            color: themeProvider.textPrimary,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.moon,
              size: 14,
              color: themeProvider.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'remaining',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: provider.progress,
            minHeight: 8,
            backgroundColor: themeProvider.backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              themeProvider.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${((1 - provider.progress) * 100).toInt()}% complete',
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.textSecondary,
              ),
            ),
            Text(
              provider.formattedRemainingTime,
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackButtons(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final isPlaying = provider.playbackState == PlaybackState.playing;
    final isPaused = provider.playbackState == PlaybackState.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        _buildControlButton(
          icon: LucideIcons.square,
          color: themeProvider.textSecondary,
          onPressed: provider.playbackState != PlaybackState.idle
              ? onStop
              : null,
          size: 52,
          themeProvider: themeProvider,
        ),

        const SizedBox(width: 24),

        // Play/Pause button
        GestureDetector(
          onTap: () {
            if (isPlaying) {
              onPause();
            } else if (isPaused) {
              provider.resumePlayback();
            } else {
              onPlay();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeProvider.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? LucideIcons.pause : LucideIcons.play,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Placeholder for symmetry
        const SizedBox(width: 52),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required double size,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: themeProvider.backgroundColor,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }

  Widget _buildVolumeControls(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Voice volume
          _buildVolumeSlider(
            context: context,
            themeProvider: themeProvider,
            label: 'Voice',
            icon: LucideIcons.mic,
            value: provider.voiceVolume,
            onChanged: provider.setVoiceVolume,
            color: themeProvider.primaryColor,
          ),

          if (provider.selectedBackground != null) ...[
            const SizedBox(height: 16),

            // Background volume
            _buildVolumeSlider(
              context: context,
              themeProvider: themeProvider,
              label: 'Background',
              icon: LucideIcons.music,
              value: provider.backgroundVolume,
              onChanged: provider.setBackgroundVolume,
              color: const Color(0xFF4FC3F7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeSlider({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required String label,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: themeProvider.textSecondary),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              activeColor: color,
              inactiveColor: themeProvider.backgroundColor,
            ),
          ),
        ),
        SizedBox(
          width: 45,
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: themeProvider.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
