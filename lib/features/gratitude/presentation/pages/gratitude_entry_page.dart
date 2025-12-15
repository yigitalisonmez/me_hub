import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/elevated_card.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_item.dart';
import '../../domain/entities/gratitude_prompt.dart';
import '../providers/gratitude_provider.dart';

/// Page for creating a new gratitude entry
class GratitudeEntryPage extends StatefulWidget {
  final EntryType entryType;

  const GratitudeEntryPage({super.key, required this.entryType});

  @override
  State<GratitudeEntryPage> createState() => _GratitudeEntryPageState();
}

class _GratitudeEntryPageState extends State<GratitudeEntryPage> {
  final List<_GratitudeItemData> _items = [];
  int _currentItemIndex = 0;
  bool _isSaving = false;

  final _contentController = TextEditingController();
  final _whyController = TextEditingController();
  List<String> _selectedEmotions = [];

  @override
  void initState() {
    super.initState();
    _addNewItem();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  void _addNewItem() {
    _items.add(_GratitudeItemData());
    _currentItemIndex = _items.length - 1;
    _loadCurrentItem();
    setState(() {});
  }

  void _loadCurrentItem() {
    final item = _items[_currentItemIndex];
    _contentController.text = item.content;
    _whyController.text = item.whyContent;
    _selectedEmotions = List.from(item.emotionTags);
  }

  void _saveCurrentItem() {
    if (_currentItemIndex < _items.length) {
      _items[_currentItemIndex] = _GratitudeItemData(
        content: _contentController.text.trim(),
        whyContent: _whyController.text.trim(),
        emotionTags: List.from(_selectedEmotions),
      );
    }
  }

  void _switchToItem(int index) {
    _saveCurrentItem();
    _currentItemIndex = index;
    _loadCurrentItem();
    setState(() {});
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    _items.removeAt(index);
    if (_currentItemIndex >= _items.length) {
      _currentItemIndex = _items.length - 1;
    }
    _loadCurrentItem();
    setState(() {});
  }

  bool get _canAddMore => _items.length < 5;
  int get _validItemsCount => _items.where((i) => i.content.isNotEmpty).length;
  bool get _canSave => _validItemsCount >= 3;

  Future<void> _saveEntry() async {
    _saveCurrentItem();

    final validItems = _items.where((i) => i.content.isNotEmpty).toList();
    if (validItems.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 3 gratitude items'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final gratitudeItems = validItems
        .map(
          (data) => GratitudeItem.create(
            content: data.content,
            whyContent: data.whyContent.isNotEmpty ? data.whyContent : null,
            emotionTags: data.emotionTags.isNotEmpty ? data.emotionTags : null,
          ),
        )
        .toList();

    final success = await context.read<GratitudeProvider>().addEntry(
      items: gratitudeItems,
      entryType: widget.entryType,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gratitude saved! 🙏'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<GratitudeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: themeProvider.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.entryType == EntryType.morning
              ? 'Morning Gratitude'
              : 'Evening Gratitude',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_canSave)
            TextButton(
              onPressed: _isSaving ? null : _saveEntry,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          themeProvider.primaryColor,
                        ),
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: themeProvider.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _ProgressBar(
            items: _items,
            currentIndex: _currentItemIndex,
            onItemTap: _switchToItem,
          ),

          // Prompt card
          _PromptHint(
            prompt: provider.currentPrompt,
            onRefresh: () => provider.refreshPrompt(),
          ),

          // Main input area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content input
                  Text(
                    'What are you grateful for?',
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedCard(
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _contentController,
                      maxLines: 3,
                      style: TextStyle(color: themeProvider.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Write something you\'re thankful for...',
                        hintStyle: TextStyle(
                          color: themeProvider.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Why depth question
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.lightbulb,
                        color: themeProvider.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Why is this meaningful to you?',
                        style: TextStyle(
                          color: themeProvider.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optional - helps deepen your gratitude practice',
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedCard(
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _whyController,
                      maxLines: 2,
                      style: TextStyle(color: themeProvider.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'This matters to me because...',
                        hintStyle: TextStyle(
                          color: themeProvider.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  // Emotion tags
                  const SizedBox(height: 24),
                  _EmotionTagSection(
                    selectedTags: _selectedEmotions,
                    onTagToggled: (tag) {
                      setState(() {
                        if (_selectedEmotions.contains(tag)) {
                          _selectedEmotions.remove(tag);
                        } else if (_selectedEmotions.length < 3) {
                          _selectedEmotions.add(tag);
                        }
                      });
                    },
                  ),

                  // Item navigation
                  const SizedBox(height: 32),
                  _ItemNavigator(
                    items: _items,
                    currentIndex: _currentItemIndex,
                    canAddMore: _canAddMore,
                    validItemsCount: _validItemsCount,
                    onItemTap: _switchToItem,
                    onRemoveItem: _removeItem,
                    onAddItem: () {
                      _saveCurrentItem();
                      _addNewItem();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final List<_GratitudeItemData> items;
  final int currentIndex;
  final void Function(int) onItemTap;

  const _ProgressBar({
    required this.items,
    required this.currentIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(5, (index) {
          final hasContent =
              index < items.length && items[index].content.isNotEmpty;
          final isCurrent = index == currentIndex;
          final isAvailable = index < items.length;

          return Expanded(
            child: GestureDetector(
              onTap: isAvailable ? () => onItemTap(index) : null,
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: hasContent
                      ? const Color(0xFF4CAF50)
                      : isCurrent
                      ? themeProvider.primaryColor
                      : themeProvider.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PromptHint extends StatelessWidget {
  final GratitudePrompt prompt;
  final VoidCallback onRefresh;

  const _PromptHint({required this.prompt, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.sparkles,
            color: themeProvider.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prompt.content,
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(
              LucideIcons.refreshCw,
              color: themeProvider.textSecondary,
              size: 14,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmotionTagSection extends StatelessWidget {
  final List<String> selectedTags;
  final void Function(String) onTagToggled;

  const _EmotionTagSection({
    required this.selectedTags,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // English emotion tags
    final emotionTags = [
      ('Peace', LucideIcons.cloud),
      ('Joy', LucideIcons.smile),
      ('Love', LucideIcons.heart),
      ('Hope', LucideIcons.star),
      ('Gratitude', LucideIcons.handshake),
      ('Trust', LucideIcons.shield),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.heart, color: const Color(0xFFE91E63), size: 18),
            const SizedBox(width: 8),
            Text(
              'How does this make you feel?',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select up to 3 emotions',
          style: TextStyle(color: themeProvider.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emotionTags.map((tag) {
            final isSelected = selectedTags.contains(tag.$1);
            final canSelect = selectedTags.length < 3 || isSelected;

            return GestureDetector(
              onTap: canSelect ? () => onTagToggled(tag.$1) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeProvider.primaryColor
                      : themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: themeProvider.textSecondary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tag.$2,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : themeProvider.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag.$1,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : themeProvider.textSecondary,
                        fontSize: 13,
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

class _ItemNavigator extends StatelessWidget {
  final List<_GratitudeItemData> items;
  final int currentIndex;
  final bool canAddMore;
  final int validItemsCount;
  final void Function(int) onItemTap;
  final void Function(int) onRemoveItem;
  final VoidCallback onAddItem;

  const _ItemNavigator({
    required this.items,
    required this.currentIndex,
    required this.canAddMore,
    required this.validItemsCount,
    required this.onItemTap,
    required this.onRemoveItem,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(items.length, (index) {
              final hasContent = items[index].content.isNotEmpty;
              final isCurrent = index == currentIndex;

              return GestureDetector(
                onTap: () => onItemTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? themeProvider.primaryColor
                        : hasContent
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isCurrent
                        ? null
                        : Border.all(
                            color: hasContent
                                ? const Color(0xFF4CAF50)
                                : themeProvider.textSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasContent && !isCurrent)
                        Icon(
                          LucideIcons.check,
                          size: 14,
                          color: const Color(0xFF4CAF50),
                        ),
                      if (hasContent && !isCurrent) const SizedBox(width: 4),
                      Text(
                        'Item ${index + 1}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : hasContent
                              ? const Color(0xFF4CAF50)
                              : themeProvider.textSecondary,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (items.length > 1) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => onRemoveItem(index),
                          child: Icon(
                            LucideIcons.x,
                            size: 14,
                            color: isCurrent
                                ? Colors.white.withValues(alpha: 0.7)
                                : themeProvider.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            // Add button
            if (canAddMore)
              GestureDetector(
                onTap: onAddItem,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeProvider.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 14,
                        color: themeProvider.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          '$validItemsCount/3+ items completed',
          style: TextStyle(
            color: validItemsCount >= 3
                ? const Color(0xFF4CAF50)
                : themeProvider.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Helper class to hold item data before saving
class _GratitudeItemData {
  String content;
  String whyContent;
  List<String> emotionTags;

  _GratitudeItemData({
    this.content = '',
    this.whyContent = '',
    List<String>? emotionTags,
  }) : emotionTags = emotionTags ?? [];
}
