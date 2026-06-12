import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                        insight: _buildMoodInsight(moodProvider.allMoods),
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

  String _buildMoodInsight(List<MoodEntry> moods) {
    final recent = [...moods]..sort((a, b) => b.date.compareTo(a.date));
    final sample = recent.take(5).toList();
    if (sample.isEmpty) {
      return 'Your check-in is a useful beginning. Patterns grow with time.';
    }
    if (sample.length == 1) {
      return 'Your first check-in is a useful beginning. Patterns grow with time.';
    }

    final goodDays = sample.where((entry) => entry.score >= 7).length;
    if (goodDays > 0) {
      return '$goodDays of your last ${sample.length} check-ins felt good or brighter.';
    }

    final average =
        sample.fold<int>(0, (total, entry) => total + entry.score) /
        sample.length;
    return 'Your recent average is ${average.toStringAsFixed(1)}/10. Keep checking in gently.';
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
              _PulsingMoodOrb(level: level),
              const SizedBox(height: 14),
              _AnimatedMoodCopy(level: level),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _MoodScale(score: score, onChanged: onScoreChanged),
        const SizedBox(height: 16),
        Divider(
          height: 1,
          color: themeProvider.borderColor.withValues(alpha: 0.28),
        ),
        const SizedBox(height: 14),
        _SectionLabel("What's shaping it"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _MoodPageState._factors.map((factor) {
            final selected = selectedFactors.contains(factor);
            return _MoodFactorChip(
              label: factor,
              selected: selected,
              onTap: () => onFactorTap(factor),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel("Today's note"),
                const SizedBox(height: 10),
                _MoodNoteInput(noteController: noteController),
              ],
            ),
            Positioned(
              top: -18,
              right: 0,
              child: _MoodSaveButton(onPressed: onSave),
            ),
          ],
        ),
        const SizedBox(height: 24),
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

class _AnimatedMoodCopy extends StatelessWidget {
  final _MoodLevel level;

  const _AnimatedMoodCopy({required this.level});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(level.score),
        children: [
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
    );
  }
}

class _MoodFactorChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoodFactorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MoodFactorChip> createState() => _MoodFactorChipState();
}

class _MoodFactorChipState extends State<_MoodFactorChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.moodTint
                : themeProvider.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected
                  ? AppColors.mood
                  : themeProvider.borderColor.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected
                  ? AppColors.moodDeep
                  : themeProvider.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodNoteInput extends StatelessWidget {
  final TextEditingController noteController;

  const _MoodNoteInput({required this.noteController});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      height: 94,
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.borderColor.withValues(alpha: 0.28),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 9,
            child: Text(
              '“',
              style: TextStyle(
                color: AppColors.mood.withValues(alpha: 0.62),
                fontSize: 31,
                height: 0.9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned.fill(
            child: TextField(
              controller: noteController,
              keyboardType: TextInputType.multiline,
              minLines: null,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 14.5,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
              decoration: InputDecoration(
                hintText: 'A slow, kind start to the day...',
                hintStyle: TextStyle(
                  color: themeProvider.textSecondary.withValues(alpha: 0.50),
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(22, 18, 18, 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MoodSaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Save mood',
      child: Material(
        color: AppColors.mood,
        elevation: 10,
        shadowColor: AppColors.moodDeep.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(LucideIcons.plus, color: Colors.white, size: 27),
          ),
        ),
      ),
    );
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
        return _PulsingMoodButton(
          key: ValueKey(level.score),
          level: level,
          selected: selected,
          onTap: () => onChanged(level.score),
        );
      }).toList(),
    );
  }
}

class _TodayMoodCard extends StatelessWidget {
  final MoodEntry mood;
  final String insight;
  final Future<void> Function() onReset;

  const _TodayMoodCard({
    super.key,
    required this.mood,
    required this.insight,
    required this.onReset,
  });

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
            child: _MoodFaceWidget(level: level, size: 44),
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
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: themeProvider.cardColor.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: level.color.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: level.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: level.deep,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                          child: _MoodFaceWidget(level: level, size: 19),
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
  final String mouthPath;
  final Color color;
  final Color deep;

  const _MoodLevel({
    required this.score,
    required this.label,
    required this.caption,
    required this.mouthPath,
    required this.color,
    required this.deep,
  });

