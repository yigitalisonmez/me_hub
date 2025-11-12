import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class AddItemButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddItemButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text('Add Item'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

