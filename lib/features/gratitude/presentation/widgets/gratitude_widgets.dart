import 'package:flutter/material.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_item.dart';
import '../../domain/entities/gratitude_prompt.dart';

/// Streak badge widget showing consecutive days
class GratitudeStreakBadge extends StatelessWidget {
  final int streak;
  final bool isCompact;

  const GratitudeStreakBadge({
    super.key,
    required this.streak,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: streak > 0
              ? [Colors.orange.shade400, Colors.amber.shade500]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        boxShadow: streak > 0
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: isCompact ? 18 : 24,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 14 : 18,
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 4),
            Text(
              streak == 1 ? 'gün' : 'gün',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card showing a random past memory for positive recall
class RandomMemoryCard extends StatelessWidget {
  final GratitudeEntry entry;
  final VoidCallback? onRefresh;
  final VoidCallback? onTap;

  const RandomMemoryCard({
    super.key,
    required this.entry,
    this.onRefresh,
    this.onTap,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstItem = entry.items.isNotEmpty ? entry.items.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.blue.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade100, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.purple.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Geçmişten Bir Hatıra',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(entry.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.purple.shade400,
                  ),
                ),
                if (onRefresh != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.purple.shade400,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (firstItem != null) ...[
              Text(
                '"${firstItem.content}"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.dominantEmotion != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${EmotionTags.getEmoji(entry.dominantEmotion!)} ${entry.dominantEmotion}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Emotion tag picker widget
class EmotionTagPicker extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final int maxTags;

  const EmotionTagPicker({
    super.key,
    required this.selectedTags,
    required this.onTagToggled,
    this.maxTags = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bu sana ne hissettirdi?',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'En fazla $maxTags duygu seç',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionTags.all.map((tag) {
            final isSelected = selectedTags.contains(tag);
            final canSelect = selectedTags.length < maxTags || isSelected;

            return GestureDetector(
              onTap: canSelect ? () => onTagToggled(tag) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.amber.shade100
                      : canSelect
                      ? Colors.grey.shade100
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.amber.shade400
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      EmotionTags.getEmoji(tag),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.amber.shade800
                            : canSelect
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Single gratitude item card
class GratitudeItemCard extends StatelessWidget {
  final GratitudeItem item;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GratitudeItemCard({
    super.key,
    required this.item,
    required this.index,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade400],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (item.whyContent != null && item.whyContent!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.whyContent!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.emotionTags != null && item.emotionTags!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: item.emotionTags!
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${EmotionTags.getEmoji(tag)} $tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Progress ring for daily gratitude goal
class GratitudeProgressRing extends StatelessWidget {
  final int currentItems;
  final int targetItems;
  final double size;

  const GratitudeProgressRing({
    super.key,
    required this.currentItems,
    this.targetItems = 3,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentItems / targetItems).clamp(0.0, 1.0);
    final isComplete = currentItems >= targetItems;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green.shade400 : Colors.amber.shade400,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.check : Icons.favorite,
                color: isComplete
                    ? Colors.green.shade400
                    : Colors.amber.shade400,
                size: size * 0.3,
              ),
              Text(
                '$currentItems/$targetItems',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.15,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Entry type toggle (morning/evening)
class EntryTypeToggle extends StatelessWidget {
  final EntryType selectedType;
  final ValueChanged<EntryType> onChanged;

  const EntryTypeToggle({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, EntryType.morning, Icons.wb_sunny, 'Sabah'),
          _buildOption(context, EntryType.evening, Icons.nights_stay, 'Akşam'),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    EntryType type,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade400 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
