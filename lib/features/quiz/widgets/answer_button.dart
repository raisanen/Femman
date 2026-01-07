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
    final theme = Theme.of(context);
    final effectiveOnTap = isDisabled ? null : onTap;

    final colors = _resolveColors(theme);

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

  _AnswerButtonColors _resolveColors(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDefaultDark : AppColors.borderDefault;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.white;
    
    // Correct state has top priority
    if (isCorrect) {
      return _AnswerButtonColors(
        background: theme.colorScheme.primary,
        border: theme.colorScheme.primary,
        text: AppColors.white,
      );
    }

    // Incorrect state
    if (isIncorrect) {
      return _AnswerButtonColors(
        background: theme.colorScheme.onSurface.withOpacity(0.08),
        border: theme.colorScheme.onSurface.withOpacity(0.7),
        text: theme.colorScheme.onSurface,
      );
    }

    // Selected state (pre-feedback)
    if (isSelected) {
      return _AnswerButtonColors(
        background: backgroundColor,
        border: theme.colorScheme.onSurface,
        text: theme.colorScheme.onSurface,
      );
    }

    // Default state
    return _AnswerButtonColors(
      background: backgroundColor,
      border: borderColor,
      text: theme.colorScheme.onSurface,
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

