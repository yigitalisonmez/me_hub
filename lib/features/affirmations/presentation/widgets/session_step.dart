import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../data/models/background_sound.dart';
import '../providers/affirmation_provider.dart';

/// Session step - 30 min circular timer with music dropdown
class SessionStep extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const SessionStep({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Status text
          Text(
            provider.playbackState == PlaybackState.playing
                ? 'Session Active'
                : provider.playbackState == PlaybackState.paused
                ? 'Paused'
                : 'Ready to Start',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: provider.playbackState == PlaybackState.playing
                  ? themeProvider.primaryColor
                  : themeProvider.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Circular Timer
          _buildCircularTimer(themeProvider, provider),

          const SizedBox(height: 40),

          // Playback controls
          _buildPlaybackControls(context, themeProvider, provider),

          const SizedBox(height: 32),

          // Background music dropdown
          _buildMusicDropdown(themeProvider, provider),

          const SizedBox(height: 24),

          // Volume slider
          if (provider.playbackState != PlaybackState.idle)
            _buildVolumeControls(themeProvider, provider),

          const SizedBox(height: 32),

          // End session button
          if (provider.playbackState != PlaybackState.idle)
            _buildEndSessionButton(themeProvider, provider),

          // Back button (only when idle)
          if (provider.playbackState == PlaybackState.idle)
            TextButton.icon(
              onPressed: onBack,
              icon: Icon(
                LucideIcons.arrowLeft,
                color: themeProvider.textSecondary,
              ),
              label: Text(
                'Back to recordings',
                style: TextStyle(color: themeProvider.textSecondary),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCircularTimer(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final progress = provider.progress;
    final timeString = provider.formattedRemainingTime;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeProvider.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          // Progress arc
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: progress,
                color: themeProvider.primaryColor,
                backgroundColor: themeProvider.backgroundColor,
                strokeWidth: 10,
              ),
            ),
          ),
          // Time display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.moon,
                size: 28,
                color: themeProvider.primaryColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  color: themeProvider.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final isPlaying = provider.playbackState == PlaybackState.playing;
    final isPaused = provider.playbackState == PlaybackState.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: () {
            if (isPlaying) {
              provider.pausePlayback();
            } else if (isPaused) {
              provider.resumePlayback();
            } else {
              provider.startPlayback();
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
      ],
    );
  }

  Widget _buildMusicDropdown(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: themeProvider.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: provider.selectedBackground?.id,
                isExpanded: true,
                icon: Icon(
                  LucideIcons.chevronDown,
                  color: themeProvider.textSecondary,
                ),
                dropdownColor: themeProvider.cardColor,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.volumeOff,
                          size: 18,
                          color: themeProvider.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Silent',
                          style: TextStyle(color: themeProvider.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  ...BackgroundSound.presets.map((sound) {
                    return DropdownMenuItem<String?>(
                      value: sound.id,
                      child: Row(
                        children: [
                          Icon(
                            sound.icon,
                            size: 18,
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            sound.nameEn,
                            style: TextStyle(color: themeProvider.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value == null) {
                    provider.setBackground(null);
                  } else {
                    final sound = BackgroundSound.findById(value);
                    provider.setBackground(sound);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControls(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Voice volume
          Row(
            children: [
              Icon(
                LucideIcons.mic,
                size: 16,
                color: themeProvider.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice',
                style: TextStyle(
                  fontSize: 13,
                  color: themeProvider.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: provider.voiceVolume,
                  onChanged: provider.setVoiceVolume,
                  activeColor: themeProvider.primaryColor,
                  inactiveColor: themeProvider.backgroundColor,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(provider.voiceVolume * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          // Background volume
          if (provider.selectedBackground != null)
            Row(
              children: [
                Icon(
                  LucideIcons.music,
                  size: 16,
                  color: const Color(0xFF4FC3F7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Music',
                  style: TextStyle(
                    fontSize: 13,
                    color: themeProvider.textSecondary,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: provider.backgroundVolume,
                    onChanged: provider.setBackgroundVolume,
                    activeColor: const Color(0xFF4FC3F7),
                    inactiveColor: themeProvider.backgroundColor,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(provider.backgroundVolume * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEndSessionButton(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return TextButton.icon(
      onPressed: () async {
        await provider.stopPlayback();
        onComplete();
      },
      icon: Icon(LucideIcons.x, color: themeProvider.textSecondary),
      label: Text(
        'Complete Session',
        style: TextStyle(color: themeProvider.textSecondary),
      ),
    );
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
