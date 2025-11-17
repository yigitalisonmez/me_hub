import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Me Hub uygulaması için özel tema uzantıları
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.primaryGradient,
    required this.cardGradient,
    required this.backgroundGradient,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final LinearGradient primaryGradient;
  final LinearGradient cardGradient;
  final LinearGradient backgroundGradient;

  @override
  AppColorScheme copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    LinearGradient? primaryGradient,
    LinearGradient? cardGradient,
    LinearGradient? backgroundGradient,
  }) {
    return AppColorScheme(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) {
      return this;
    }
    return AppColorScheme(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
    );
  }

  static const AppColorScheme light = AppColorScheme(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    primaryGradient: AppColors.primaryGradient,
    cardGradient: AppColors.cardGradient,
    backgroundGradient: AppColors.backgroundGradient,
  );

  static const AppColorScheme dark = AppColorScheme(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    primaryGradient: AppColors.darkPrimaryGradient,
    cardGradient: LinearGradient(
      colors: [AppColors.darkCard, AppColors.darkSurface],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    backgroundGradient: LinearGradient(
      colors: [AppColors.darkBackground, AppColors.darkCard],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}

/// Tema uzantılarına erişim için extension
extension AppColorSchemeExtension on ThemeData {
  AppColorScheme get appColorScheme => extension<AppColorScheme>()!;
}
