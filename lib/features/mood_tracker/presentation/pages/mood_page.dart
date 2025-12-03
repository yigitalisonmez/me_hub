import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/mood_provider.dart';
import '../widgets/mood_heatmap.dart';
import '../../../../core/widgets/page_header.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  int _selectedScore = 5; // Default to middle score

  // Slider track measurement for gradient alignment
  final GlobalKey _sliderKey = GlobalKey();
  double? _trackLeft;
  double? _trackWidth;

  // Slider constants
  static const double _thumbRadius = 10.0;
  static const double _trackHeight = 6.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moodProvider = context.read<MoodProvider>();
      moodProvider.loadTodayMood();
      moodProvider.loadAllMoods();
      _measureSliderTrack();
    });
  }

  /// Measures the slider's track position and width for gradient alignment
  void _measureSliderTrack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? renderBox =
          _sliderKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        // Slider track starts at thumbRadius and ends at width - thumbRadius
        setState(() {
          _trackLeft = _thumbRadius;
          _trackWidth = size.width - (_thumbRadius * 2);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              // Show mood entry if not entered today, otherwise show heatmap
              if (!moodProvider.hasTodayMood)
                _buildMoodEntryView(context, themeProvider, moodProvider)
              else
                _buildHeatMapView(context, themeProvider, moodProvider),
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
    return Column(
      children: [
        _buildScoreSelector(context, themeProvider),
        const SizedBox(height: 32),
        _buildSaveButton(context, themeProvider, moodProvider),
      ],
    );
  }

  Widget _buildHeatMapView(
    BuildContext context,
    ThemeProvider themeProvider,
    MoodProvider moodProvider,
  ) {
    return Column(
      children: [
        // Today's mood display
        _buildTodayMoodCard(context, themeProvider, moodProvider),
        const SizedBox(height: 24),
        // Heatmap
        const MoodHeatMap(),
      ],
    );
  }

  Widget _buildTodayMoodCard(
    BuildContext context,
    ThemeProvider themeProvider,
    MoodProvider moodProvider,
  ) {
    final todayMood = moodProvider.todayMood;
    if (todayMood == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your mood today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getColorForScore(todayMood.score),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${todayMood.score}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Score: ${todayMood.score}/10',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              await moodProvider.deleteTodayMood();
              setState(() {
                _selectedScore = 5;
              });
            },
            child: Text(
              'Change Mood',
              style: TextStyle(
                color: themeProvider.primaryColor,
                fontWeight: FontWeight.w600,
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

  Widget _buildScoreSelector(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Select your mood score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          // Score display
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _getColorForScore(_selectedScore),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$_selectedScore',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Score buttons (1-10)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(10, (index) {
              final score = index + 1;
              final isSelected = _selectedScore == score;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedScore = score;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getColorForScore(score)
                        : themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? themeProvider.primaryColor
                          : themeProvider.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : themeProvider.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    ThemeProvider themeProvider,
    MoodProvider moodProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            try {
              await moodProvider.saveMood(score: _selectedScore);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mood saved: $_selectedScore/10'),
                    backgroundColor: themeProvider.primaryColor,
                  ),
                );
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
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save Mood',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// Get color for mood score (1-10) using gradient scale
  /// 1-5: Red to White
  /// 5-10: White to Dark Green
  Color _getColorForScore(int score) {
    if (score <= 5) {
      // 1-5: Red to White
      final normalized = (score - 1) / 4.0; // 0.0 to 1.0 for scores 1-5
      return Color.lerp(
        const Color(0xFFDC2626), // Red
        Colors.white,
        normalized,
      )!;
    } else {
      // 5-10: White to Dark Green
      final normalized = (score - 5) / 5.0; // 0.0 to 1.0 for scores 5-10
      return Color.lerp(
        Colors.white,
        const Color(0xFF15803D), // Dark Green
        normalized,
      )!;
    }
  }
}
