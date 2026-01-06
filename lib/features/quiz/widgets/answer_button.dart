import 'package:flutter/material.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';

/// Answer button widget
///
/// - Full-width button with answer text
/// - States: default, selected, correct, incorrect, disabled
/// - Subtle border styling following Swiss typography design
class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    this.isCorrect = false,
    this.isIncorrect = false,
    this.isDisabled = false,
  });

  /// Answer text to display
  final String text;

  /// Tap callback (ignored when disabled)
  final VoidCallback? onTap;

  /// Whether this option is currently selected
  final bool isSelected;

  /// Whether this option is the correct answer (for feedback state)
  final bool isCorrect;

  /// Whether this option is an incorrect selection (for feedback state)
  final bool isIncorrect;

  /// Whether the button is disabled (e.g., after answering)
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = isDisabled ? null : onTap;

    final colors = _resolveColors();

    return Opacity(
      opacity: isDisabled ? 0.7 : 1.0,
      child: InkWell(
        onTap: effectiveOnTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colors.border,
              width: 1,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AnswerButtonColors _resolveColors() {
    // Correct state has top priority
    if (isCorrect) {
      return _AnswerButtonColors(
        background: AppColors.accent,
        border: AppColors.accent,
        text: AppColors.white,
      );
    }

    // Incorrect state
    if (isIncorrect) {
      return _AnswerButtonColors(
        background: AppColors.textSecondary.withOpacity(0.08),
        border: AppColors.textSecondary,
        text: AppColors.textPrimary,
      );
    }

    // Selected state (pre-feedback)
    if (isSelected) {
      return _AnswerButtonColors(
        background: AppColors.white,
        border: AppColors.textPrimary,
        text: AppColors.textPrimary,
      );
    }

    // Default state
    return _AnswerButtonColors(
      background: AppColors.white,
      border: AppColors.borderDefault,
      text: AppColors.textPrimary,
    );
  }
}

class _AnswerButtonColors {
  const _AnswerButtonColors({
    required this.background,
    required this.border,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color text;
}

