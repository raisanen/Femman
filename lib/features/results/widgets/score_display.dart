import 'package:flutter/material.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/core/constants/app_strings.dart' show AppLanguage;
import 'package:femman/models/card_result.dart';

/// Displays the overall score for a completed card.
class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({
    super.key,
    required this.result,
    required this.language,
  });

  final CardResult result;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreText = AppStrings.scoreDisplay(
      language,
      result.score,
      result.results.length,
    );

    String subtitle;
    if (result.isPerfect) {
      subtitle = AppStrings.perfectScore(language);
    } else if (result.score >= 3) {
      subtitle = AppStrings.goodScore(language);
    } else {
      subtitle = AppStrings.keepTrying(language);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${result.score}/${result.results.length}',
          style: AppTypography.displayLarge.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          scoreText,
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.labelMedium.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
