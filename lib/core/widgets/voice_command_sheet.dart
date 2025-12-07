import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/voice_command_service.dart';
import '../services/command_parser.dart';
import '../providers/theme_provider.dart';
import '../providers/voice_settings_provider.dart';
import '../../features/water/presentation/providers/water_provider.dart';
import '../../features/todo/presentation/providers/todo_provider.dart';
import '../../features/mood_tracker/presentation/providers/mood_provider.dart';

/// Show voice command dialog (not bottom sheet for better UX)
Future<void> showVoiceCommandSheet(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => const VoiceCommandDialog(),
  );
}

class VoiceCommandDialog extends StatefulWidget {
  const VoiceCommandDialog({super.key});

  @override
  State<VoiceCommandDialog> createState() => _VoiceCommandDialogState();
}

class _VoiceCommandDialogState extends State<VoiceCommandDialog>
    with TickerProviderStateMixin {
  final VoiceCommandService _voiceService = VoiceCommandService();

  String _recognizedText = '';
  ParsedCommand? _parsedCommand;
  bool _isListening = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startListening();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
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
    _waveController.repeat();

    await _voiceService.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
            _parsedCommand = CommandParser.parse(text);
          });
        }
      },
      onListeningComplete: () {
        if (mounted) {
          _pulseController.stop();
          _pulseController.reset();
          _waveController.stop();
          setState(() {
            _isListening = false;
          });
          if (_recognizedText.isNotEmpty) {
            _executeCommand();
          }
        }
      },
      localeId: context.read<VoiceSettingsProvider>().selectedLocale,
    );
  }

  Future<void> _executeCommand() async {
    if (_parsedCommand == null || _parsedCommand!.type == CommandType.unknown) {
      setState(() {
        _errorMessage = 'Komut anlaşılamadı. Tekrar deneyin.';
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
            _successMessage = '$amount ml su eklendi! 💧';
          });
          break;

        case CommandType.addTodo:
          final title = _parsedCommand!.parameters['title'] as String;
          await context.read<TodoProvider>().addTodo(title: title);
          setState(() {
            _successMessage = 'Görev eklendi: "$title" ✅';
          });
          break;

        case CommandType.setMood:
          final score = _parsedCommand!.parameters['score'] as int;
          await context.read<MoodProvider>().saveMood(score: score);
          setState(() {
            _successMessage = 'Ruh hali: $score 😊';
          });
          break;

        case CommandType.unknown:
          setState(() {
            _errorMessage = 'Komut tanınamadı';
          });
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });

      if (_successMessage != null) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        constraints: const BoxConstraints(maxWidth: 320),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: themeProvider.cardColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated microphone
                  _buildMicrophoneButton(themeProvider),
                  const SizedBox(height: 20),

                  // Status text
                  Text(
                    _isListening ? 'Dinleniyor...' : 'Mikrofona dokun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textPrimary,
                    ),
                  ),

                  // Recognized text
                  if (_recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: themeProvider.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '"$_recognizedText"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: themeProvider.textPrimary,
                            ),
                          ),
                          if (_parsedCommand != null &&
                              _parsedCommand!.type != CommandType.unknown) ...[
                            const SizedBox(height: 8),
                            _buildCommandChip(themeProvider),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Processing
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],

                  // Success
                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildResultCard(
                      icon: LucideIcons.circleCheck,
                      color: Colors.green,
                      message: _successMessage!,
                    ),
                  ],

                  // Error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildResultCard(
                      icon: LucideIcons.circleAlert,
                      color: Colors.red,
                      message: _errorMessage!,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _startListening,
                      child: Text(
                        'Tekrar Dene',
                        style: TextStyle(color: themeProvider.primaryColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: _isListening ? _voiceService.stopListening : _startListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer wave rings
              if (_isListening) ...[
                _buildWaveRing(themeProvider, 1.4, 0.1),
                _buildWaveRing(themeProvider, 1.25, 0.15),
              ],
              // Main button
              Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: _isListening
                        ? themeProvider.primaryGradient
                        : null,
                    color: _isListening ? null : themeProvider.surfaceColor,
                    shape: BoxShape.circle,
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: themeProvider.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? LucideIcons.mic : LucideIcons.micOff,
                    size: 32,
                    color: _isListening
                        ? Colors.white
                        : themeProvider.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWaveRing(
    ThemeProvider themeProvider,
    double scale,
    double opacity,
  ) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        final animatedScale = scale + (0.1 * _waveController.value);
        final animatedOpacity = opacity * (1 - _waveController.value);
        return Transform.scale(
          scale: animatedScale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: themeProvider.primaryColor.withValues(
                  alpha: animatedOpacity,
                ),
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommandChip(ThemeProvider themeProvider) {
    final command = _parsedCommand!;
    String label;

    switch (command.type) {
      case CommandType.addWater:
        label = '💧 ${command.parameters['amount']} ml';
        break;
      case CommandType.addTodo:
        label = '✅ ${command.parameters['title']}';
        break;
      case CommandType.setMood:
        label = '😊 Mood: ${command.parameters['score']}';
        break;
      case CommandType.unknown:
        label = '?';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
