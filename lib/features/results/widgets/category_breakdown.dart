import 'package:flutter/material.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/core/constants/app_strings.dart' show AppLanguage;
import 'package:femman/models/card_result.dart';
import 'package:femman/models/category.dart';

/// Shows per-category correctness for a completed card.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.result,
    required this.language,
  });

  final CardResult result;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.categoryBreakdown(language),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...Category.values.map((category) {
          final isCorrect = result.isCorrect(category);
          final label = category.localizedName(language);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isCorrect
                      ? AppStrings.correct(language)
                      : AppStrings.incorrect(language),
                  style: AppTypography.labelMedium.copyWith(
                    color: isCorrect
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
