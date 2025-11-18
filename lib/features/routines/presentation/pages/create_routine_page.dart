import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/routine_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../widgets/routine_icon_picker.dart';
import '../widgets/routine_time_picker.dart';
import '../widgets/routine_days_selector.dart';
import '../widgets/routine_preview_card.dart';
import '../providers/routines_provider.dart';

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
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeProvider.borderColor, width: 1.5),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: themeProvider.primaryColor,
              size: 20,
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

  Widget _buildStep1() {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // Large icon display
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final iconContainerSize =
                    screenWidth * 0.35; // Ekran genişliğinin %30'u
                final iconSize =
                    iconContainerSize * 0.5; // Container boyutunun %50'si

                return Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: _selectedIconCodePoint != null
                        ? themeProvider.backgroundColor
                        : themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedIconCodePoint != null
                          ? themeProvider.primaryColor
                          : themeProvider.borderColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.primaryColor.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 12,
                        spreadRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          // Name input
          CustomTextField(
            hint: 'Enter routine name...',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textAlign: TextAlign.center,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
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

  Widget _buildStep2() {
    return SingleChildScrollView(
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

  Widget _buildStep3() {
    return SingleChildScrollView(
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
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                    ? _buildStep2()
                    : _buildStep3(),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: themeProvider.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
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
                            _currentStep == 2 ? 'Create Routine' : 'Continue',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: themeProvider.textPrimary),
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
}
