import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/mood_provider.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/page_header.dart';
import '../utils/mood_utils.dart';
import '../widgets/weekly_mood_trend.dart';
import '../widgets/mood_history_list.dart';
import '../../../analytics/presentation/widgets/analysis_card.dart';
import '../../../../core/widgets/elevated_card.dart';

enum _MoodStep { score, note }

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  double _currentScore = 5.0;
  _MoodStep _currentStep = _MoodStep.score;
  final TextEditingController _noteController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moodProvider = context.read<MoodProvider>();
      moodProvider.loadTodayMood();
      moodProvider.loadAllMoods();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();
    final moodProvider = context.watch<MoodProvider>();

    return Container(
      decoration: BoxDecoration(color: themeProvider.backgroundColor),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 32),
              if (!moodProvider.hasTodayMood)
                _buildMoodEntryView(context, themeProvider, moodProvider)
              else
                _buildTodayMoodCard(context, themeProvider, moodProvider),
              const SizedBox(height: 32),
              const AnalysisCard(),
              const WeeklyMoodTrend(),
              const SizedBox(height: 32),
              const MoodHistoryList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodEntryView(
    BuildContext context,
    ThemeProvider themeProvider,
    MoodProvider moodProvider,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _currentStep == _MoodStep.score
          ? _buildScoreStep(context, themeProvider)
          : _buildNoteStep(context, themeProvider, moodProvider),
    );
  }

  Widget _buildScoreStep(BuildContext context, ThemeProvider themeProvider) {
    final color = MoodUtils.getColorForScore(_currentScore.toInt());
    final icon = MoodUtils.getIconForScore(_currentScore.toInt());
    final label = MoodUtils.getLabelForScore(_currentScore.toInt());

    return ElevatedCard(
      key: const ValueKey('score_step'),
      borderRadius: 32,
      child: Column(
        children: [
          // Animated Icon and Score
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(icon, key: ValueKey(icon), size: 48, color: color),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Label and Score
          Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentScore.toInt()}/10',
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Premium Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: themeProvider.borderColor,
              thumbColor: Colors.white,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: _RingThumbShape(
                enabledThumbRadius: 14,
                ringColor: color,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
            ),
            child: Slider(
              value: _currentScore,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                if (val != _currentScore) {
                  setState(() => _currentScore = val);
                  HapticFeedback.selectionClick();
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                'High',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = _MoodStep.note;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteStep(
    BuildContext context,
    ThemeProvider themeProvider,
    MoodProvider moodProvider,
  ) {
    final color = MoodUtils.getColorForScore(_currentScore.toInt());
    final icon = MoodUtils.getIconForScore(_currentScore.toInt());

    return ElevatedCard(
      key: const ValueKey('note_step'),
      borderRadius: 32,
      child: Column(
        children: [
          // Selected Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, size: 32, color: color)),
          ),
          const SizedBox(height: 24),
          Text(
            "What's on your mind?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a note to remember this moment',
            style: TextStyle(fontSize: 16, color: themeProvider.textSecondary),
          ),
          const SizedBox(height: 32),
          // Note Input
          TextField(
            controller: _noteController,
            maxLines: 4,
            style: TextStyle(color: themeProvider.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Type your thoughts...',
              hintStyle: TextStyle(
                color: themeProvider.textSecondary.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: themeProvider.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: themeProvider.primaryColor,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 32),
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await moodProvider.saveMood(
                    score: _currentScore.toInt(),
                    note: _noteController.text.trim().isEmpty
                        ? null
                        : _noteController.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mood saved successfully'),
                        backgroundColor: themeProvider.primaryColor,
                      ),
                    );
                    // Reset state
                    setState(() {
                      _currentStep = _MoodStep.score;
                      _noteController.clear();
                      _currentScore = 5.0;
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving mood: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Save Mood',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Back Button
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = _MoodStep.score;
              });
            },
            child: Text(
              'Back',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMoodCard(
    BuildContext context,
    ThemeProvider themeProvider,
    MoodProvider moodProvider,
  ) {
    final todayMood = moodProvider.todayMood;
    if (todayMood == null) return const SizedBox.shrink();

    final color = MoodUtils.getColorForScore(todayMood.score);
    final icon = MoodUtils.getIconForScore(todayMood.score);
    final label = MoodUtils.getLabelForScore(todayMood.score);

    return ElevatedCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'You are feeling',
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, size: 40, color: color)),
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${todayMood.score}/10',
            style: TextStyle(
              fontSize: 18,
              color: themeProvider.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () async {
              await moodProvider.deleteTodayMood();
              setState(() {
                _currentScore = 5.0;
              });
            },
            icon: Icon(
              LucideIcons.rotateCcw,
              size: 18,
              color: themeProvider.textSecondary,
            ),
            label: Text(
              'Reset Entry',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: themeProvider.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const PageHeader(
      title: 'Mood Tracker',
      subtitle: 'How are you feeling today?',
      actionIcon: LucideIcons.heart,
    );
  }
}

class _RingThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final Color ringColor;

  const _RingThumbShape({
    required this.enabledThumbRadius,
    required this.ringColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw white background
    canvas.drawCircle(
      center,
      enabledThumbRadius,
      Paint()..color = Colors.white,
    );

    // Draw colored ring
    canvas.drawCircle(
      center,
      enabledThumbRadius - 2,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
}
