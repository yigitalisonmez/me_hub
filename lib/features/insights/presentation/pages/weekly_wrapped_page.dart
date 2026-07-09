import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/insights_data_service.dart';
import '../../domain/entities/weekly_wrapped_data.dart';

/// Weekly Wrapped: a full-screen, auto-advancing story of the past week,
/// mirroring the redesign board's WrappedStory (tap zones, swipe, progress
/// segments, share on the last slide).
class WeeklyWrappedPage extends StatefulWidget {
  const WeeklyWrappedPage({super.key});

  @override
  State<WeeklyWrappedPage> createState() => _WeeklyWrappedPageState();
}

class _WeeklyWrappedPageState extends State<WeeklyWrappedPage> {
  static const _slideDuration = Duration(seconds: 5);

  WeeklyWrappedData? _data;
  int _index = 0;

  /// Bumped on every manual navigation so the progress animation restarts.
  int _run = 0;
  Timer? _timer;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    InsightsDataService().loadWeeklyWrapped().then((data) {
      if (!mounted) return;
      setState(() => _data = data);
      _armTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_WrappedSlide> get _slides => _buildSlides(_data!);

  void _armTimer() {
    _timer?.cancel();
    if (_data == null || _index >= _slides.length - 1) return;
    _timer = Timer(_slideDuration, () => _go(1));
  }

  void _go(int delta) {
    if (_data == null) return;
    final next = (_index + delta).clamp(0, _slides.length - 1);
    if (next == _index) return;
    setState(() {
      _index = next;
      _run++;
    });
    _armTimer();
  }

  void _share() {
    final data = _data!;
    final liters = data.totalWaterLiters.toStringAsFixed(1);
    SharePlus.instance.share(
      ShareParams(
        text:
            'My week with Kora: $liters L of water, '
            '${data.tasksCompleted} tasks done, '
            '${data.mindfulSessions} mindful sessions, '
            'and a ${data.currentStreak}-day streak.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1916),
        body: data == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : _story(data),
      ),
    );
  }

  Widget _story(WeeklyWrappedData data) {
    final slides = _slides;
    final slide = slides[_index];

    return GestureDetector(
      onHorizontalDragStart: (d) => _dragStartX = d.globalPosition.dx,
      onHorizontalDragUpdate: (d) {
        final delta = d.globalPosition.dx - _dragStartX;
        if (delta.abs() > 60) {
          _dragStartX = d.globalPosition.dx;
          _go(delta < 0 ? 1 : -1);
        }
      },
      child: Stack(
        children: [
          // Background gradient per slide.
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            decoration: BoxDecoration(gradient: slide.gradient),
          ),
          // Tap zones: left third back, rest forward.
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(-1),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(1),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _progressRow(slides.length),
                  const SizedBox(height: 14),
                  _header(slide),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(_index),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [slide.body],
                      ),
                    ),
                  ),
                  if (slide.isLast) _cta(),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressRow(int count) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
              child: i < _index
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    )
                  : i == _index
                  ? TweenAnimationBuilder<double>(
                      key: ValueKey('$_index-$_run'),
                      tween: Tween(begin: 0, end: 1),
                      duration: _index == _slides.length - 1
                          ? Duration.zero
                          : _slideDuration,
                      builder: (context, value, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _index == _slides.length - 1 ? 1 : value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }

  Widget _header(_WrappedSlide slide) {
    return Row(
      children: [
        Expanded(
          child: Text(
            slide.kick,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              LucideIcons.x,
              color: Colors.white.withValues(alpha: 0.75),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cta() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _go(-1),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            label: const Text(
              'Back',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _share,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF423A31),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(LucideIcons.share, size: 16),
            label: const Text(
              'Share',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- slide data

  List<_WrappedSlide> _buildSlides(WeeklyWrappedData data) {
    final name = data.userName.isEmpty ? 'friend' : data.userName;
    final range = _rangeLabel(data.weekStart, data.weekEnd);
    final liters = data.totalWaterLiters.toStringAsFixed(1);

    return [
      _WrappedSlide(
        gradient: _gradient(const Color(0xFFC9714F), const Color(0xFF8C4A31)),
        kick: 'YOUR WEEK · $range',
        body: _SlideBody(
          art: Image.asset(
            'assets/images/home_page_character.png',
            width: 130,
            fit: BoxFit.contain,
          ),
          eyebrow: 'Weekly wrapped',
          huge: 'What a week, $name.',
          line: data.hasAnyData
              ? 'Tap through to see your highlights.'
              : 'A quiet week — next Sunday can shine brighter.',
        ),
      ),
      _WrappedSlide(
        gradient: _gradient(const Color(0xFF4E84AA), const Color(0xFF2E5670)),
        kick: 'HYDRATION',
        body: _SlideBody(
          eyebrow: 'You drank',
          huge: '$liters L',
          hugeSmall: 'of water this week',
          extra: _WaterBars(byDayMl: data.waterByDayMl),
          line: data.bestWaterDay != null
              ? '${_dayNames[data.bestWaterDay!]} was your best day — '
                    '${(data.waterByDayMl[data.bestWaterDay!] / 1000).toStringAsFixed(1)} L.'
              : 'No water logged this week — small sips count too.',
        ),
      ),
      _WrappedSlide(
        gradient: _gradient(const Color(0xFF6E895B), const Color(0xFF44573A)),
        kick: 'PRODUCTIVITY',
        body: _SlideBody(
          eyebrow: 'You completed',
          huge: '${data.tasksCompleted}',
          hugeSmall: data.mindfulSessions > 0
              ? 'tasks & ${data.mindfulSessions} mindful sessions'
              : 'tasks this week',
          line: data.morningTaskShare != null && data.morningTaskShare! >= 0.5
              ? 'Mornings are your superpower — '
                    '${(data.morningTaskShare! * 100).round()}% of tasks done before noon.'
              : data.tasksCompleted > 0
              ? 'Every checked box is momentum. Nice work.'
              : 'A fresh week of tasks awaits.',
        ),
      ),
      _WrappedSlide(
        gradient: _gradient(const Color(0xFFC9912F), const Color(0xFF8A5F1B)),
        kick: 'MOOD',
        body: _SlideBody(
          eyebrow: 'Your mood trended',
          huge: switch (data.moodTrend) {
            MoodTrend.up => 'Up ↗',
            MoodTrend.down => 'Down ↘',
            MoodTrend.steady => 'Steady →',
            MoodTrend.unknown => 'Unwritten',
          },
          hugeSmall: data.moodTrend == MoodTrend.unknown
              ? 'log moods to see your trend'
              : null,
          line: data.moodWaterBoostPercent != null
              ? 'On days you logged water, your mood was '
                    '${data.moodWaterBoostPercent}% brighter.'
              : 'Checking in with yourself is its own win.',
        ),
      ),
      _WrappedSlide(
        gradient: _gradient(const Color(0xFF7C70AC), const Color(0xFF4E4472)),
        kick: 'STREAK',
        isLast: true,
        body: _SlideBody(
          eyebrow: data.currentStreak > 0 ? 'You’re on a' : 'Your streak',
          huge: data.currentStreak > 0
              ? '${data.currentStreak}-day streak'
              : 'starts today',
          hugeSmall: data.bestStreak > data.currentStreak
              ? 'your best is ${data.bestStreak} days'
              : data.currentStreak > 0
              ? 'your longest yet'
              : null,
          line: 'See you next Sunday for the next one.',
        ),
      ),
    ];
  }

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _monthNames = [
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

  static String _rangeLabel(DateTime start, DateTime end) {
    final startLabel = '${_monthNames[start.month - 1]} ${start.day}'
        .toUpperCase();
    final endLabel = '${_monthNames[end.month - 1]} ${end.day}'.toUpperCase();
    return '$startLabel – $endLabel';
  }

  static LinearGradient _gradient(Color from, Color to) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [from, to],
  );
}

class _WrappedSlide {
  final LinearGradient gradient;
  final String kick;
  final Widget body;
  final bool isLast;

  const _WrappedSlide({
    required this.gradient,
    required this.kick,
    required this.body,
    this.isLast = false,
  });
}

class _SlideBody extends StatelessWidget {
  final Widget? art;
  final String eyebrow;
  final String huge;
  final String? hugeSmall;
  final Widget? extra;
  final String line;

  const _SlideBody({
    this.art,
    required this.eyebrow,
    required this.huge,
    this.hugeSmall,
    this.extra,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (art != null) ...[art!, const SizedBox(height: 18)],
        Text(
          eyebrow,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          huge,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        if (hugeSmall != null) ...[
          const SizedBox(height: 6),
          Text(
            hugeSmall!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (extra != null) ...[const SizedBox(height: 22), extra!],
        const SizedBox(height: 18),
        Text(
          line,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Seven relative bars for the hydration slide, highlighting the best day.
class _WaterBars extends StatelessWidget {
  final List<int> byDayMl;

  const _WaterBars({required this.byDayMl});

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxMl = byDayMl.fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++) ...[
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: maxMl == 0
                        ? 0.06
                        : (byDayMl[i] / maxMl).clamp(0.06, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: byDayMl[i] == maxMl && maxMl > 0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                if (i != 6) const SizedBox(width: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              Expanded(
                child: Text(
                  _letters[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (i != 6) const SizedBox(width: 7),
            ],
          ],
        ),
      ],
    );
  }
}
