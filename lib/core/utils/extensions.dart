import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Extension methods for easier theme color access
extension ThemeColors on BuildContext {
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textSecondary => Theme.of(this).colorScheme.onSurface.withOpacity(0.7);
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get borderColor => Theme.of(this).brightness == Brightness.dark
      ? AppColors.borderDefaultDark
      : AppColors.borderDefault;
}
