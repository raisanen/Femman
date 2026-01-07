import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_typography.dart';
import 'package:femman/features/quiz/quiz_controller.dart';
import 'package:femman/features/quiz/widgets/question_view.dart';
import 'package:femman/features/quiz/widgets/progress_dots.dart';
import 'package:femman/providers/settings_providers.dart';

/// Main game screen showing a 5-question quiz card.
///
/// Flow:
/// 1. On mount, start new card if none exists
/// 2. Display current question
/// 3. On answer selected, show result briefly (1.5s or tap to continue)
/// 4. Advance to next question
/// 5. After question 5, navigate to Results screen
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _showResult = false;
  Timer? _resultTimer;

  @override
  void initState() {
    super.initState();

    // Always start a new card when this screen is mounted
    // This ensures a fresh card when navigating from results screen or home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizControllerProvider.notifier).startNewCard();
    });
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizControllerProvider);
    final language = ref.watch(languageProvider);

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppStrings.appTitle(language),
          style: AppTypography.headlineMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_showResult) {
              _resultTimer?.cancel();
              _advanceOrFinish();
            }
          },
          child: _buildBody(context, quizState, language),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    QuizState quizState,
    AppLanguage language,
  ) {
    final theme = Theme.of(context);
    
    // Loading state
    if (quizState.isLoading && quizState.currentCard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.generatingQuestions(language),
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Error or empty state
    if (quizState.error != null || quizState.currentCard == null) {
      final errorText = quizState.error ?? AppStrings.errorLoadingQuestions(language);

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.error(language),
                style: AppTypography.headlineMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorText,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  ref.read(quizControllerProvider.notifier).startNewCard();
                },
                child: Text(AppStrings.retry(language)),
              ),
            ],
          ),
        ),
      );
    }

    // Normal question display
    final question = quizState.currentQuestion;
    if (question == null) {
      return const SizedBox.shrink();
    }

    final selectedAnswer =
        ref.watch(quizControllerProvider.notifier).getCurrentAnswer();
    final answeredCount =
        ref.watch(quizControllerProvider.notifier).getAnsweredCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: QuestionView(
              key: ValueKey(quizState.currentQuestionIndex),
              question: question,
              questionNumber: quizState.currentQuestionIndex + 1,
              selectedAnswer: selectedAnswer,
              showResult: _showResult,
              onAnswerSelected: _handleAnswerSelected,
              language: language,
              shuffledCorrectIndex: quizState.shuffledCorrectIndices[question.category],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_showResult)
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  AppStrings.tapToContinue(language),
                  style: AppTypography.labelMedium.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
          ),
          child: ProgressDots(
            currentIndex: quizState.currentQuestionIndex,
            answeredCount: answeredCount,
          ),
        ),
      ],
    );
  }

  void _handleAnswerSelected(int index) {
    final controller = ref.read(quizControllerProvider.notifier);

    // Ignore if already showing result or question answered
    if (_showResult || controller.isCurrentQuestionAnswered()) {
      return;
    }

    controller.selectAnswer(index);

    setState(() {
      _showResult = true;
    });

    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(milliseconds: 1500), () {
      _advanceOrFinish();
    });
  }

  void _advanceOrFinish() {
    final controller = ref.read(quizControllerProvider.notifier);

    _resultTimer?.cancel();

    // If there are more questions, move to next
    if (controller.canAdvance()) {
      controller.nextQuestion();
      setState(() {
        _showResult = false;
      });
      return;
    }

    // Final question: build result and navigate to results
    final result = controller.getCardResult();
    if (result == null) {
      // Fallback: just reset UI
      setState(() {
        _showResult = false;
      });
      return;
    }

    setState(() {
      _showResult = false;
    });

    Navigator.of(context).pushReplacementNamed(
      '/results',
      arguments: result,
    );
  }
}
