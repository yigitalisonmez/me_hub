import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  String? _selectedMood;

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Happy', 'color': Colors.yellow},
    {'emoji': '😢', 'label': 'Sad', 'color': Colors.blue},
    {'emoji': '😡', 'label': 'Angry', 'color': Colors.red},
    {'emoji': '😴', 'label': 'Tired', 'color': Colors.grey},
    {'emoji': '😰', 'label': 'Anxious', 'color': Colors.orange},
    {'emoji': '😌', 'label': 'Calm', 'color': Colors.green},
    {'emoji': '🤔', 'label': 'Thoughtful', 'color': Colors.purple},
    {'emoji': '😎', 'label': 'Confident', 'color': Colors.cyan},
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(color: themeProvider.backgroundColor),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context, themeProvider),
              const SizedBox(height: 32),
              _buildMoodSelector(context, themeProvider),
              const SizedBox(height: 32),
              if (_selectedMood != null) _buildSelectedMood(context, themeProvider),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: theme.textTheme.displaySmall?.copyWith(
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your daily mood',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
        Icon(
          LucideIcons.heart,
          color: themeProvider.primaryColor,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildMoodSelector(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Select your mood',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _moods.map((mood) {
              final isSelected = _selectedMood == mood['label'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = mood['label'];
                  });
                },
                child: Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeProvider.primaryColor.withValues(alpha: 0.1)
                        : themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? themeProvider.primaryColor
                          : themeProvider.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood['emoji'],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mood['label'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? themeProvider.primaryColor
                              : themeProvider.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMood(BuildContext context, ThemeProvider themeProvider) {
    final selectedMoodData = _moods.firstWhere(
      (mood) => mood['label'] == _selectedMood,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your mood today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            selectedMoodData['emoji'],
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          Text(
            selectedMoodData['label'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save mood
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mood saved: ${selectedMoodData['label']}'),
                    backgroundColor: themeProvider.primaryColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Mood',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

