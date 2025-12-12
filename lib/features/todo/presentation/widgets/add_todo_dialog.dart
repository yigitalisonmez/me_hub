import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/validators.dart';

/// Add todo dialog with monochromatic elevation
class AddTodoDialog extends StatefulWidget {
  final Function({required String title, DateTime? date, int priority}) onAdd;

  const AddTodoDialog({super.key, required this.onAdd});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int _selectedPriority = 2;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    // Use existing theme colors for dialog
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          // Dialog uses cardColor from theme
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _getDialogShadow(isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Add New Todo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Input field - lighter than card, popped up
                  _buildInputField(themeProvider, isDark),
                  const SizedBox(height: 20),
                  _buildPrioritySelector(themeProvider, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCancelButton(themeProvider, isDark),
                const SizedBox(width: 12),
                _buildAddButton(themeProvider, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog shadow - bevel effect
  List<BoxShadow> _getDialogShadow(bool isDark) {
    return [
      // Top highlight (light from above)
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        offset: const Offset(0, -2),
        blurRadius: 4,
      ),
      // Bottom shadow (ground separation)
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
        offset: const Offset(0, 8),
        blurRadius: 16,
        spreadRadius: 2,
      ),
    ];
  }

  /// Elevated element color - lighter than card
  Color _getElevatedColor(bool isDark) {
    return isDark ? const Color(0xFF454545) : Colors.white;
  }

  /// Bevel shadow for raised elements
  List<BoxShadow> _getRaisedShadow(bool isDark) {
    return [
      // Top highlight
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.9),
        offset: const Offset(0, -1),
        blurRadius: 2,
      ),
      // Bottom shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
        offset: const Offset(0, 3),
        blurRadius: 6,
        spreadRadius: 1,
      ),
    ];
  }

  Widget _buildInputField(ThemeProvider themeProvider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _getElevatedColor(isDark),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _getRaisedShadow(isDark),
      ),
      child: TextFormField(
        controller: _titleController,
        validator: (value) {
          final required = Validators.required(value, fieldName: 'Title');
          if (required != null) return required;
          return Validators.maxLength(value, 200, fieldName: 'Title');
        },
        maxLength: 200, // Security: Limit input length
        textCapitalization: TextCapitalization.sentences,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) {
              // Only show counter when focused or near limit
              if (isFocused || currentLength > 80) {
                return Text(
                  '$currentLength/$maxLength',
                  style: TextStyle(
                    fontSize: 10,
                    color: currentLength > 90
                        ? Colors.red
                        : themeProvider.textSecondary.withValues(alpha: 0.5),
                  ),
                );
              }
              return null;
            },
        style: TextStyle(color: themeProvider.textPrimary),
        decoration: InputDecoration(
          labelText: 'Title',
          labelStyle: TextStyle(color: themeProvider.textSecondary),
          hintText: 'What do you want to accomplish?',
          hintStyle: TextStyle(
            color: themeProvider.textSecondary.withValues(alpha: 0.6),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeProvider.primaryColor,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(ThemeProvider themeProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: themeProvider.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildPriorityOption(
              1,
              'Low',
              const Color(0xFF10B981),
              themeProvider,
              isDark,
            ),
            const SizedBox(width: 10),
            _buildPriorityOption(
              2,
              'Medium',
              const Color(0xFFF59E0B),
              themeProvider,
              isDark,
            ),
            const SizedBox(width: 10),
            _buildPriorityOption(
              3,
              'High',
              const Color(0xFFEF4444),
              themeProvider,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityOption(
    int priority,
    String label,
    Color color,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    final isSelected = _selectedPriority == priority;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                : _getElevatedColor(isDark),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? _getActiveShadow(color, isDark)
                : _getRaisedShadow(isDark),
          ),
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : themeProvider.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Active/selected element shadow with color glow
  List<BoxShadow> _getActiveShadow(Color color, bool isDark) {
    return [
      // Color glow
      BoxShadow(
        color: color.withValues(alpha: isDark ? 0.4 : 0.3),
        offset: Offset.zero,
        blurRadius: 10,
      ),
      // Top highlight
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.9),
        offset: const Offset(0, -1),
        blurRadius: 2,
      ),
      // Bottom shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
        offset: const Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ];
  }

  Widget _buildCancelButton(ThemeProvider themeProvider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _getElevatedColor(isDark),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _getRaisedShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(ThemeProvider themeProvider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _getActiveShadow(themeProvider.primaryColor, isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addTodo,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'Add',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addTodo() {
    if (_formKey.currentState!.validate()) {
      widget.onAdd(
        title: _titleController.text.trim(),
        date: DateTime.now(),
        priority: _selectedPriority,
      );
      Navigator.of(context).pop();
    }
  }
}
