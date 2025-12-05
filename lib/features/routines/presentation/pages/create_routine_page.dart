import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';

import '../widgets/routine_icon_picker.dart';
import '../widgets/routine_time_picker.dart';
import '../widgets/routine_days_selector.dart';
import '../widgets/routine_preview_card.dart';
import '../providers/routines_provider.dart';
import '../../../../core/widgets/elevated_card.dart';

class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage({super.key});

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  int? _selectedIconCodePoint;
  TimeOfDay? _selectedTime;
  List<int> _selectedDays = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Set default icon (first icon from RoutineIcons)
    if (RoutineIcons.allIcons.isNotEmpty) {
      final defaultIcon = RoutineIcons.allIcons[0]['icon'] as IconData;
      _selectedIconCodePoint = defaultIcon.codePoint;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate step 1: name must not be empty
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a routine name')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validate step 2: time must be selected
      if (_selectedTime == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a time')));
        return;
      }
    } else if (_currentStep == 2) {
      // Validate step 3: at least one day must be selected
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day')),
        );
        return;
      }
      // Create routine
      _createRoutine();
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
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _createRoutine() async {
    // Çift tıklamayı önle
    if (_isCreating) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final provider = context.read<RoutinesProvider>();
      await provider.addNewRoutine(
        _nameController.text.trim(),
        iconCodePoint: _selectedIconCodePoint,
        time: _selectedTime!,
        selectedDays: _selectedDays,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating routine: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Widget _buildProgressIndicator() {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: List.generate(3, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;

        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? themeProvider.primaryColor
                  : themeProvider.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        GestureDetector(
          onTap: _previousStep,
          child: SizedBox(
            width: 40,
            height: 40,
            child: ElevatedCard(
              padding: EdgeInsets.zero,
              borderRadius: 12,
              backgroundColor: themeProvider.cardColor,
              child: Center(
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Create Routine',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeProvider.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40), // Balance the back button
      ],
    );
  }

  Widget _buildStep1({Key? key}) {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // Large icon display
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final iconContainerSize = screenWidth * 0.35;
                final iconSize = iconContainerSize * 0.5;

                return SizedBox(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  child: ElevatedCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 20,
                    backgroundColor: _selectedIconCodePoint != null
                        ? themeProvider.backgroundColor
                        : themeProvider.surfaceColor,
                    child: Center(
                      child: Icon(
                        _selectedIconCodePoint != null
                            ? (RoutineIcons.getIconFromCodePoint(
                                    _selectedIconCodePoint!,
                                  ) ??
                                  RoutineIcons.allIcons[0]['icon'] as IconData)
                            : RoutineIcons.allIcons[0]['icon'] as IconData,
                        color: themeProvider.primaryColor,
                        size: iconSize,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          // Name input
          // Name input
          _buildInsetContainer(
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter routine name...',
                hintStyle: TextStyle(
                  color: themeProvider.textSecondary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Icon picker
          Text(
            'Select Icon',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: themeProvider.textPrimary),
          ),
          const SizedBox(height: 12),
          RoutineIconPicker(
            selectedIconCodePoint: _selectedIconCodePoint,
            onIconSelected: (codePoint) {
              setState(() {
                _selectedIconCodePoint = codePoint;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Preview card
          RoutinePreviewCard(
            name: _nameController.text.trim().isEmpty
                ? 'Routine Name'
                : _nameController.text.trim(),
            iconCodePoint: _selectedIconCodePoint,
            time: _selectedTime,
          ),
          const SizedBox(height: 32),
          Text(
            'When do you do it?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: context.watch<ThemeProvider>().textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a time for your routine',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.watch<ThemeProvider>().textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          RoutineTimePicker(
            selectedTime: _selectedTime,
            onTimeSelected: (time) {
              setState(() {
                _selectedTime = time;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Preview card
          RoutinePreviewCard(
            name: _nameController.text.trim(),
            iconCodePoint: _selectedIconCodePoint,
            time: _selectedTime,
          ),
          const SizedBox(height: 32),
          Text(
            'How often?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: context.watch<ThemeProvider>().textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the days you want to repeat',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.watch<ThemeProvider>().textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          RoutineDaysSelector(
            selectedDays: _selectedDays,
            onDaysChanged: (days) {
              setState(() {
                _selectedDays = days;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildProgressIndicator(),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedCard(
                      onTap: _previousStep,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      borderRadius: 12,
                      backgroundColor: themeProvider.surfaceColor,
                      child: Center(
                        child: Text(
                          'Back',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: themeProvider.textPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedCard(
                      onTap: _isCreating ? null : _nextStep,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      borderRadius: 12,
                      backgroundColor: themeProvider.primaryColor,
                      child: _isCreating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  themeProvider.textPrimary,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_currentStep == 2)
                                  Icon(
                                    LucideIcons.sparkles,
                                    color: themeProvider.textPrimary,
                                    size: 20,
                                  ),
                                if (_currentStep == 2) const SizedBox(width: 8),
                                Text(
                                  _currentStep == 2
                                      ? 'Create Routine'
                                      : 'Continue',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: themeProvider.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsetContainer({required Widget child}) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Top inner shadow (simulated with dark border/gradient)
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
          // Bottom highlight (simulated with light border)
          BoxShadow(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            offset: const Offset(0, -1),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
