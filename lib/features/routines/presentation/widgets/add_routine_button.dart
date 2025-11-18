import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class AddRoutineButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddRoutineButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(LucideIcons.plus, size: 20, color: themeProvider.primaryColor),
        label: Text(
                  'Add New Routine',
                  style: TextStyle(
            color: themeProvider.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        style: OutlinedButton.styleFrom(
          foregroundColor: themeProvider.primaryColor,
          backgroundColor: themeProvider.cardColor,
          side: BorderSide(color: themeProvider.borderColor, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

