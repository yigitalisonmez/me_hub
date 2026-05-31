import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/mood_entry.dart';
import '../providers/mood_provider.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage>
    with AutomaticKeepAliveClientMixin {
  double _currentScore = 8;
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedFactors = {'Work', 'Sleep', 'Social'};

  static const List<String> _factors = [
    'Work',
    'Sleep',
    'Social',
    'Energy',
    'Health',
    'Weather',
  ];

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

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const PageHeader(
                title: 'Mood',
                subtitle: 'How are you feeling today?',
                showBackButton: true,
                actionIcon: LucideIcons.ellipsis,
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: moodProvider.hasTodayMood
                    ? _TodayMoodCard(
                        key: const ValueKey('today_mood'),
                        mood: moodProvider.todayMood!,
                        onReset: () async {
                          await moodProvider.deleteTodayMood();
                          if (mounted) {
                            setState(() => _currentScore = 8);
                          }
                        },
                      )
                    : _MoodEntryCard(
                        key: const ValueKey('mood_entry'),
                        score: _currentScore.toInt(),
                        noteController: _noteController,
                        selectedFactors: _selectedFactors,
                        onScoreChanged: (score) {
                          setState(() => _currentScore = score.toDouble());
                          HapticFeedback.selectionClick();
                        },
                        onFactorTap: (factor) {
                          setState(() {
                            if (_selectedFactors.contains(factor)) {
                              _selectedFactors.remove(factor);
                            } else {
                              _selectedFactors.add(factor);
                            }
                          });
                        },
                        onSave: () => _saveMood(moodProvider, themeProvider),
                      ),
              ),
              const SizedBox(height: 22),
              _WeeklyMoodCard(moods: moodProvider.allMoods),
              const SizedBox(height: 22),
              _MoodLogTimeline(moods: moodProvider.allMoods),
              SizedBox(height: LayoutConstants.getNavbarClearance(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMood(
    MoodProvider moodProvider,
    ThemeProvider themeProvider,
  ) async {
    try {
      await moodProvider.saveMood(
        score: _currentScore.toInt(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (!mounted) return;
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mood saved'),
          backgroundColor: AppColors.moodDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mood: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _MoodEntryCard extends StatelessWidget {
  final int score;
  final TextEditingController noteController;
  final Set<String> selectedFactors;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<String> onFactorTap;
  final VoidCallback onSave;

  const _MoodEntryCard({
    super.key,
    required this.score,
    required this.noteController,
    required this.selectedFactors,
    required this.onScoreChanged,
    required this.onFactorTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final level = _MoodLevel.fromScore(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formattedToday().toUpperCase(),
          style: TextStyle(
            color: AppColors.moodDeep,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How are you\nfeeling today?',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 32,
            height: 1.02,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: level.color.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: level.color.withValues(alpha: 0.20),
                      blurRadius: 38,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: level.color.withValues(alpha: 0.20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: Icon(level.icon, size: 48, color: level.deep),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                level.label,
                style: TextStyle(
                  color: level.deep,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                level.caption,
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _MoodScale(score: score, onChanged: onScoreChanged),
        const SizedBox(height: 22),
        _SectionLabel('What is shaping it'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _MoodPageState._factors.map((factor) {
            final selected = selectedFactors.contains(factor);
            return GestureDetector(
              onTap: () => onFactorTap(factor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.moodTint
                      : themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? AppColors.mood
                        : themeProvider.borderColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  factor,
                  style: TextStyle(
                    color: selected
                        ? AppColors.moodDeep
                        : themeProvider.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        _SectionLabel("Today's note"),
        const SizedBox(height: 10),
        TextField(
          controller: noteController,
          minLines: 3,
          maxLines: 5,
          style: TextStyle(color: themeProvider.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'A slow, kind start to the day...',
            hintStyle: TextStyle(
              color: themeProvider.textSecondary.withValues(alpha: 0.55),
            ),
            filled: true,
            fillColor: themeProvider.cardColor,
            contentPadding: const EdgeInsets.all(18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: themeProvider.borderColor.withValues(alpha: 0.35),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: themeProvider.borderColor.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.mood, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(LucideIcons.check, color: Colors.white, size: 18),
            label: const Text(
              'Save mood',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.moodDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formattedToday() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} · ${now.day} ${months[now.month - 1]}';
  }
}

class _MoodScale extends StatelessWidget {
  final int score;
  final ValueChanged<int> onChanged;

  const _MoodScale({required this.score, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final levels = _MoodLevel.scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: levels.map((level) {
        final selected = _MoodLevel.fromScore(score).score == level.score;
        return GestureDetector(
          onTap: () => onChanged(level.score),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 58 : 48,
            height: selected ? 58 : 48,
            decoration: BoxDecoration(
              color: selected
                  ? level.color
                  : level.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: level.color.withValues(alpha: 0.34),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              level.icon,
              color: selected ? Colors.white : level.deep,
              size: selected ? 27 : 22,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TodayMoodCard extends StatelessWidget {
  final MoodEntry mood;
  final Future<void> Function() onReset;

  const _TodayMoodCard({super.key, required this.mood, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final level = _MoodLevel.fromScore(mood.score);

    return ElevatedCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 28,
      backgroundColor: level.color.withValues(alpha: 0.13),
      borderColor: level.color.withValues(alpha: 0.20),
      child: Column(
        children: [
          Text(
            'You are feeling',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: level.color.withValues(alpha: 0.20),
            ),
            child: Icon(level.icon, color: level.deep, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            level.label,
            style: TextStyle(
              color: level.deep,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mood.note?.isNotEmpty == true ? mood.note! : level.caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(LucideIcons.rotateCcw, size: 17),
            label: const Text('Reset entry'),
            style: TextButton.styleFrom(
              foregroundColor: themeProvider.textSecondary,
              backgroundColor: themeProvider.cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyMoodCard extends StatelessWidget {
  final List<MoodEntry> moods;

  const _WeeklyMoodCard({required this.moods});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final weekScores = _weekScores(moods);
    final avg = weekScores.where((e) => e != null).toList();
    final avgText = avg.isEmpty
        ? 'no entries yet'
        : '${(avg.reduce((a, b) => a! + b!)! / avg.length).toStringAsFixed(1)}/10 avg';

    return ElevatedCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel('This week'),
              const Spacer(),
              Text(
                avgText,
                style: const TextStyle(
                  color: AppColors.moodDeep,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 88,
            child: CustomPaint(
              painter: _MoodWavePainter(weekScores, themeProvider.isDarkMode),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final score = weekScores[index];
              final level = score == null ? null : _MoodLevel.fromScore(score);
              return Column(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          level?.color ??
                          themeProvider.borderColor.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  List<int?> _weekScores(List<MoodEntry> moods) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      for (final mood in moods) {
        final d = mood.date;
        if (d.year == day.year && d.month == day.month && d.day == day.day) {
          return mood.score;
        }
      }
      return null;
    });
  }
}

class _MoodLogTimeline extends StatelessWidget {
  final List<MoodEntry> moods;

  const _MoodLogTimeline({required this.moods});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final recent = [...moods]..sort((a, b) => b.date.compareTo(a.date));
    final items = recent.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${moods.length} logs',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          ElevatedCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  color: AppColors.moodDeep.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your mood logs will appear here after your first entry.',
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final mood = entry.value;
            final level = _MoodLevel.fromScore(mood.score);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 320 + index * 80),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: level.color.withValues(alpha: 0.18),
                          ),
                          child: Icon(level.icon, color: level.deep, size: 19),
                        ),
                        if (index != items.length - 1)
                          Container(
                            width: 2,
                            height: 54,
                            color: themeProvider.borderColor.withValues(
                              alpha: 0.35,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  level.label,
                                  style: TextStyle(
                                    color: level.deep,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatLogDate(mood.date),
                                  style: TextStyle(
                                    color: themeProvider.textTertiary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (mood.note?.isNotEmpty == true) ...[
                              const SizedBox(height: 7),
                              Text(
                                mood.note!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: themeProvider.textSecondary,
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatLogDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    if (value == today) {
      return 'Today · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (value == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Text(
      text,
      style: TextStyle(
        color: themeProvider.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _MoodLevel {
  final int score;
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final Color deep;

  const _MoodLevel({
    required this.score,
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.deep,
  });

  static const scale = [
    _MoodLevel(
      score: 2,
      label: 'Awful',
      caption: 'Heavy and low.',
      icon: LucideIcons.frown,
      color: Color(0xFFB96D74),
      deep: Color(0xFF934A54),
    ),
    _MoodLevel(
      score: 4,
      label: 'Low',
      caption: 'A little tender.',
      icon: LucideIcons.meh,
      color: Color(0xFFD58A62),
      deep: Color(0xFFA9603C),
    ),
    _MoodLevel(
      score: 6,
      label: 'Okay',
      caption: 'Neutral and steady.',
      icon: LucideIcons.smile,
      color: AppColors.mood,
      deep: AppColors.moodDeep,
    ),
    _MoodLevel(
      score: 8,
      label: 'Good',
      caption: 'A calm, steady kind of good.',
      icon: LucideIcons.laugh,
      color: Color(0xFFB9BF79),
      deep: Color(0xFF788443),
    ),
    _MoodLevel(
      score: 10,
      label: 'Great',
      caption: 'Light and open.',
      icon: LucideIcons.sparkles,
      color: AppColors.routine,
      deep: AppColors.routineDeep,
    ),
  ];

  static _MoodLevel fromScore(int score) {
    if (score <= 2) return scale[0];
    if (score <= 4) return scale[1];
    if (score <= 6) return scale[2];
    if (score <= 8) return scale[3];
    return scale[4];
  }
}

class _MoodWavePainter extends CustomPainter {
  final List<int?> scores;
  final bool isDark;

  _MoodWavePainter(this.scores, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final score = scores[i] ?? 5;
      final x = size.width * (i / (scores.length - 1));
      final y = size.height - ((score / 10) * size.height * 0.82) - 8;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.mood.withValues(alpha: isDark ? 0.22 : 0.30),
            AppColors.mood.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.moodDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MoodWavePainter oldDelegate) {
    return oldDelegate.scores != scores || oldDelegate.isDark != isDark;
  }
}
