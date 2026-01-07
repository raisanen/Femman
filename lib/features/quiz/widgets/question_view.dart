import 'package:flutter/material.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/models/question.dart';
import 'package:femman/core/constants/app_strings.dart' show AppLanguage;
import 'package:femman/features/quiz/widgets/answer_button.dart';
import 'package:femman/features/quiz/widgets/category_label.dart';

/// Displays a single quiz question.
///
/// Layout:
/// - Category label at top-left
/// - Question number at top-right (e.g. "3/5")
/// - Question text centered with generous padding
/// - Four answer buttons stacked vertically
/// - Fun fact area shown after answering (if available)
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.selectedAnswer,
    required this.showResult,
    required this.onAnswerSelected,
    required this.language,
  });

  /// Question to display
  final Question question;

  /// 1-based question number (1–5)
  final int questionNumber;

  /// Index of selected answer, or null if not answered
  final int? selectedAnswer;

  /// Whether to reveal correct/incorrect state
  final bool showResult;

  /// Callback when an answer is selected
  final void Function(int index) onAnswerSelected;

  /// Current app language
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final options = question.getOptions(language);
    final isAnswered = selectedAnswer != null;
    final funFact = question.getFunFact(language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: category label + question number
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CategoryLabel(
                category: question.category,
                language: language,
              ),
              Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return Text(
                    '$questionNumber/5',
                    style: AppTypography.labelLarge.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Question text
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Text(
                question.getText(language),
                style: AppTypography.bodyLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Answer options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = selectedAnswer == index;
              final isCorrect = showResult && index == question.correctIndex;
              final isIncorrect =
                  showResult && isSelected && index != question.correctIndex;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == options.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: AnswerButton(
                  text: optionText,
                  onTap: () => onAnswerSelected(index),
                  isSelected: isSelected && !showResult,
                  isCorrect: isCorrect,
                  isIncorrect: isIncorrect,
                  isDisabled: isAnswered,
                ),
              );
            }),
          ),
        ),

        // Fun fact (after answering, if available)
        if (isAnswered && funFact != null && funFact.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.funFact(language).toUpperCase(),
                          style: AppTypography.labelMedium.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          funFact,
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
