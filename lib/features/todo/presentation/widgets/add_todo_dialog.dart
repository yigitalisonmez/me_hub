import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';

/// Add todo dialog
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

    return AlertDialog(
      backgroundColor: themeProvider.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      title: Text(
        'Add New Todo',
        style: TextStyle(
          color: themeProvider.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Title',
                hint: 'What do you want to accomplish?',
                controller: _titleController,
                validator: (value) =>
                    Validators.required(value, fieldName: 'Title'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              _buildPrioritySelector(),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: BorderSide(color: themeProvider.borderColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: themeProvider.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _addTodo,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Add',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    final themeProvider = context.watch<ThemeProvider>();

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
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPriorityOption(1, 'Low', const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _buildPriorityOption(2, 'Medium', const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            _buildPriorityOption(3, 'High', const Color(0xFFEF4444)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityOption(int priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;
    final themeProvider = context.watch<ThemeProvider>();

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : themeProvider.borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : themeProvider.textSecondary,
                ),
              ),
            ],
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
