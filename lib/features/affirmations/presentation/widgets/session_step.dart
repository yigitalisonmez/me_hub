import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../data/models/background_sound.dart';
import '../providers/affirmation_provider.dart';

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
    final tp = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.mindfulTint, tp.backgroundColor],
          stops: const [0.0, 0.50],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  if (provider.playbackState == PlaybackState.idle)
                    GestureDetector(
                      onTap: onBack,
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
                    )
                  else
                    const SizedBox(width: 38),
                  Expanded(
                    child: Text(
                      'Session',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tp.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 38,
                    child: Text(
                      '3/3',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mindfulDeep,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SessionPlayer(provider: provider),
                    const SizedBox(height: 18),
                    _PlaybackControls(
                      provider: provider,
                      onComplete: onComplete,
                    ),
                    const SizedBox(height: 20),
                    _BackgroundSounds(provider: provider),
                    const SizedBox(height: 18),
                    _VolumePanel(provider: provider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionPlayer extends StatelessWidget {
  final AffirmationProvider provider;

  const _SessionPlayer({required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final selectedIndex = provider.selectedRecordingIndex;
    final recordingName =
        selectedIndex != null && selectedIndex < provider.savedRecordings.length
        ? provider.savedRecordings[selectedIndex].name
        : 'No recording selected';

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mindfulTint.withValues(
                      alpha: themeProvider.isDarkMode ? 0.12 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mindful.withValues(alpha: 0.22),
                        blurRadius: 34,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 208,
                  height: 208,
                  child: CircularProgressIndicator(
                    value: provider.progress.clamp(0, 1).toDouble(),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: themeProvider.borderColor.withValues(
                      alpha: 0.34,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.mindful,
                    ),
                  ),
                ),
                _FloatingAffirmationAsset(
                  active: provider.playbackState == PlaybackState.playing,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'NOW PLAYING',
            style: TextStyle(
              color: AppColors.mindfulDeep,
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            recordingName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${provider.formattedRemainingTime} of ${_formatDuration(provider.totalDuration)}',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _FloatingAffirmationAsset extends StatefulWidget {
  final bool active;

  const _FloatingAffirmationAsset({required this.active});

  @override
  State<_FloatingAffirmationAsset> createState() =>
      _FloatingAffirmationAssetState();
}

class _FloatingAffirmationAssetState extends State<_FloatingAffirmationAsset>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _FloatingAffirmationAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller
        ..stop()
        ..animateTo(0, duration: const Duration(milliseconds: 260));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      builder: (context, child) {
        final t = _controller.value;
        final lift = widget.active ? -10.0 * t : 0.0;
        final scale = widget.active ? 1.0 + (0.045 * t) : 1.0;

        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Image.asset(
        'assets/images/affirmation.png',
        width: 130,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final AffirmationProvider provider;
  final VoidCallback onComplete;

  const _PlaybackControls({required this.provider, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isPlaying = provider.playbackState == PlaybackState.playing;
    final isPaused = provider.playbackState == PlaybackState.paused;
    final canStart = provider.selectedRecordingIndex != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: LucideIcons.refreshCw,
          onTap: provider.playbackState == PlaybackState.idle
              ? null
              : () => provider.stopPlayback(),
        ),
        const SizedBox(width: 22),
        _CircleButton(
          icon: isPlaying ? LucideIcons.pause : LucideIcons.play,
          primary: true,
          onTap: canStart
              ? () {
                  if (isPlaying) {
                    provider.pausePlayback();
                  } else if (isPaused) {
                    provider.resumePlayback();
                  } else {
                    provider.startPlayback();
                  }
                }
              : null,
        ),
        const SizedBox(width: 22),
        _CircleButton(
          icon: LucideIcons.square,
          onTap: provider.playbackState == PlaybackState.idle
              ? null
              : () async {
                  await provider.stopPlayback();
                  onComplete();
                },
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: primary ? 72 : 50,
        height: primary ? 72 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? AppColors.mindfulDeep : themeProvider.cardColor,
          border: primary
              ? null
              : Border.all(
                  color: themeProvider.borderColor.withValues(alpha: 0.35),
                ),
          boxShadow: [
            BoxShadow(
              color: primary
                  ? AppColors.mindfulDeep.withValues(alpha: 0.32)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: primary ? 24 : 14,
              offset: Offset(0, primary ? 12 : 7),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: disabled
              ? themeProvider.textTertiary.withValues(alpha: 0.55)
              : primary
              ? Colors.white
              : themeProvider.textSecondary,
          size: primary ? 28 : 19,
        ),
      ),
    );
  }
}

class _BackgroundSounds extends StatelessWidget {
  final AffirmationProvider provider;

  const _BackgroundSounds({required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Background sound',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: provider.availableBackgrounds.map((sound) {
            final selected = provider.selectedBackground?.id == sound.id;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: sound == provider.availableBackgrounds.last ? 0 : 9,
                ),
                child: _SoundTile(
                  sound: sound,
                  selected: selected,
                  previewing: provider.previewingSoundId == sound.id,
                  onSelect: () => provider.setBackground(sound),
                  onPreview: () => provider.previewBackgroundSound(sound),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SoundTile extends StatelessWidget {
  final BackgroundSound sound;
  final bool selected;
  final bool previewing;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const _SoundTile({
    required this.sound,
    required this.selected,
    required this.previewing,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.mindfulTint.withValues(
                  alpha: themeProvider.isDarkMode ? 0.14 : 1,
                )
              : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.mindful
                : themeProvider.borderColor.withValues(alpha: 0.35),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              sound.icon,
              color: selected
                  ? AppColors.mindfulDeep
                  : themeProvider.textSecondary,
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              sound.nameEn,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? AppColors.mindfulDeep
                    : themeProvider.textSecondary,
                fontSize: 10.8,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            GestureDetector(
              onTap: onPreview,
              child: Icon(
                previewing ? LucideIcons.circlePause : LucideIcons.circlePlay,
                color: selected
                    ? AppColors.mindfulDeep
                    : themeProvider.textTertiary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumePanel extends StatelessWidget {
  final AffirmationProvider provider;

  const _VolumePanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ElevatedCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      borderRadius: 20,
      child: Column(
        children: [
          _VolumeRow(
            icon: LucideIcons.mic,
            label: 'Voice',
            value: provider.voiceVolume,
            onChanged: provider.setVoiceVolume,
          ),
          _VolumeRow(
            icon: LucideIcons.volume2,
            label: 'Background',
            value: provider.backgroundVolume,
            onChanged: provider.setBackgroundVolume,
          ),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        Icon(icon, color: AppColors.mindfulDeep, size: 16),
        const SizedBox(width: 9),
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.mindful,
              inactiveTrackColor: AppColors.mindfulTint.withValues(
                alpha: themeProvider.isDarkMode ? 0.16 : 1,
              ),
              thumbColor: Colors.white,
              overlayColor: AppColors.mindful.withValues(alpha: 0.16),
              trackHeight: 6,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
