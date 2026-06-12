import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
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
    final tp = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();
    final canContinue = provider.selectedRecordingIndex != null;
    final remaining = 3 - provider.savedRecordings.length;

    return Container(
      color: tp.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(tp),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
                    const SizedBox(height: 16),
                    _RecordingsList(provider: provider),
                    if (remaining > 0 && provider.savedRecordings.isNotEmpty)
                      _RecordAnotherButton(remaining: remaining),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildBottomButton(tp, canContinue),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
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
          ),
          Expanded(
            child: Text(
              'Record',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tp.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '2/3',
            style: const TextStyle(
              color: AppColors.mindfulDeep,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(ThemeProvider tp, bool canContinue) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        8,
        18,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: canContinue ? widget.onContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mindfulDeep,
            disabledBackgroundColor: tp.borderColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Use selected for session',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.arrowRight,
                size: 18,
                color: canContinue ? Colors.white : tp.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recording stage card ──────────────────────────────
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
    final tp = context.watch<ThemeProvider>();
    final isRecording = provider.recordingState == RecordingState.recording;
    final isPaused = provider.recordingState == RecordingState.paused;
    final isRecorded = provider.recordingState == RecordingState.recorded;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isRecording
              ? AppColors.mindful.withValues(alpha: 0.45)
              : tp.textSecondary.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _WaveBars(active: isRecording),
          const SizedBox(height: 14),
          // Timer: "0:18 / 1:00" format
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: provider.formattedRecordingTime,
                  style: TextStyle(
                    color: tp.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: '  / 1:00',
                  style: TextStyle(
                    color: tp.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!isRecorded)
            _RecordControls(provider: provider)
          else
            _SaveRecordingForm(
              controller: nameController,
              onSave: onSaveRecording,
              onDiscard: provider.cancelRecording,
            ),
          const SizedBox(height: 10),
          Text(
            isRecording
                ? 'Tap to pause · speak slowly and kindly'
                : isPaused
                ? 'Paused · tap to resume'
                : isRecorded
                ? 'Recording complete · name and save'
                : '${provider.savedRecordings.length}/3 recordings saved',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tp.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated waveform bars ────────────────────────────
class _WaveBars extends StatefulWidget {
  final bool active;

  const _WaveBars({required this.active});

  @override
  State<_WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<_WaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(21, (i) {
              final base = 14.0 + math.sin(i * 0.9).abs() * 32 + (i % 3) * 6;
              final pulse = widget.active
                  ? math.sin((_ctrl.value * math.pi * 2) + i * 0.55).abs() * 20
                  : 0;
              return Container(
                width: 4,
                height: (base + pulse).clamp(4.0, 56.0),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.mindful.withValues(
                    alpha: widget.active ? 0.88 : 0.30,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ── Record / pause / stop button ─────────────────────
class _RecordControls extends StatelessWidget {
  final AffirmationProvider provider;

  const _RecordControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isIdle = provider.recordingState == RecordingState.idle;
    final isRecording = provider.recordingState == RecordingState.recording;
    final isPaused = provider.recordingState == RecordingState.paused;
    final canRecord = provider.savedRecordings.length < 3;

    return Column(
      children: [
        // Main record button: circle with border + red square inside (design spec)
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
              color: Colors.white,
              border: Border.all(
                color: isRecording
                    ? AppColors.mindful
                    : AppColors.mindful.withValues(alpha: 0.45),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mindfulDeep.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isIdle
                  ? Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isRecording || !canRecord
                            ? Colors.grey
                            : const Color(0xFFD8584E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : Icon(
                      isRecording ? LucideIcons.pause : LucideIcons.play,
                      color: AppColors.mindfulDeep,
                      size: 28,
                    ),
            ),
          ),
        ),
        if (isRecording || isPaused) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: provider.stopRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mindfulDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
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

// ── Name + save after recording ──────────────────────
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
    final tp = context.watch<ThemeProvider>();

    return Column(
      children: [
        TextField(
          controller: controller,
          style: TextStyle(color: tp.textPrimary),
          decoration: InputDecoration(
            hintText: 'Name this affirmation',
            hintStyle: TextStyle(
              color: tp.textSecondary.withValues(alpha: 0.55),
            ),
            filled: true,
            fillColor: tp.backgroundColor,
            prefixIcon: const Icon(
              LucideIcons.tag,
              size: 17,
              color: AppColors.mindfulDeep,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: tp.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: tp.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.mindfulDeep,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDiscard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tp.textSecondary,
                  side: BorderSide(
                    color: tp.textSecondary.withValues(alpha: 0.25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mindfulDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Recordings list ───────────────────────────────────
class _RecordingsList extends StatelessWidget {
  final AffirmationProvider provider;

  const _RecordingsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your recordings',
              style: TextStyle(
                color: tp.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${provider.savedRecordings.length}/3',
              style: const TextStyle(
                color: AppColors.mindfulDeep,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.savedRecordings.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tp.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tp.textSecondary.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.mindfulTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.micOff,
                    color: AppColors.mindfulDeep,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No recordings yet.\nTap the button above to start.',
                    style: TextStyle(
                      color: tp.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: provider.savedRecordings.asMap().entries.map((entry) {
              final index = entry.key;
              final recording = entry.value;
              final selected = provider.selectedRecordingIndex == index;
              final previewing = provider.previewingRecordingIndex == index;
              final selectedTileColor = tp.isDarkMode
                  ? Color.alphaBlend(
                      AppColors.mindful.withValues(alpha: 0.22),
                      tp.cardColor,
                    )
                  : AppColors.mindfulTint;

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: GestureDetector(
                  onTap: () => provider.selectRecording(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? selectedTileColor : tp.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? AppColors.mindful
                            : tp.textSecondary.withValues(alpha: 0.10),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Play/pause button
                        GestureDetector(
                          onTap: () => provider.previewRecording(index),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.mindful,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              previewing ? LucideIcons.pause : LucideIcons.play,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + duration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recording.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tp.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _fmt(recording.durationSeconds),
                                style: TextStyle(
                                  color: tp.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              _confirmDelete(context, tp, provider, index),
                          icon: Icon(
                            LucideIcons.trash2,
                            color: tp.textSecondary,
                            size: 16,
                          ),
                        ),
                        // Radio select circle
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.mindfulDeep
                                  : tp.borderColor,
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
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  void _confirmDelete(
    BuildContext context,
    ThemeProvider tp,
    AffirmationProvider provider,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tp.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete recording?',
          style: TextStyle(color: tp.textPrimary),
        ),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: tp.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tp.textSecondary)),
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

// ── "Record another · N left" dashed button ──────────
class _RecordAnotherButton extends StatelessWidget {
  final int remaining;

  const _RecordAnotherButton({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.mic, size: 15),
          label: Text(
            'Record another  ·  $remaining left',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.mindfulDeep,
            backgroundColor: AppColors.mindfulTint,
            side: BorderSide(
              color: AppColors.mindful.withValues(alpha: 0.50),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
