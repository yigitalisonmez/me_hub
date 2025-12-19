import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../domain/entities/gratitude_entry.dart';
import '../../domain/entities/gratitude_item.dart';
import '../providers/gratitude_provider.dart';

class GratitudeEntryPage extends StatefulWidget {
  final EntryType entryType;

  const GratitudeEntryPage({super.key, required this.entryType});

  @override
  State<GratitudeEntryPage> createState() => _GratitudeEntryPageState();
}

class _GratitudeEntryPageState extends State<GratitudeEntryPage> {
  int _currentStep = 0; // 0: intro, 1: write, 2: feel
  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();
  final _controller3 = TextEditingController();
  String? _selectedFeeling;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _feelings = [
    {
      'id': 'grateful',
      'icon': LucideIcons.heart,
      'label': 'Grateful',
      'color': const Color(0xFFE91E63),
    },
    {
      'id': 'peaceful',
      'icon': LucideIcons.cloud,
      'label': 'Peaceful',
      'color': const Color(0xFF42A5F5),
    },
    {
      'id': 'happy',
      'icon': LucideIcons.sun,
      'label': 'Happy',
      'color': const Color(0xFFFFB74D),
    },
    {
      'id': 'hopeful',
      'icon': LucideIcons.sparkles,
      'label': 'Hopeful',
      'color': const Color(0xFF9C27B0),
    },
    {
      'id': 'strong',
      'icon': LucideIcons.zap,
      'label': 'Strong',
      'color': const Color(0xFF4CAF50),
    },
  ];

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

  bool get _canProceedFromWrite => _filledCount >= 3;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveEntry() async {
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

    if (_selectedFeeling != null && items.isNotEmpty) {
      items[0] = GratitudeItem.create(
        content: items[0].content,
        emotionTags: [_selectedFeeling!],
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
    final isMorning = widget.entryType == EntryType.morning;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _prevStep,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _currentStep == 0
                            ? LucideIcons.x
                            : LucideIcons.arrowLeft,
                        color: themeProvider.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Progress dots
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentStep ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i <= _currentStep
                                ? themeProvider.primaryColor
                                : themeProvider.textSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Time indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMorning ? LucideIcons.sunrise : LucideIcons.moon,
                          color: themeProvider.primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMorning ? 'AM' : 'PM',
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content based on step
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0
                    ? _buildIntroStep(themeProvider)
                    : _currentStep == 1
                    ? _buildWriteStep(themeProvider)
                    : _buildFeelStep(themeProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroStep(ThemeProvider themeProvider) {
    final provider = context.watch<GratitudeProvider>();

    return Padding(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big heart icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.heart,
              color: themeProvider.primaryColor,
              size: 64,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "What are you\ngrateful for?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Take a moment to reflect on the\ngood things in your life.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Prompt hint
          GestureDetector(
            onTap: () => provider.refreshPrompt(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    color: themeProvider.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.currentPrompt.content,
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.refreshCw,
                    color: themeProvider.textSecondary.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Start button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Let's Start",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWriteStep(ThemeProvider themeProvider) {
    return Padding(
      key: const ValueKey('write'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            "Write 3 things",
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Big or small, anything counts!",
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),
          // Progress indicator
          Row(
            children: [
              Text(
                '$_filledCount/3',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _filledCount / 3,
                    backgroundColor: themeProvider.textSecondary.withValues(
                      alpha: 0.2,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      themeProvider.primaryColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Text fields
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canProceedFromWrite ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceedFromWrite
                    ? themeProvider.primaryColor
                    : themeProvider.textSecondary.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _canProceedFromWrite
                        ? 'Continue'
                        : '$_filledCount of 3 completed',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_canProceedFromWrite) ...[
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.arrowRight, size: 20),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeelStep(ThemeProvider themeProvider) {
    return Padding(
      key: const ValueKey('feel'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Big emoji container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _selectedFeeling != null
                  ? (_feelings.firstWhere(
                              (f) => f['id'] == _selectedFeeling,
                            )['color']
                            as Color)
                        .withValues(alpha: 0.1)
                  : themeProvider.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedFeeling != null
                  ? _feelings.firstWhere(
                          (f) => f['id'] == _selectedFeeling,
                        )['icon']
                        as IconData
                  : LucideIcons.smile,
              color: _selectedFeeling != null
                  ? _feelings.firstWhere(
                          (f) => f['id'] == _selectedFeeling,
                        )['color']
                        as Color
                  : themeProvider.textSecondary,
              size: 56,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "How do you feel?",
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select the emotion that best describes you right now",
            textAlign: TextAlign.center,
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          // Feelings grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _feelings.map((feeling) {
                final isSelected = _selectedFeeling == feeling['id'];
                final color = feeling['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(
                    () => _selectedFeeling = isSelected ? null : feeling['id'],
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          feeling['icon'] as IconData,
                          size: isSelected ? 32 : 28,
                          color: isSelected
                              ? color
                              : themeProvider.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          feeling['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? color
                                : themeProvider.textSecondary,
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
          ),
          const Spacer(),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: !_isSaving ? _saveEntry : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save Gratitude',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.check, size: 20),
                      ],
                    ),
            ),
          ),
          // Skip button
          TextButton(
            onPressed: !_isSaving ? _saveEntry : null,
            child: Text(
              'Skip this step',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

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
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
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
            Container(
              margin: const EdgeInsets.all(12),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasContent
                    ? const Color(0xFF4CAF50)
                    : widget.themeProvider.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: hasContent
                    ? const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 18,
                      )
                    : Text(
                        '${widget.number}',
                        style: TextStyle(
                          color: widget.themeProvider.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 2,
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
