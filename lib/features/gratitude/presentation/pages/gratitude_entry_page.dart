import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_item.dart';
import '../providers/gratitude_provider.dart';

/// Simplified gratitude entry page - 3 boxes, minimal friction
class GratitudeEntryPage extends StatefulWidget {
  final EntryType entryType;

  const GratitudeEntryPage({super.key, required this.entryType});

  @override
  State<GratitudeEntryPage> createState() => _GratitudeEntryPageState();
}

class _GratitudeEntryPageState extends State<GratitudeEntryPage> {
  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();
  final _controller3 = TextEditingController();
  String? _selectedEmoji;
  bool _isSaving = false;

  final List<String> _quickEmojis = ['😊', '🙏', '❤️', '✨', '🌟', '💪'];

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  int get _filledCount {
    int count = 0;
    if (_controller1.text.trim().isNotEmpty) count++;
    if (_controller2.text.trim().isNotEmpty) count++;
    if (_controller3.text.trim().isNotEmpty) count++;
    return count;
  }

  bool get _canSave => _filledCount >= 3;

  Future<void> _saveEntry() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    final items = <GratitudeItem>[];

    if (_controller1.text.trim().isNotEmpty) {
      items.add(GratitudeItem.create(content: _controller1.text.trim()));
    }
    if (_controller2.text.trim().isNotEmpty) {
      items.add(GratitudeItem.create(content: _controller2.text.trim()));
    }
    if (_controller3.text.trim().isNotEmpty) {
      items.add(GratitudeItem.create(content: _controller3.text.trim()));
    }

    // Add emoji as emotion tag if selected
    if (_selectedEmoji != null && items.isNotEmpty) {
      items[0] = GratitudeItem.create(
        content: items[0].content,
        emotionTags: [_selectedEmoji!],
      );
    }

    final success = await context.read<GratitudeProvider>().addEntry(
      items: items,
      entryType: widget.entryType,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      _showSuccessAnimation();
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessDialog(
        onClose: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<GratitudeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: themeProvider.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.entryType == EntryType.morning ? 'Morning' : 'Evening',
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "What are you grateful for?",
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Write 3 things, big or small.",
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 14,
              ),
            ),

            // Prompt hint
            GestureDetector(
              onTap: () => provider.refreshPrompt(),
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      color: themeProvider.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.currentPrompt.content,
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      LucideIcons.refreshCw,
                      color: themeProvider.textSecondary.withValues(alpha: 0.5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 3 Simple text fields
            _GratitudeTextField(
              controller: _controller1,
              number: 1,
              placeholder: "I'm grateful for...",
              themeProvider: themeProvider,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            _GratitudeTextField(
              controller: _controller2,
              number: 2,
              placeholder: "I appreciate...",
              themeProvider: themeProvider,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            _GratitudeTextField(
              controller: _controller3,
              number: 3,
              placeholder: "I'm thankful for...",
              themeProvider: themeProvider,
              onChanged: () => setState(() {}),
            ),

            const SizedBox(height: 32),

            // Quick emoji selector - app style
            Text(
              "How do you feel?",
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickEmojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedEmoji = isSelected ? null : emoji;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeProvider.primaryColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: isSelected ? 26 : 22),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSave && !_isSaving ? _saveEntry : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave
                      ? themeProvider.primaryColor
                      : themeProvider.textSecondary.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _canSave ? 4 : 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _canSave ? 'Save Gratitude' : '$_filledCount of 3',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_canSave) ...[
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.check, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered text field with focus border
class _GratitudeTextField extends StatefulWidget {
  final TextEditingController controller;
  final int number;
  final String placeholder;
  final ThemeProvider themeProvider;
  final VoidCallback onChanged;

  const _GratitudeTextField({
    required this.controller,
    required this.number,
    required this.placeholder,
    required this.themeProvider,
    required this.onChanged,
  });

  @override
  State<_GratitudeTextField> createState() => _GratitudeTextFieldState();
}

class _GratitudeTextFieldState extends State<_GratitudeTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.controller.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? widget.themeProvider.primaryColor
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? widget.themeProvider.primaryColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _isFocused ? 12 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Container(
              margin: const EdgeInsets.all(12),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hasContent
                    ? const Color(0xFF4CAF50)
                    : widget.themeProvider.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: hasContent
                    ? const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : Text(
                        '${widget.number}',
                        style: TextStyle(
                          color: widget.themeProvider.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: 2,
                minLines: 1,
                style: TextStyle(
                  color: widget.themeProvider.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(
                    color: widget.themeProvider.textSecondary.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                ),
                onChanged: (_) => widget.onChanged(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Success celebration dialog
class _SuccessDialog extends StatefulWidget {
  final VoidCallback onClose;

  const _SuccessDialog({required this.onClose});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.heart,
                  color: Color(0xFF4CAF50),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Gratitude Saved!',
                style: TextStyle(
                  color: themeProvider.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep up the great habit 🌟',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
