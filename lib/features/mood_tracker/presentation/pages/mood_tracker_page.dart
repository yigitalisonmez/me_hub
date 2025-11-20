import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/theme_provider.dart';

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  int _activeMood = 1;
  bool _expanded = false;
  List<Map<String, dynamic>> _todayMoods = [];
  Map<String, dynamic>? _lastMood;

  final List<_MoodProfile> _moods = const [
    _MoodProfile(
      title: 'Happy',
      subtitle: 'Feeling great and positive',
      emoji: '😊',
      gradient: [Color(0xFFFFD93D), Color(0xFFFFB347)],
    ),
    _MoodProfile(
      title: 'Calm',
      subtitle: 'Peaceful and relaxed',
      emoji: '😌',
      gradient: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
    ),
    _MoodProfile(
      title: 'Energetic',
      subtitle: 'Full of energy and ready',
      emoji: '⚡',
      gradient: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    ),
    _MoodProfile(
      title: 'Tired',
      subtitle: 'Feeling exhausted',
      emoji: '😴',
      gradient: [Color(0xFF95A5A6), Color(0xFF7F8C8D)],
    ),
    _MoodProfile(
      title: 'Anxious',
      subtitle: 'Feeling worried or stressed',
      emoji: '😰',
      gradient: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
    ),
    _MoodProfile(
      title: 'Sad',
      subtitle: 'Feeling down or low',
      emoji: '😢',
      gradient: [Color(0xFF6C9BCF), Color(0xFF5D8AA8)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _loadTodayMoods();
    _loadLastMood();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat(reverse: true);
    }
  }

  void _cycleMood() {
    setState(() {
      _activeMood = (_activeMood + 1) % _moods.length;
      _expanded = !_expanded;
    });
  }

  Future<void> _loadTodayMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayKey = 'mood_today_$today';
      final moodsJson = prefs.getString(todayKey);

      if (moodsJson != null) {
        final List<dynamic> decoded = json.decode(moodsJson);
        setState(() {
          _todayMoods = decoded.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading today moods: $e');
    }
  }

  Future<void> _loadLastMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMoodJson = prefs.getString('mood_last');

      if (lastMoodJson != null) {
        setState(() {
          _lastMood = json.decode(lastMoodJson) as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error loading last mood: $e');
    }
  }

  Future<void> _logMood() async {
    try {
      final mood = _moods[_activeMood];
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('HH:mm').format(now);

      final moodData = {
        'title': mood.title,
        'emoji': mood.emoji,
        'time': time,
        'timestamp': now.toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();

      // Save to today's moods
      final todayKey = 'mood_today_$today';
      final existingMoodsJson = prefs.getString(todayKey);
      List<Map<String, dynamic>> todayMoods = [];

      if (existingMoodsJson != null) {
        final List<dynamic> decoded = json.decode(existingMoodsJson);
        todayMoods = decoded.cast<Map<String, dynamic>>();
      }

      todayMoods.insert(0, moodData);
      await prefs.setString(todayKey, json.encode(todayMoods));

      // Save as last mood
      await prefs.setString('mood_last', json.encode(moodData));

      // Update state
      setState(() {
        _todayMoods = todayMoods;
        _lastMood = moodData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mood logged: ${mood.title}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error logging mood: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log mood: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                _LiquidBackdrop(
                  controller: _controller,
                  themeProvider: themeProvider,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(themeProvider),
                    Expanded(
                      child: Center(
                        child: _buildMorphingCard(constraints, themeProvider),
                      ),
                    ),
                    _buildMeltedActions(themeProvider),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Tracker',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (_lastMood != null)
                  Row(
                    children: [
                      Text(
                        _lastMood!['emoji'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last: ${_lastMood!['title']} at ${_lastMood!['time']}',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Track your emotional well-being',
                    style: TextStyle(color: themeProvider.textSecondary),
                  ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.1),
              border: Border.all(color: themeProvider.borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_todayMoods.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                ),
                Text(
                  'today',
                  style: TextStyle(
                    fontSize: 10,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorphingCard(
    BoxConstraints constraints,
    ThemeProvider themeProvider,
  ) {
    final mood = _moods[_activeMood];
    final targetWidth = _expanded ? constraints.maxWidth - 40 : 360.0;
    final targetHeight = _expanded ? 460.0 : 360.0;
    final borderRadius = BorderRadius.circular(_expanded ? 48 : 28);

    return GestureDetector(
      onTap: _cycleMood,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
        width: targetWidth,
        height: targetHeight,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: themeProvider.primaryColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Semantics(
          label:
              'Current mood: ${mood.title}. ${mood.subtitle}. Double tap to cycle to next mood.',
          button: true,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      mood.gradient.first.withValues(alpha: 0.9),
                      mood.gradient.last.withValues(
                        alpha: _expanded ? 0.8 : 0.7,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: themeProvider.borderColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 42)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                mood.title,
                                key: ValueKey(mood.title),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.textPrimary,
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                mood.subtitle,
                                key: ValueKey(mood.subtitle),
                                style: TextStyle(
                                  color: themeProvider.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: _LiquidWave(
                        animation: _controller,
                        color: themeProvider.primaryColor.withValues(
                          alpha: 0.7,
                        ),
                        accent: themeProvider.textPrimary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      child: _expanded
                          ? _buildExpandedPanel(themeProvider)
                          : _buildCompactPanel(themeProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPanel(ThemeProvider themeProvider) {
    if (_todayMoods.isEmpty) {
      return Center(
        child: Text(
          'No moods logged today',
          style: TextStyle(
            color: themeProvider.textSecondary,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Show last 3 moods
    final recentMoods = _todayMoods.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Moods',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentMoods.map((mood) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeProvider.borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mood['emoji'] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mood['time'] as String,
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpandedPanel(ThemeProvider themeProvider) {
    if (_todayMoods.isEmpty) {
      return Center(
        child: Text(
          'Log your first mood to see your daily pattern',
          style: TextStyle(
            color: themeProvider.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Count mood frequencies
    final moodCounts = <String, int>{};
    for (var mood in _todayMoods) {
      final title = mood['title'] as String;
      moodCounts[title] = (moodCounts[title] ?? 0) + 1;
    }

    final mostCommon = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Pattern',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (mostCommon.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: _ArcPill(
                  label: 'Most Common',
                  value: '${mostCommon.first.key} (${mostCommon.first.value}x)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ArcPill(
                  label: 'Total Logs',
                  value: '${_todayMoods.length}',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Tap to cycle through moods',
          style: TextStyle(color: themeProvider.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMeltedActions(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _MeltedButton(
        config: _ActionButtonConfig(
          label: 'Log Mood',
          icon: LucideIcons.penTool,
        ),
        controller: _controller,
        highlightColor: themeProvider.primaryColor,
        isPrimary: true,
        onTap: _logMood,
      ),
    );
  }
}

class _LiquidBackdrop extends StatelessWidget {
  final AnimationController controller;
  final ThemeProvider themeProvider;

  const _LiquidBackdrop({
    required this.controller,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;
        return Stack(
          children: [
            _Blob(
              color: themeProvider.primaryColor.withValues(alpha: 0.12),
              alignment: Alignment(
                math.sin(progress * math.pi * 2) * 0.7,
                -0.8 + progress * 0.1,
              ),
              size: 220 + 80 * progress,
            ),
            _Blob(
              color: themeProvider.textSecondary.withValues(alpha: 0.12),
              alignment: Alignment(-0.6 + progress * 0.6, 0.8 - progress * 0.3),
              size: 260 - 40 * progress,
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  final double size;

  const _Blob({
    required this.color,
    required this.alignment,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPill extends StatelessWidget {
  final String label;
  final String value;

  const _ArcPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeltedButton extends StatelessWidget {
  final _ActionButtonConfig config;
  final AnimationController controller;
  final Color highlightColor;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _MeltedButton({
    required this.config,
    required this.controller,
    required this.highlightColor,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final wobble = (math.sin(controller.value * 2 * math.pi) + 1) / 2;
        final radius = 22 + (wobble * 6);
        final scale = 0.96 + wobble * 0.04;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    if (isPrimary)
                      highlightColor.withValues(alpha: 0.9)
                    else
                      highlightColor.withValues(alpha: 0.15),
                    if (isPrimary)
                      highlightColor.withValues(alpha: 0.7)
                    else
                      highlightColor.withValues(alpha: 0.25),
                  ],
                ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isPrimary
                      ? highlightColor
                      : highlightColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: highlightColor.withValues(
                      alpha: isPrimary ? 0.2 : 0.1,
                    ),
                    blurRadius: isPrimary ? 16 : 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    config.icon,
                    color: isPrimary ? Colors.white : highlightColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    config.label,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : highlightColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiquidWave extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final Color accent;

  const _LiquidWave({
    required this.animation,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            progress: animation.value,
            color: color,
            accent: accent,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accent;

  _WavePainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final path2 = Path();
    final amplitude = size.height * 0.35;
    final baseHeight = size.height / 2;

    for (double x = 0; x <= size.width; x += 1) {
      final normalized = x / size.width;
      final y =
          baseHeight +
          math.sin((normalized * 3 * math.pi) + progress * 2 * math.pi) *
              amplitude;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      final y2 =
          baseHeight +
          math.cos((normalized * 2.5 * math.pi) + progress * math.pi) *
              amplitude *
              0.6;
      if (x == 0) {
        path2.moveTo(x, y2);
      } else {
        path2.lineTo(x, y2);
      }
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint2 = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.accent != accent;
  }
}

class _MoodProfile {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;

  const _MoodProfile({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
  });
}

class _ActionButtonConfig {
  final String label;
  final IconData icon;

  const _ActionButtonConfig({required this.label, required this.icon});
}
