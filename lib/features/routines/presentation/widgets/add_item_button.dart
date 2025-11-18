import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/providers/theme_provider.dart';

class AddItemButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddItemButton({
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
          'Add Item',
          style: TextStyle(color: themeProvider.primaryColor),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: themeProvider.primaryColor,
          backgroundColor: themeProvider.cardColor,
          side: BorderSide(color: themeProvider.borderColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

