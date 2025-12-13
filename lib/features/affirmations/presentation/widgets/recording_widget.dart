import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/affirmation_provider.dart';

/// Widget for recording affirmation audio - centered layout
class RecordingWidget extends StatelessWidget {
  const RecordingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(28),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording state indicator
            _buildStateIndicator(context, themeProvider, provider),

            const SizedBox(height: 32),

            // Recording button(s)
            _buildRecordButtons(context, themeProvider, provider),

            const SizedBox(height: 24),

            // Recording duration
            if (provider.recordingState == RecordingState.recording ||
                provider.recordingState == RecordingState.recorded)
              _buildDurationDisplay(themeProvider, provider),

            // Instructions when idle
            if (provider.recordingState == RecordingState.idle)
              _buildInstructions(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIndicator(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    String text;
    IconData icon;
    Color color;
    String subtitle;

    switch (provider.recordingState) {
      case RecordingState.idle:
        text = 'Ready to Record';
        subtitle = 'Tap the button below to start';
        icon = LucideIcons.mic;
        color = themeProvider.primaryColor;
        break;
      case RecordingState.recording:
        text = 'Recording...';
        subtitle = 'Speak your affirmation clearly';
        icon = LucideIcons.radio;
        color = Colors.red;
        break;
      case RecordingState.paused:
        text = 'Paused';
        subtitle = 'Tap resume to continue recording';
        icon = LucideIcons.pause;
        color = themeProvider.primaryColor;
        break;
      case RecordingState.recorded:
        text = 'Recording Complete';
        subtitle = 'Ready to add background sound';
        icon = LucideIcons.circleCheck;
        color = Colors.green;
        break;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: themeProvider.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRecordButtons(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final isRecording = provider.recordingState == RecordingState.recording;
    final isRecorded = provider.recordingState == RecordingState.recorded;

    if (isRecording) {
      // Show stop and cancel buttons while recording
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cancel button
          GestureDetector(
            onTap: () => provider.cancelRecording(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider.backgroundColor,
                border: Border.all(
                  color: themeProvider.textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                LucideIcons.x,
                color: themeProvider.textSecondary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Stop button (main)
          GestureDetector(
            onTap: () => provider.stopRecording(),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.square,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 80), // Balance for cancel button
        ],
      );
    }

    if (isRecorded) {
      // Show re-record button
      return Column(
        children: [
          // Play preview button would be nice but we show it on next screen
          TextButton.icon(
            onPressed: () => provider.cancelRecording(),
            icon: Icon(
              LucideIcons.refreshCcw,
              size: 18,
              color: themeProvider.textSecondary,
            ),
            label: Text(
              "Don't like it? Record again",
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    // Idle state - show record button
    return GestureDetector(
      onTap: () async {
        final hasPermission = await provider.hasRecordingPermission();
        if (!hasPermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Microphone permission is required'),
                backgroundColor: Colors.red.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return;
        }
        await provider.startRecording();
      },
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
            ),
          ],
        ),
        child: const Icon(LucideIcons.mic, color: Colors.white, size: 42),
      ),
    );
  }

  Widget _buildDurationDisplay(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: themeProvider.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 18, color: themeProvider.textSecondary),
          const SizedBox(width: 8),
          Text(
            provider.formattedRecordingTime,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: themeProvider.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Example Affirmations:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"I am confident and capable"\n"I attract success and abundance"\n"I am worthy of love and happiness"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: themeProvider.textSecondary.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
