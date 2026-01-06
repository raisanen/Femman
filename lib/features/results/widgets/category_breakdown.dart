import 'package:flutter/material.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/core/constants/app_strings.dart' show AppLanguage;
import 'package:femman/models/card_result.dart';
import 'package:femman/models/category.dart';

/// Shows per-category correctness for a completed card as a clean vertical list.
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
      children: Category.values.map((category) {
        final isCorrect = result.isCorrect(category);
        final label = category.localizedName(language);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              // Coloured dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              // Category name
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // ✓ / ✗ indicator
              Text(
                isCorrect ? '✓' : '✗',
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      isCorrect ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
