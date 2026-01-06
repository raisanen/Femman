import 'package:flutter/material.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/models/category.dart';
import 'package:femman/core/constants/app_spacing.dart';

/// Category label widget
///
/// - Displays localized category name
/// - Optional colour accent bar
/// - Uppercase, subtle Swiss-typography styling
class CategoryLabel extends StatelessWidget {
  const CategoryLabel({
    super.key,
    required this.category,
    required this.language,
    this.showAccentBar = true,
  });

  /// Question category
  final Category category;

  /// Current app language
  final AppLanguage language;

  /// Whether to show the coloured accent bar to the left
  final bool showAccentBar;

  @override
  Widget build(BuildContext context) {
    final labelText = category.localizedName(language).toUpperCase();

    final label = Text(
      labelText,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!showAccentBar) {
      return label;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 16,
          color: category.color,
        ),
        const SizedBox(width: AppSpacing.sm),
        label,
      ],
    );
  }
}
