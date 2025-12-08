import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/voice_command_service.dart';
import '../services/command_parser.dart';
import '../services/nlp_intent_service.dart';
import '../providers/theme_provider.dart';
import '../providers/voice_settings_provider.dart';
import '../../features/water/presentation/providers/water_provider.dart';
import '../../features/todo/presentation/providers/todo_provider.dart';
import '../../features/mood_tracker/presentation/providers/mood_provider.dart';
import '../../features/water/data/services/daily_goal_service.dart';

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
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
        print('🧠 Final NLP result: ${command.type} - ${command.parameters}');
      }
    } catch (e) {
      print('NLP processing error: $e');
      // Fallback to regex parser
      if (mounted) {
        setState(() {
          _parsedCommand = CommandParser.parse(text);
        });
      }
    }
  }

  Future<void> _executeCommand() async {
    print('🔍 _executeCommand called');
    print('🔍 _parsedCommand: $_parsedCommand');
    print('🔍 type: ${_parsedCommand?.type}');
    print('🔍 parameters: ${_parsedCommand?.parameters}');

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
          setState(() {
            _successMessage = 'Added $amount ml of water! 💧';
          });
          break;

        case CommandType.addTodo:
          final title = _parsedCommand!.parameters['title'] as String;
          await context.read<TodoProvider>().addTodo(title: title);
          setState(() {
            _successMessage = 'Added task: "$title" ✅';
          });
          break;

        case CommandType.setMood:
          final score = _parsedCommand!.parameters['score'] as int;
          await context.read<MoodProvider>().saveMood(score: score);
          setState(() {
            _successMessage = 'Mood set to $score! 😊';
          });
          break;

        case CommandType.startTimer:
          final minutes = _parsedCommand!.parameters['minutes'] as int? ?? 25;
          setState(() {
            _successMessage = 'Timer started for $minutes min! ⏱️';
          });
          // TODO: Integrate with timer feature
          break;

        case CommandType.setWaterTarget:
          final target = _parsedCommand!.parameters['target'] as int? ?? 2000;
          await DailyGoalService.setDailyGoal(target);
          context.read<WaterProvider>().setDailyGoal(target);
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
      setState(() {
        _errorMessage = 'Failed to execute command: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });

      // Auto-close after success
      if (_successMessage != null) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeProvider.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _isListening ? 'Listening...' : 'Voice Command',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Microphone button with pulse animation
              GestureDetector(
                onTap: _isListening
                    ? _voiceService.stopListening
                    : _startListening,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? themeProvider.primaryColor
                              : themeProvider.surfaceColor,
                          shape: BoxShape.circle,
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: themeProvider.primaryColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isListening ? LucideIcons.mic : LucideIcons.micOff,
                          size: 40,
                          color: _isListening
                              ? Colors.white
                              : themeProvider.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Recognized text
              if (_recognizedText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You said:',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _recognizedText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                      if (_parsedCommand != null &&
                          _parsedCommand!.type != CommandType.unknown) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCommandLabel(_parsedCommand!),
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Processing indicator
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: themeProvider.primaryColor,
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.circleCheck, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.circleAlert, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Example commands
              if (!_isListening && _recognizedText.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Try saying:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildExampleCommand('"Add 500 ml water"', themeProvider),
                      _buildExampleCommand(
                        '"Add task buy groceries"',
                        themeProvider,
                      ),
                      _buildExampleCommand('"Set mood 8"', themeProvider),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleCommand(String text, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.mic, size: 14, color: themeProvider.primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.textSecondary,
              fontStyle: FontStyle.italic,
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
