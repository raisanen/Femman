import 'package:flutter/material.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/core/constants/app_spacing.dart';

/// Progress indicator for a 5-question card.
///
/// - Filled (●) = answered
/// - Half (◐) = current
/// - Empty (○) = upcoming
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.currentIndex,
    required this.answeredCount,
    this.total = 5,
  });

  /// Index of the current question (0-based)
  final int currentIndex;

  /// Number of questions that have been answered
  final int answeredCount;

  /// Total number of questions in the card (defaults to 5)
  final int total;

  @override
  Widget build(BuildContext context) {
    final dots = List<Widget>.generate(total, (index) {
      final symbol = _symbolForIndex(index);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          symbol,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots,
    );
  }

  String _symbolForIndex(int index) {
    if (index < answeredCount) {
      return '●'; // answered
    }
    if (index == currentIndex) {
      return '◐'; // current
    }
    return '○'; // upcoming
  }
}

