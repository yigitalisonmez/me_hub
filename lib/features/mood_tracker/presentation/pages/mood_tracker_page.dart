import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  int _currentStep = 0;
  int? _selectedMood;
  int _energyLevel = 5;
  final _noteController = TextEditingController();
  Map<String, dynamic>? _todayMood;
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
    _loadTodayMood();
    _loadLastMood();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _noteController.dispose();
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

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedMood == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a mood')));
        return;
      }
    } else if (_currentStep == 2) {
      // Final step - log the mood
      _logMood();
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _loadTodayMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayKey = 'mood_today_$today';
      final moodJson = prefs.getString(todayKey);

      if (moodJson != null) {
        final decoded = json.decode(moodJson) as Map<String, dynamic>;
        setState(() {
          _todayMood = decoded;
          // Set selected mood to match today's mood
          final moodTitle = decoded['title'] as String;
          final moodIndex = _moods.indexWhere((m) => m.title == moodTitle);
          if (moodIndex != -1) {
            _selectedMood = moodIndex;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading today mood: $e');
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
    // Check if mood already logged today
    if (_todayMood != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have already logged your mood today',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_selectedMood == null) return;

    try {
      final mood = _moods[_selectedMood!];
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('HH:mm').format(now);

      final moodData = {
        'title': mood.title,
        'emoji': mood.emoji,
        'time': time,
        'energyLevel': _energyLevel,
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'timestamp': now.toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();

      // Save today's mood (only one per day)
      final todayKey = 'mood_today_$today';
      await prefs.setString(todayKey, json.encode(moodData));

      // Save as last mood
      await prefs.setString('mood_last', json.encode(moodData));

      // Update state
      setState(() {
        _todayMood = moodData;
        _lastMood = moodData;
        _currentStep = 0; // Reset to first step
        _selectedMood = null;
        _energyLevel = 5;
        _noteController.clear();
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

    // If mood already logged today, show the logged mood view
    if (_todayMood != null) {
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
                          child: _buildLoggedMoodCard(
                            constraints,
                            themeProvider,
                          ),
                        ),
                      ),
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

    // Stepper view for logging new mood
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            _LiquidBackdrop(
              controller: _controller,
              themeProvider: themeProvider,
            ),
            Column(
              children: [
                _buildStepperHeader(themeProvider),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutCubic;

                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));

                          var offsetAnimation = animation.drive(tween);
                          var fadeAnimation = Tween(
                            begin: 0.0,
                            end: 1.0,
                          ).chain(CurveTween(curve: curve)).animate(animation);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: fadeAnimation,
                              child: child,
                            ),
                          );
                        },
                    child: _currentStep == 0
                        ? _buildStep1(key: const ValueKey('step1'))
                        : _currentStep == 1
                        ? _buildStep2(key: const ValueKey('step2'))
                        : _buildStep3(key: const ValueKey('step3')),
                  ),
                ),
                _buildStepperButtons(themeProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _previousStep,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeProvider.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.arrowLeft,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                  ),
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: Center(
                  child: Text(
                    'Log Your Mood',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(themeProvider),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeProvider themeProvider) {
    return Row(
      children: List.generate(3, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;

        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? themeProvider.primaryColor
                  : themeProvider.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepperButtons(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: themeProvider.borderColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(color: themeProvider.textPrimary),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Complete' : 'Next',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1({Key? key}) {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your current mood',
            style: TextStyle(fontSize: 16, color: themeProvider.textSecondary),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(_moods.length, (index) {
              final mood = _moods[index];
              final isSelected = _selectedMood == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? mood.gradient
                          : [
                              mood.gradient.first.withValues(alpha: 0.3),
                              mood.gradient.last.withValues(alpha: 0.3),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? themeProvider.primaryColor
                          : themeProvider.borderColor,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeProvider.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood.emoji,
                        style: TextStyle(fontSize: isSelected ? 36 : 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mood.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : themeProvider.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2({Key? key}) {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Energy Level',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rate your energy from 0 to 10',
            style: TextStyle(fontSize: 16, color: themeProvider.textSecondary),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '$_energyLevel',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildEnergySlider(themeProvider),
          const SizedBox(height: 40),
          _buildEnergyColors(themeProvider),
        ],
      ),
    );
  }

  Widget _buildEnergySlider(ThemeProvider themeProvider) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: themeProvider.primaryColor,
        inactiveTrackColor: themeProvider.textSecondary.withValues(alpha: 0.3),
        thumbColor: themeProvider.primaryColor,
        overlayColor: themeProvider.primaryColor.withValues(alpha: 0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        trackHeight: 4,
      ),
      child: Slider(
        value: _energyLevel.toDouble(),
        min: 0,
        max: 10,
        divisions: 10,
        label: '$_energyLevel',
        onChanged: (value) {
          setState(() {
            _energyLevel = value.round();
          });
        },
      ),
    );
  }

  Widget _buildEnergyColors(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(11, (index) {
        final color = _getEnergyColor(index);
        final isSelected = _energyLevel == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _energyLevel = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? themeProvider.primaryColor
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  Color _getEnergyColor(int level) {
    // Gradient from red (0) to green (10) through yellow (5)
    if (level <= 5) {
      // Red to Yellow
      final ratio = level / 5;
      return Color.lerp(
        const Color(0xFFFF6B6B), // Red
        const Color(0xFFFFD93D), // Yellow
        ratio,
      )!;
    } else {
      // Yellow to Green
      final ratio = (level - 5) / 5;
      return Color.lerp(
        const Color(0xFFFFD93D), // Yellow
        const Color(0xFF2ECC71), // Green
        ratio,
      )!;
    }
  }

  Widget _buildStep3({Key? key}) {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Add a Note',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional: Write about your day',
            style: TextStyle(fontSize: 16, color: themeProvider.textSecondary),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _noteController,
            hint: 'How was your day? What made you feel this way?',
            maxLines: 6,
            maxLength: 500,
          ),
          const SizedBox(height: 24),
          if (_selectedMood != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: themeProvider.borderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _moods[_selectedMood!].emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _moods[_selectedMood!].title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Energy: $_energyLevel/10',
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
          ],
        ],
      ),
    );
  }

  Widget _buildLoggedMoodCard(
    BoxConstraints constraints,
    ThemeProvider themeProvider,
  ) {
    if (_todayMood == null) return const SizedBox();

    final moodTitle = _todayMood!['title'] as String;
    final moodIndex = _moods.indexWhere((m) => m.title == moodTitle);
    final mood = moodIndex != -1 ? _moods[moodIndex] : _moods[0];
    final energyLevel = _todayMood!['energyLevel'] as int? ?? 5;
    final note = _todayMood!['note'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: constraints.maxWidth - 40,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  mood.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logged at ${_todayMood!['time']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Energy: ',
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$energyLevel/10',
                      style: TextStyle(
                        color: _getEnergyColor(energyLevel),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note,
                      style: TextStyle(
                        color: themeProvider.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
              color: _todayMood != null
                  ? themeProvider.primaryColor.withValues(alpha: 0.2)
                  : themeProvider.primaryColor.withValues(alpha: 0.1),
              border: Border.all(
                color: _todayMood != null
                    ? themeProvider.primaryColor
                    : themeProvider.borderColor,
                width: _todayMood != null ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _todayMood != null ? '✓' : '○',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _todayMood != null
                        ? themeProvider.primaryColor
                        : themeProvider.textSecondary,
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