  static const scale = [
    _MoodLevel(
      score: 2,
      label: 'Awful',
      caption: 'Heavy and low.',
      mouthPath: 'M8.4 16c1-1.6 2.3-2.2 3.6-2.2s2.6.6 3.6 2.2',
      color: Color(0xFFB96D74),
      deep: Color(0xFF934A54),
    ),
    _MoodLevel(
      score: 4,
      label: 'Low',
      caption: 'A little tender.',
      mouthPath: 'M8.8 15.4c.9-1 1.9-1.4 3.2-1.4s2.3.4 3.2 1.4',
      color: Color(0xFFD58A62),
      deep: Color(0xFFA9603C),
    ),
    _MoodLevel(
      score: 6,
      label: 'Okay',
      caption: 'Neutral and steady.',
      mouthPath: 'M8.8 15h6.4',
      color: AppColors.mood,
      deep: AppColors.moodDeep,
    ),
    _MoodLevel(
      score: 8,
      label: 'Good',
      caption: 'A calm, steady kind of good.',
      mouthPath: 'M8.8 14.7c.9 1.1 1.9 1.6 3.2 1.6s2.3-.5 3.2-1.6',
      color: Color(0xFFB9BF79),
      deep: Color(0xFF788443),
    ),
    _MoodLevel(
      score: 10,
      label: 'Great',
      caption: 'Light and open.',
      mouthPath: 'M8.4 14.2c1 1.7 2.3 2.3 3.6 2.3s2.6-.6 3.6-2.3',
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

String _colorHex(Color c) {
  final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

class _MoodFaceWidget extends StatelessWidget {
  final _MoodLevel level;
  final double size;
  final Color? overrideColor;

  const _MoodFaceWidget({
    required this.level,
    this.size = 26,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    final hex = _colorHex(overrideColor ?? level.deep);
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" width="24" height="24" fill="none"'
      ' stroke="$hex" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">'
      '<circle cx="9" cy="10" r="1.05" fill="$hex" stroke="none"/>'
      '<circle cx="15" cy="10" r="1.05" fill="$hex" stroke="none"/>'
      '<path d="${level.mouthPath}"/>'
      '</svg>',
      width: size,
      height: size,
    );
  }
}

class _PulsingMoodOrb extends StatefulWidget {
  final _MoodLevel level;

  const _PulsingMoodOrb({required this.level});

  @override
  State<_PulsingMoodOrb> createState() => _PulsingMoodOrbState();
}

class _PulsingMoodOrbState extends State<_PulsingMoodOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _faceController;
  late Animation<double> _faceAnimation;
  late Animation<double> _faceOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _faceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1,
    );
    _faceAnimation = CurvedAnimation(
      parent: _faceController,
      curve: Curves.easeOutBack,
    );
    _faceOpacity = CurvedAnimation(
      parent: _faceController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant _PulsingMoodOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level.score != widget.level.score) {
      _faceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _faceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size.square(160),
                painter: _MoodPulsePainter(
                  progress: _pulseController.value,
                  color: widget.level.color,
                ),
              );
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0, -0.24),
                colors: [
                  Color.alphaBlend(
                    widget.level.color.withValues(alpha: 0.26),
                    themeProvider.cardColor,
                  ),
                  themeProvider.cardColor,
                ],
              ),
              border: Border.all(
                color: themeProvider.borderColor.withValues(alpha: 0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.level.color.withValues(alpha: 0.20),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Center(
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.6,
                  end: 1,
                ).animate(_faceAnimation),
                child: FadeTransition(
                  opacity: _faceOpacity,
                  child: _MoodFaceWidget(level: widget.level, size: 60),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodPulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _MoodPulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = (progress / 0.7).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(normalized);
    final opacity = 0.40 * (1 - eased);
    if (opacity <= 0) return;

    canvas.drawCircle(
      size.center(Offset.zero),
      66 + (22 * eased),
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MoodPulsePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _PulsingMoodButton extends StatefulWidget {
  final _MoodLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _PulsingMoodButton({
    super.key,
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PulsingMoodButton> createState() => _PulsingMoodButtonState();
}

class _PulsingMoodButtonState extends State<_PulsingMoodButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Center(
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.9 : (widget.selected ? 1.04 : 1),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: widget.selected ? 56 : 46,
              height: widget.selected ? 56 : 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected
                    ? widget.level.color
                    : widget.level.color.withValues(alpha: 0.18),
                border: Border.all(
                  color: widget.selected
                      ? Colors.transparent
                      : widget.level.color.withValues(alpha: 0.22),
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: widget.level.color.withValues(alpha: 0.34),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _MoodFaceWidget(
                  level: widget.level,
                  size: widget.selected ? 26 : 22,
                  overrideColor: widget.selected ? Colors.white : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
