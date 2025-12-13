import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:avatar_glow/avatar_glow.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/affirmation_provider.dart';

/// Record step - record new or select from saved (max 3 slots, 1 min each)
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
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Your Affirmations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Record up to 3 affirmations (max 1 minute each)',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // Saved recordings slots
                _buildRecordingSlots(context, themeProvider, provider),

                const SizedBox(height: 32),

                // Recording area (only if recording or has recording)
                if (provider.recordingState != RecordingState.idle)
                  _buildRecordingArea(context, themeProvider, provider),

                // Record new button (if not recording and has space)
                if (provider.recordingState == RecordingState.idle &&
                    provider.savedRecordings.length < 3)
                  _buildRecordNewButton(context, themeProvider, provider),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Navigation buttons - fixed at bottom with SafeArea
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _buildNavigationButtons(themeProvider, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingSlots(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.mic, size: 18, color: themeProvider.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Saved Recordings (${provider.savedRecordings.length}/3)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Show saved recordings
        ...provider.savedRecordings.asMap().entries.map((entry) {
          final index = entry.key;
          final recording = entry.value;
          final isSelected = provider.selectedRecordingIndex == index;

          return GestureDetector(
            onTap: () => provider.selectRecording(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeProvider.primaryColor.withValues(alpha: 0.15)
                    : themeProvider.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? themeProvider.primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? themeProvider.primaryColor.withValues(alpha: 0.2)
                          : themeProvider.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? LucideIcons.circleCheck : LucideIcons.mic,
                      size: 20,
                      color: isSelected
                          ? themeProvider.primaryColor
                          : themeProvider.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: themeProvider.textPrimary,
                          ),
                        ),
                        Text(
                          '${recording.durationSeconds}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Preview button
                  IconButton(
                    onPressed: () => provider.previewRecording(index),
                    icon: Icon(
                      provider.previewingRecordingIndex == index
                          ? LucideIcons.pause
                          : LucideIcons.play,
                      size: 20,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () =>
                        _confirmDelete(context, themeProvider, provider, index),
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Empty slots
        if (provider.savedRecordings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: themeProvider.textSecondary.withValues(alpha: 0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.micOff,
                    size: 32,
                    color: themeProvider.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recordings yet',
                    style: TextStyle(color: themeProvider.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the button below to record',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordingArea(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final isRecording = provider.recordingState == RecordingState.recording;
    final isRecorded = provider.recordingState == RecordingState.recorded;
    final remainingSeconds = 60 - provider.recordingDuration.inSeconds;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecording
              ? Colors.red.withValues(alpha: 0.5)
              : themeProvider.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Recording indicator with avatar glow effect
          if (isRecording) ...[
            // Avatar glow with mic icon
            AvatarGlow(
              glowColor: themeProvider.primaryColor,
              glowShape: BoxShape.circle,
              animate: true,
              glowCount: 3,
              glowRadiusFactor: 0.4,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeProvider.primaryColor,
                ),
                child: const Icon(
                  LucideIcons.mic,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recording...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${remainingSeconds}s remaining',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: provider.recordingDuration.inSeconds / 60,
                minHeight: 6,
                backgroundColor: themeProvider.backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  themeProvider.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Pause and Stop buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause button
                OutlinedButton.icon(
                  onPressed: () => provider.pauseRecording(),
                  icon: Icon(
                    LucideIcons.pause,
                    color: themeProvider.primaryColor,
                  ),
                  label: Text(
                    'Pause',
                    style: TextStyle(color: themeProvider.primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    side: BorderSide(color: themeProvider.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stop button
                ElevatedButton.icon(
                  onPressed: () => provider.stopRecording(),
                  icon: const Icon(LucideIcons.square, color: Colors.white),
                  label: const Text(
                    'Stop',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Paused state - show resume and stop
          if (provider.recordingState == RecordingState.paused) ...[
            Icon(
              LucideIcons.pause,
              size: 48,
              color: themeProvider.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Paused',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.recordingDuration.inSeconds}s recorded',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: provider.recordingDuration.inSeconds / 60,
                minHeight: 6,
                backgroundColor: themeProvider.backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  themeProvider.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Resume button
                ElevatedButton.icon(
                  onPressed: () => provider.resumeRecording(),
                  icon: const Icon(LucideIcons.play, color: Colors.white),
                  label: const Text(
                    'Resume',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stop and save button
                OutlinedButton.icon(
                  onPressed: () => provider.stopRecording(),
                  icon: Icon(
                    LucideIcons.check,
                    color: themeProvider.primaryColor,
                  ),
                  label: Text(
                    'Done',
                    style: TextStyle(color: themeProvider.primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    side: BorderSide(color: themeProvider.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Recorded state - name input
          if (isRecorded) ...[
            Icon(LucideIcons.circleCheck, size: 32, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              'Recording Complete!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.recordingDuration.inSeconds} seconds',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            // Name input
            TextField(
              controller: _nameController,
              style: TextStyle(color: themeProvider.textPrimary),
              decoration: InputDecoration(
                hintText: 'Name your affirmation',
                hintStyle: TextStyle(color: themeProvider.textSecondary),
                filled: true,
                fillColor: themeProvider.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  LucideIcons.tag,
                  color: themeProvider.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.cancelRecording(),
                    icon: const Icon(LucideIcons.x),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeProvider.textSecondary,
                      side: BorderSide(
                        color: themeProvider.textSecondary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_nameController.text.trim().isNotEmpty) {
                        provider.saveRecordingWithName(
                          _nameController.text.trim(),
                        );
                        _nameController.clear();
                      }
                    },
                    icon: const Icon(LucideIcons.save, color: Colors.white),
                    label: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordNewButton(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final hasPermission = await provider.hasRecordingPermission();
          if (!hasPermission) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Microphone permission required'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          await provider.startRecording();
        },
        child: AvatarGlow(
          glowColor: themeProvider.primaryColor,
          glowShape: BoxShape.circle,
          animate: true,
          glowCount: 2,
          glowRadiusFactor: 0.3,
          child: Container(
            width: 100,
            height: 100,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.mic, color: Colors.white, size: 32),
                const SizedBox(height: 4),
                const Text(
                  'Record',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final canContinue =
        provider.selectedRecordingIndex != null ||
        provider.savedRecordings.isNotEmpty;

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(LucideIcons.arrowLeft),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            foregroundColor: themeProvider.textSecondary,
            side: BorderSide(
              color: themeProvider.textSecondary.withValues(alpha: 0.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canContinue ? widget.onContinue : null,
            icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
            label: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              disabledBackgroundColor: themeProvider.textSecondary.withValues(
                alpha: 0.3,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Recording?',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
