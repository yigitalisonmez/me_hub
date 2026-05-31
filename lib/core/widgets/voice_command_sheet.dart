import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../services/voice_command_service.dart';
import '../services/command_parser.dart';
import '../services/nlp_intent_service.dart';
import '../providers/theme_provider.dart';
import '../providers/voice_settings_provider.dart';
import '../../features/water/presentation/providers/water_provider.dart';
import '../../features/todo/presentation/providers/todo_provider.dart';
import '../../features/mood_tracker/presentation/providers/mood_provider.dart';
import '../../features/water/data/services/daily_goal_service.dart';
import '../../features/timer/presentation/providers/timer_provider.dart';

/// Show voice command bottom sheet
Future<void> showVoiceCommandSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const VoiceCommandSheet(),
  );
}

class VoiceCommandSheet extends StatefulWidget {
  const VoiceCommandSheet({super.key});

  @override
  State<VoiceCommandSheet> createState() => _VoiceCommandSheetState();
}

class _VoiceCommandSheetState extends State<VoiceCommandSheet>
    with SingleTickerProviderStateMixin {
  final VoiceCommandService _voiceService = VoiceCommandService();

  String _recognizedText = '';
  ParsedCommand? _parsedCommand;
  bool _isListening = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _startListening();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _errorMessage = null;
      _successMessage = null;
      _recognizedText = '';
      _parsedCommand = null;
    });
    _pulseController.repeat(reverse: true);

    await _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _recognizedText = text;
        });
        // Show preview using fast regex (for UI feedback only)
        _showPreview(text);
      },
      onListeningComplete: () async {
        _pulseController.stop();
        _pulseController.reset();
        setState(() {
          _isListening = false;
        });

        // Process final text with NLP (this is the authoritative result)
        if (_recognizedText.isNotEmpty) {
          await _processWithNlp(_recognizedText);

          if (_parsedCommand != null) {
            _executeCommand();
          } else {
            setState(() {
              _errorMessage = 'Could not process the command. Try again.';
            });
          }
        }
      },
      localeId: context.read<VoiceSettingsProvider>().selectedLocale,
    );
  }

  /// Show preview label (fast regex, for UI feedback while speaking)
  void _showPreview(String text) {
    // Use regex parser for quick preview (not authoritative)
    final preview = CommandParser.parse(text);
    if (preview.type != CommandType.unknown) {
      setState(() {
        _parsedCommand = preview;
      });
    }
  }

  /// Process final text with NLP model (authoritative result)
  Future<void> _processWithNlp(String text) async {
    try {
      final command = await NlpIntentService.instance.processCommand(text);
      if (mounted) {
        setState(() {
          _parsedCommand = command;
        });
        debugPrint(
          '🧠 Final NLP result: ${command.type} - ${command.parameters}',
        );
      }
    } catch (e) {
      debugPrint('NLP processing error: $e');
      // Fallback to regex parser
      if (mounted) {
        setState(() {
          _parsedCommand = CommandParser.parse(text);
        });
      }
    }
  }

  Future<void> _executeCommand() async {
    if (kDebugMode) {
      debugPrint('🔍 _executeCommand called');
      debugPrint('🔍 _parsedCommand: $_parsedCommand');
      debugPrint('🔍 type: ${_parsedCommand?.type}');
      debugPrint('🔍 parameters: ${_parsedCommand?.parameters}');
    }

    if (_parsedCommand == null) {
      setState(() {
        _errorMessage = 'Could not understand the command. Try again.';
      });
      return;
    }

    // For "other" and "unknown" types, show appropriate message
    if (_parsedCommand!.type == CommandType.unknown ||
        _parsedCommand!.type == CommandType.other) {
      setState(() {
        _errorMessage = 'This command is not supported yet.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      switch (_parsedCommand!.type) {
        case CommandType.addWater:
          final amount = _parsedCommand!.parameters['amount'] as int;
          await context.read<WaterProvider>().addWaterAmount(amount);
          if (!mounted) return;
          setState(() {
            _successMessage = 'Added $amount ml of water! 💧';
          });
          break;

        case CommandType.addTodo:
          final title = _parsedCommand!.parameters['title'] as String;
          await context.read<TodoProvider>().addTodo(title: title);
          if (!mounted) return;
          setState(() {
            _successMessage = 'Added task: "$title" ✅';
          });
          break;

        case CommandType.setMood:
          final score = _parsedCommand!.parameters['score'] as int;
          await context.read<MoodProvider>().saveMood(score: score);
          if (!mounted) return;
          setState(() {
            _successMessage = 'Mood set to $score! 😊';
          });
          break;

        case CommandType.startTimer:
          final minutes = _parsedCommand!.parameters['minutes'] as int? ?? 25;
          // Actually start the timer via TimerProvider
          final timerProvider = context.read<TimerProvider>();
          timerProvider.setMode(TimerMode.countdown);
          timerProvider.setCountdownDuration(minutes);
          timerProvider.start();
          if (!mounted) return;
          setState(() {
            _successMessage = 'Timer started for $minutes min! ⏱️';
          });
          break;

        case CommandType.setWaterTarget:
          final target = _parsedCommand!.parameters['target'] as int? ?? 2000;
          final waterProvider = context.read<WaterProvider>();
          await DailyGoalService.setDailyGoal(target);
          if (!mounted) return;
          waterProvider.setDailyGoal(target);
          setState(() {
            _successMessage = 'Water target set to $target ml! 🎯';
          });
          break;

        case CommandType.completeTodo:
          final title = _parsedCommand!.parameters['title'] as String;
          final todoProvider = context.read<TodoProvider>();
          final todos = todoProvider.todos;

          // Find todo by title (fuzzy match - contains)
          final matchingTodo = todos.where((todo) {
            final todoTitle = todo.title.toLowerCase();
            final searchTitle = title.toLowerCase();
            return todoTitle.contains(searchTitle) ||
                searchTitle.contains(todoTitle) ||
                _fuzzyMatch(todoTitle, searchTitle);
          }).toList();

          if (matchingTodo.isNotEmpty) {
            // Complete the first matching todo
            final todo = matchingTodo.first;
            if (!todo.isCompleted) {
              await todoProvider.toggleTodoCompletion(todo.id);
              if (!mounted) return;
              setState(() {
                _successMessage = 'Completed: "${todo.title}" ✅';
              });
            } else {
              setState(() {
                _successMessage = '"${todo.title}" is already completed! ✅';
              });
            }
          } else {
            setState(() {
              _errorMessage = 'Could not find task: "$title"';
            });
          }
          break;

        case CommandType.navigate:
        case CommandType.queryStatus:
        case CommandType.undoLast:
        case CommandType.other:
        case CommandType.unknown:
          setState(() {
            _errorMessage = 'Command not yet implemented';
          });
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to execute command: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }

      // Auto-close after success
      if (_successMessage != null) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted && context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.cardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: themeProvider.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 32),

            // Animated sound wave bars (when listening)
            if (_isListening) _SoundWaveBars(color: themeProvider.primaryColor),

            // Main mic button with glow
            GestureDetector(
              onTap: _isListening
                  ? _voiceService.stopListening
                  : _startListening,
              child: SizedBox(
                width: 180,
                height: 180,
                child: Center(
                  child: AvatarGlow(
                    glowColor: themeProvider.primaryColor,
                    glowShape: BoxShape.circle,
                    animate: _isListening,
                    glowCount: 3,
                    glowRadiusFactor: 0.4,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isListening
                              ? [
                                  themeProvider.primaryColor,
                                  themeProvider.primaryColor.withValues(
                                    alpha: 0.8,
                                  ),
                                ]
                              : [
                                  themeProvider.surfaceColor,
                                  themeProvider.cardColor,
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? themeProvider.primaryColor.withValues(
                                    alpha: 0.3,
                                  )
                                : Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.mic,
                        size: 48,
                        color: _isListening
                            ? Colors.white
                            : themeProvider.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getStatusText(),
                key: ValueKey(_getStatusText()),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Recognized text
            if (_recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '"$_recognizedText"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Command preview chip
            if (_parsedCommand != null &&
                _parsedCommand!.type != CommandType.unknown)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeProvider.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getCommandLabel(_parsedCommand!),
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Processing indicator
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ),

            // Success message
            if (_successMessage != null)
              _buildResultCard(
                icon: LucideIcons.circleCheck,
                message: _successMessage!,
                color: Colors.green,
                themeProvider: themeProvider,
              ),

            // Error message
            if (_errorMessage != null)
              _buildResultCard(
                icon: LucideIcons.circleAlert,
                message: _errorMessage!,
                color: Colors.red,
                themeProvider: themeProvider,
              ),

            // Hint text
            if (!_isListening && _recognizedText.isEmpty && !_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Tap the microphone and speak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_isProcessing) return 'Processing...';
    if (_successMessage != null) return 'Done!';
    if (_errorMessage != null) return 'Try again';
    if (_isListening) return 'Listening...';
    return 'Voice Command';
  }

  Widget _buildResultCard({
    required IconData icon,
    required String message,
    required Color color,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCommandLabel(ParsedCommand command) {
    switch (command.type) {
      case CommandType.addWater:
        return '💧 Add ${command.parameters['amount']} ml';
      case CommandType.setWaterTarget:
        return '🎯 Set target: ${command.parameters['target']} ml';
      case CommandType.addTodo:
        return '✅ Add task: ${command.parameters['title']}';
      case CommandType.completeTodo:
        return '✓ Complete task';
      case CommandType.setMood:
        return '😊 Set mood: ${command.parameters['score']}';
      case CommandType.startTimer:
        return '⏱️ Timer: ${command.parameters['minutes']} min';
      case CommandType.navigate:
        return '🧭 Navigate to ${command.parameters['target']}';
      case CommandType.queryStatus:
        return '❓ Check status';
      case CommandType.undoLast:
        return '↩️ Undo last action';
      case CommandType.other:
        return '📝 Other command';
      case CommandType.unknown:
        return '❓ Unknown';
    }
  }

  /// Simple fuzzy match - checks if words overlap significantly
  bool _fuzzyMatch(String a, String b) {
    final wordsA = a.split(' ').where((w) => w.length > 2).toSet();
    final wordsB = b.split(' ').where((w) => w.length > 2).toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return false;
    final intersection = wordsA.intersection(wordsB);
    return intersection.isNotEmpty;
  }
}

/// Animated sound wave bars for listening state
class _SoundWaveBars extends StatefulWidget {
  final Color color;
  const _SoundWaveBars({required this.color});

  @override
  State<_SoundWaveBars> createState() => _SoundWaveBarsState();
}

class _SoundWaveBarsState extends State<_SoundWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final phase = (index * 0.2) % 1.0;
              final value = (((_controller.value + phase) * 2) % 2.0 - 1.0)
                  .abs();
              final height = 8 + (value * 24);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.6 + (value * 0.4)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
