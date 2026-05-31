import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../providers/affirmation_provider.dart';

class RecordStep extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const RecordStep({super.key, required this.onContinue, required this.onBack});

  @override
  State<RecordStep> createState() => _RecordStepState();
}

class _RecordStepState extends State<RecordStep> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
                _RecordStage(
                  provider: provider,
                  nameController: _nameController,
                  onSaveRecording: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    provider.saveRecordingWithName(name);
                    _nameController.clear();
                  },
                ),
                const SizedBox(height: 18),
                _RecordingsList(provider: provider),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: _NavigationButtons(
              provider: provider,
              onBack: widget.onBack,
              onContinue: widget.onContinue,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordStage extends StatelessWidget {
  final AffirmationProvider provider;
  final TextEditingController nameController;
  final VoidCallback onSaveRecording;

  const _RecordStage({
    required this.provider,
    required this.nameController,
    required this.onSaveRecording,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isRecording = provider.recordingState == RecordingState.recording;
    final isPaused = provider.recordingState == RecordingState.paused;
    final isRecorded = provider.recordingState == RecordingState.recorded;

    return ElevatedCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      borderRadius: 28,
      backgroundColor: themeProvider.cardColor,
      borderColor: isRecording
          ? AppColors.mindful.withValues(alpha: 0.42)
          : themeProvider.borderColor.withValues(alpha: 0.28),
      child: Column(
        children: [
          _WaveBars(active: isRecording),
          const SizedBox(height: 12),
          Text(
            provider.formattedRecordingTime,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isRecorded
                ? 'Recording complete'
                : isPaused
                ? 'Paused'
                : isRecording
                ? 'Speak slowly and kindly'
                : '${provider.savedRecordings.length}/3 recordings saved',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (!isRecorded)
            _RecordControls(provider: provider)
          else
            _SaveRecordingForm(
              controller: nameController,
              onSave: onSaveRecording,
              onDiscard: provider.cancelRecording,
            ),
        ],
      ),
    );
  }
}

class _WaveBars extends StatefulWidget {
  final bool active;

  const _WaveBars({required this.active});

  @override
  State<_WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<_WaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(21, (index) {
              final base = 14 + math.sin(index * 0.75).abs() * 28;
              final pulse = widget.active
                  ? math
                            .sin(
                              (_controller.value * math.pi * 2) + index * 0.55,
                            )
                            .abs() *
                        18
                  : 0;
              return Container(
                width: 4,
                height: base + pulse,
                margin: const EdgeInsets.symmetric(horizontal: 1.8),
                decoration: BoxDecoration(
                  color: AppColors.mindful.withValues(
                    alpha: widget.active ? 0.90 : 0.38,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _RecordControls extends StatelessWidget {
  final AffirmationProvider provider;

  const _RecordControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isIdle = provider.recordingState == RecordingState.idle;
    final isRecording = provider.recordingState == RecordingState.recording;
    final isPaused = provider.recordingState == RecordingState.paused;
    final canRecord = provider.savedRecordings.length < 3;

    return Column(
      children: [
        GestureDetector(
          onTap: isIdle
              ? canRecord
                    ? () => _startRecording(context, provider)
                    : null
              : isRecording
              ? provider.pauseRecording
              : provider.resumeRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording
                  ? Colors.white
                  : canRecord
                  ? AppColors.mindfulDeep
                  : themeProvider.borderColor,
              border: isRecording
                  ? Border.all(color: AppColors.mindful, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.mindfulDeep.withValues(alpha: 0.25),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isIdle
                  ? LucideIcons.mic
                  : isRecording
                  ? LucideIcons.pause
                  : LucideIcons.play,
              color: isRecording ? AppColors.mindfulDeep : Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 13),
        if (isRecording || isPaused)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StageButton(
                icon: isRecording ? LucideIcons.pause : LucideIcons.play,
                label: isRecording ? 'Pause' : 'Resume',
                onTap: isRecording
                    ? provider.pauseRecording
                    : provider.resumeRecording,
              ),
              const SizedBox(width: 10),
              _StageButton(
                icon: LucideIcons.square,
                label: 'Done',
                filled: true,
                onTap: provider.stopRecording,
              ),
            ],
          )
        else
          Text(
            canRecord ? 'Tap to record up to 1:00' : 'Recording limit reached',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Future<void> _startRecording(
    BuildContext context,
    AffirmationProvider provider,
  ) async {
    final hasPermission = await provider.hasRecordingPermission();
    if (!hasPermission) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission required'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }
    await provider.startRecording();
  }
}

class _StageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _StageButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: filled ? AppColors.mindfulDeep : Colors.transparent,
        foregroundColor: filled ? Colors.white : AppColors.mindfulDeep,
        side: BorderSide(
          color: filled ? AppColors.mindfulDeep : AppColors.mindful,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SaveRecordingForm extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final Future<void> Function() onDiscard;

  const _SaveRecordingForm({
    required this.controller,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Column(
      children: [
        TextField(
          controller: controller,
          style: TextStyle(color: themeProvider.textPrimary),
          decoration: InputDecoration(
            hintText: 'Name your affirmation',
            hintStyle: TextStyle(color: themeProvider.textTertiary),
            filled: true,
            fillColor: themeProvider.inputFillColor,
            prefixIcon: const Icon(LucideIcons.tag, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDiscard,
                icon: const Icon(LucideIcons.x, size: 16),
                label: const Text('Discard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeProvider.textSecondary,
                  side: BorderSide(
                    color: themeProvider.borderColor.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(
                  LucideIcons.save,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mindfulDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecordingsList extends StatelessWidget {
  final AffirmationProvider provider;

  const _RecordingsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your recordings',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${provider.savedRecordings.length}/3',
              style: const TextStyle(
                color: AppColors.mindfulDeep,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.savedRecordings.isEmpty)
          ElevatedCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 18,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.mindfulTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.micOff,
                    color: AppColors.mindfulDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No recordings yet. Use the record button above.',
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...provider.savedRecordings.asMap().entries.map((entry) {
            final index = entry.key;
            final recording = entry.value;
            final selected = provider.selectedRecordingIndex == index;
            final previewing = provider.previewingRecordingIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: ElevatedCard(
                padding: const EdgeInsets.all(11),
                borderRadius: 18,
                backgroundColor: selected
                    ? AppColors.mindfulTint.withValues(
                        alpha: themeProvider.isDarkMode ? 0.14 : 1,
                      )
                    : null,
                borderColor: selected
                    ? AppColors.mindful.withValues(alpha: 0.65)
                    : null,
                onTap: () => provider.selectRecording(index),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => provider.previewRecording(index),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.mindful,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          previewing ? LucideIcons.pause : LucideIcons.play,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recording.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: themeProvider.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDuration(recording.durationSeconds),
                            style: TextStyle(
                              color: themeProvider.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDelete(
                        context,
                        themeProvider,
                        provider,
                        index,
                      ),
                      icon: Icon(
                        LucideIcons.trash2,
                        color: themeProvider.textTertiary,
                        size: 17,
                      ),
                    ),
                    Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.mindfulDeep
                              : themeProvider.borderColor,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.mindfulDeep,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete recording?',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: themeProvider.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteRecording(index);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  final AffirmationProvider provider;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _NavigationButtons({
    required this.provider,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final canContinue = provider.selectedRecordingIndex != null;

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(LucideIcons.arrowLeft, size: 17),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            foregroundColor: themeProvider.textSecondary,
            side: BorderSide(
              color: themeProvider.borderColor.withValues(alpha: 0.45),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canContinue ? onContinue : null,
            icon: const Icon(
              LucideIcons.arrowRight,
              color: Colors.white,
              size: 17,
            ),
            label: const Text(
              'Use selected',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mindfulDeep,
              disabledBackgroundColor: themeProvider.borderColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
