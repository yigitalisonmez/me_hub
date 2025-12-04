import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/mood_provider.dart';
import '../utils/mood_utils.dart';
import '../../domain/entities/mood_entry.dart';

class MoodHistoryList extends StatelessWidget {
  const MoodHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final moodProvider = context.watch<MoodProvider>();
    final moods = moodProvider.allMoods;

    // Sort moods by date descending
    final sortedMoods = List<MoodEntry>.from(moods)
      ..sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));

    if (sortedMoods.isEmpty) {
      return const EmptyStateWidget(
        message: 'No mood entries yet',
        icon: LucideIcons.heart,
        subMessage: 'Track your mood to see patterns over time.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Recent Entries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (sortedMoods.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: EmptyStateWidget(
              message: 'No recent entries',
              icon: LucideIcons.history,
              subMessage: 'Your mood history will appear here.',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMoods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final mood = sortedMoods[index];
              return _MoodHistoryItem(
                mood: mood,
                themeProvider: themeProvider,
                moodProvider: moodProvider,
              );
            },
          ),
      ],
    );
  }
}

class _MoodHistoryItem extends StatelessWidget {
  final MoodEntry mood;
  final ThemeProvider themeProvider;
  final MoodProvider moodProvider;

  const _MoodHistoryItem({
    required this.mood,
    required this.themeProvider,
    required this.moodProvider,
  });

  @override
  Widget build(BuildContext context) {
    final color = MoodUtils.getColorForScore(mood.score);
    final icon = MoodUtils.getIconForScore(mood.score);
    final label = MoodUtils.getLabelForScore(mood.score);
    final date = DateTime.fromMillisecondsSinceEpoch(mood.dateTimestamp);
    final timeStr = DateFormat('h:mm a').format(date);
    final dateStr = DateFormat('MMM d, y').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Mood Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '$dateStr • $timeStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${mood.score}/10',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (mood.note != null && mood.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mood.note!,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                context,
                icon: LucideIcons.pencil,
                label: 'Edit',
                onTap: () => _showEditDialog(context),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                icon: LucideIcons.trash2,
                label: 'Delete',
                isDestructive: true,
                onTap: () => _showDeleteDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : themeProvider.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        title: Text('Delete Entry', style: TextStyle(color: themeProvider.textPrimary)),
        content: Text(
          'Are you sure you want to delete this mood entry?',
          style: TextStyle(color: themeProvider.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeProvider.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              moodProvider.deleteMood(DateTime.fromMillisecondsSinceEpoch(mood.dateTimestamp));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    double currentScore = mood.score.toDouble();
    final noteController = TextEditingController(text: mood.note);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final color = MoodUtils.getColorForScore(currentScore.toInt());
          final icon = MoodUtils.getIconForScore(currentScore.toInt());
          final label = MoodUtils.getLabelForScore(currentScore.toInt());

          return AlertDialog(
            backgroundColor: themeProvider.cardColor,
            title: Text('Edit Mood', style: TextStyle(color: themeProvider.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon and Label
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: color,
                      inactiveTrackColor: themeProvider.borderColor,
                      thumbColor: Colors.white,
                      overlayColor: color.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Slider(
                      value: currentScore,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (val) {
                        setState(() => currentScore = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Note
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: TextStyle(color: themeProvider.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      hintStyle: TextStyle(color: themeProvider.textSecondary),
                      filled: true,
                      fillColor: themeProvider.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: themeProvider.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  moodProvider.saveMood(
                    score: currentScore.toInt(),
                    note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    date: DateTime.fromMillisecondsSinceEpoch(mood.dateTimestamp),
                  );
                  Navigator.pop(context);
                },
                child: Text('Save', style: TextStyle(color: themeProvider.primaryColor)),
              ),
            ],
          );
        },
      ),
    );
  }
}
