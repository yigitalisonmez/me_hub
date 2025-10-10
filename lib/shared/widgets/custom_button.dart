import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Özel buton widget'ı
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !isEnabled || isLoading || onPressed == null;
    
    return SizedBox(
      width: width,
      height: height ?? _getHeight(),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _getButtonStyle(context, isDisabled),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getTextColor(),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(text, style: _getTextStyle()),
        ],
      );
    }

    return Text(text, style: _getTextStyle());
  }

  ButtonStyle _getButtonStyle(BuildContext context, bool isDisabled) {
    final baseStyle = ElevatedButton.styleFrom(
      elevation: isDisabled ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );

    switch (type) {
      case ButtonType.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return AppColors.lightGrey;
            return backgroundColor ?? AppColors.primaryOrange;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return AppColors.grey;
            return textColor ?? AppColors.white;
          }),
        );
      
      case ButtonType.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return AppColors.lightGrey;
            return backgroundColor ?? AppColors.secondaryCream;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return AppColors.grey;
            return textColor ?? AppColors.white;
          }),
        );
      
      case ButtonType.outline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return AppColors.lightGrey;
            return backgroundColor ?? AppColors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return AppColors.grey;
            return textColor ?? AppColors.primaryOrange;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return const BorderSide(color: AppColors.grey);
            return BorderSide(color: textColor ?? AppColors.primaryOrange);
          }),
        );
      
      case ButtonType.text:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return AppColors.grey;
            return textColor ?? AppColors.primaryOrange;
          }),
          elevation: WidgetStateProperty.all(0),
        );
    }
  }

  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: _getFontSize(),
      fontWeight: FontWeight.w600,
      color: _getTextColor(),
    );
  }

  Color _getTextColor() {
    if (!isEnabled || isLoading) return AppColors.grey;
    
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return textColor ?? AppColors.white;
      case ButtonType.outline:
      case ButtonType.text:
        return textColor ?? AppColors.primaryOrange;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.medium:
        return 40;
      case ButtonSize.large:
        return 48;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 6;
      case ButtonSize.medium:
        return 8;
      case ButtonSize.large:
        return 10;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }
}

/// Buton türleri
enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}

/// Buton boyutları
enum ButtonSize {
  small,
  medium,
  large,
}
