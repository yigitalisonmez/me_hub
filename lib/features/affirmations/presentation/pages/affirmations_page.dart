import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../providers/affirmation_provider.dart';
import '../widgets/recording_widget.dart';
import '../widgets/background_picker.dart';
import '../widgets/playback_controls.dart';
import '../widgets/session_complete_page.dart';

/// Main page for the Affirmations feature
class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage> {
  bool _showCompletionPage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProvider();
    });
  }

  Future<void> _initProvider() async {
    final provider = context.read<AffirmationProvider>();
    await provider.init();
  }

  void _onSessionComplete() {
    setState(() {
      _showCompletionPage = true;
    });
  }

  void _closeCompletionPage() {
    setState(() {
      _showCompletionPage = false;
    });
    final provider = context.read<AffirmationProvider>();
    provider.clearCurrentRecording();
  }

  @override
  Widget build(BuildContext context) {
    if (_showCompletionPage) {
      return SessionCompletePage(onClose: _closeCompletionPage);
    }

    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AffirmationProvider>();

    // Check if session completed
    if (provider.playbackState != PlaybackState.idle &&
        provider.remainingDuration.inSeconds == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSessionComplete();
      });
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(themeProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.playbackState != PlaybackState.idle)
                    _buildActiveSessionView(themeProvider, provider)
                  else if (provider.recordingState == RecordingState.recorded)
                    _buildReadyToPlayContent(context, themeProvider, provider)
                  else ...[
                    _buildIntroSection(themeProvider),
                    const SizedBox(height: 24),
                    _buildHowItWorksSection(themeProvider),
                    const SizedBox(height: 32),
                    const RecordingWidget(),
                  ],

                  const SizedBox(height: 24),

                  if (provider.sessions.isNotEmpty &&
                      provider.playbackState == PlaybackState.idle)
                    _buildSavedSessions(context, themeProvider, provider),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: themeProvider.backgroundColor,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Affirmations',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeProvider.primaryColor,
                themeProvider.primaryColor.withValues(alpha: 0.8),
                themeProvider.backgroundColor,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                right: 30,
                child: Icon(
                  LucideIcons.moon,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.primaryColor.withValues(alpha: 0.15),
            themeProvider.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: themeProvider.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transform Your Mind',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'While You Sleep',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Record positive affirmations in your own voice and let them gently rewire your subconscious mind during the transition to sleep.',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(ThemeProvider themeProvider) {
    final steps = [
      {
        'icon': LucideIcons.mic,
        'title': 'Record',
        'desc': 'Speak your affirmation clearly',
      },
      {
        'icon': LucideIcons.music,
        'title': 'Choose Sound',
        'desc': 'Pick a calming background',
      },
      {
        'icon': LucideIcons.moon,
        'title': 'Sleep Loop',
        'desc': 'Listen for 30 min as you sleep',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          final step = entry.value;
          return _buildStepItem(
            themeProvider,
            icon: step['icon'] as IconData,
            title: step['title'] as String,
            description: step['desc'] as String,
            stepNumber: entry.key + 1,
            showLine: entry.key < steps.length - 1,
          );
        }),
      ],
    );
  }

  Widget _buildStepItem(
    ThemeProvider themeProvider, {
    required IconData icon,
    required String title,
    required String description,
    required int stepNumber,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 30,
                color: themeProvider.primaryColor.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: themeProvider.textSecondary),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionView(
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeProvider.primaryColor.withValues(alpha: 0.3),
                themeProvider.cardColor,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                LucideIcons.moon,
                size: 48,
                color: themeProvider.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Sleep Session Active',
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Relax and let the affirmations work',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PlaybackControls(
          onPlay: () => provider.startPlayback(),
          onPause: () => provider.pausePlayback(),
          onStop: () => provider.stopPlayback(),
        ),
      ],
    );
  }

  Widget _buildReadyToPlayContent(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording Ready!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    Text(
                      'Now choose a background sound and start your session',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recording preview card
        _buildRecordingPreviewCard(context, themeProvider, provider),

        const SizedBox(height: 24),

        // Background picker
        const BackgroundPicker(),

        const SizedBox(height: 24),

        // Tips card
        _buildTipsCard(themeProvider),

        const SizedBox(height: 24),

        // Save session button
        if (provider.currentSession == null)
          _buildSaveButton(context, themeProvider, provider),

        const SizedBox(height: 16),

        // Start session button
        _buildStartButton(context, themeProvider, provider),

        const SizedBox(height: 16),

        // Re-record button
        Center(
          child: TextButton.icon(
            onPressed: () => provider.clearCurrentRecording(),
            icon: Icon(
              LucideIcons.refreshCcw,
              size: 18,
              color: themeProvider.textSecondary,
            ),
            label: Text(
              'Record Again',
              style: TextStyle(color: themeProvider.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  /// Card to preview the recorded affirmation with progress bar
  Widget _buildRecordingPreviewCard(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final isPlaying = provider.previewingSoundId == 'recording';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isPlaying
            ? Border.all(color: themeProvider.primaryColor, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => provider.playRecordingPreview(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: themeProvider.primaryColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Recording',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.formattedRecordingTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPlaying)
                Icon(
                  LucideIcons.mic,
                  color: themeProvider.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
            ],
          ),
          // Progress bar (only when playing)
          if (isPlaying)
            StreamBuilder<Duration>(
              stream: provider.previewPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration =
                    provider.previewPlayer.duration ??
                    provider.recordingDuration;
                final progress = duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                        0.0,
                        1.0,
                      )
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: themeProvider.backgroundColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeProvider.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: themeProvider.textSecondary,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: themeProvider.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTipsCard(ThemeProvider themeProvider) {
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
              const Icon(LucideIcons.lightbulb, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Pro Tips',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(themeProvider, 'Use in the last 30 min before sleep'),
          _buildTipItem(themeProvider, 'Keep volume low but audible'),
          _buildTipItem(themeProvider, 'Be consistent for 21+ days'),
        ],
      ),
    );
  }

  Widget _buildTipItem(ThemeProvider themeProvider, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 14, color: themeProvider.primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: themeProvider.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showSaveDialog(context, themeProvider, provider),
        icon: const Icon(LucideIcons.save),
        label: const Text('Save for Later'),
        style: OutlinedButton.styleFrom(
          foregroundColor: themeProvider.primaryColor,
          side: BorderSide(color: themeProvider.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => provider.startPlayback(),
        icon: const Icon(LucideIcons.moon, color: Colors.white),
        label: const Text(
          'Start 30-Min Sleep Session',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: themeProvider.primaryColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  void _showSaveDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Save Affirmation',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: themeProvider.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g., Confidence Boost',
            hintStyle: TextStyle(color: themeProvider.textSecondary),
            filled: true,
            fillColor: themeProvider.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
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
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await provider.saveSession(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedSessions(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.folderOpen,
              size: 18,
              color: themeProvider.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Saved Affirmations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.sessions.length,
          itemBuilder: (context, index) {
            final session = provider.sessions[index];
            return _buildSessionCard(context, themeProvider, provider, session);
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
    dynamic session,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.mic,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
                Text(
                  '${session.completedSessions} sessions completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => provider.loadSession(session),
            icon: Icon(
              LucideIcons.play,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () =>
                _confirmDelete(context, themeProvider, provider, session),
            icon: Icon(
              LucideIcons.trash2,
              color: themeProvider.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ThemeProvider themeProvider,
    AffirmationProvider provider,
    dynamic session,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Affirmation?',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Text(
          '"${session.name}" will be permanently deleted.',
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
              provider.deleteSession(session.id);
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
