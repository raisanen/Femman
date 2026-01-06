import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz_card.dart';
import '../../models/card_result.dart';
import '../../models/category.dart';
import '../../providers/quiz_providers.dart';
import '../../providers/stats_providers.dart';

/// State for the quiz controller
class QuizState {
  final QuizCard? currentCard;
  final int currentQuestionIndex;
  final Map<Category, int?> answers;
  final DateTime? timeStarted;
  final bool isLoading;
  final String? error;

  const QuizState({
    this.currentCard,
    this.currentQuestionIndex = 0,
    required this.answers,
    this.timeStarted,
    this.isLoading = false,
    this.error,
  });

  /// Create initial state
  factory QuizState.initial() {
    return QuizState(
      answers: {for (final category in Category.values) category: null},
    );
  }

  /// Create loading state
  QuizState copyWithLoading() {
    return QuizState(
      currentCard: currentCard,
      currentQuestionIndex: currentQuestionIndex,
      answers: answers,
      timeStarted: timeStarted,
      isLoading: true,
      error: null,
    );
  }

  /// Create error state
  QuizState copyWithError(String error) {
    return QuizState(
      currentCard: currentCard,
      currentQuestionIndex: currentQuestionIndex,
      answers: answers,
      timeStarted: timeStarted,
      isLoading: false,
      error: error,
    );
  }

  /// Copy with new values
  QuizState copyWith({
    QuizCard? currentCard,
    int? currentQuestionIndex,
    Map<Category, int?>? answers,
    DateTime? timeStarted,
    bool? isLoading,
    String? error,
  }) {
    return QuizState(
      currentCard: currentCard ?? this.currentCard,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      timeStarted: timeStarted ?? this.timeStarted,
      isLoading: isLoading ?? false,
      error: error,
    );
  }

  /// Check if card is complete (all questions answered)
  bool get isComplete => answers.values.every((answer) => answer != null);

  /// Get duration since card started
  Duration? get duration {
    if (timeStarted == null) return null;
    return DateTime.now().difference(timeStarted!);
  }

  /// Get current question
  dynamic get currentQuestion {
    if (currentCard == null) return null;
    if (currentQuestionIndex < 0 || currentQuestionIndex >= 5) return null;
    return currentCard!.questions[currentQuestionIndex];
  }
}

/// Provider for the quiz controller
final quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  return QuizController(ref);
});

/// Controller for managing quiz flow
class QuizController extends StateNotifier<QuizState> {
  final Ref _ref;

  QuizController(this._ref) : super(QuizState.initial());

  /// Start a new quiz card
  /// Fetches questions at current adaptive difficulties
  Future<void> startNewCard() async {
    state = state.copyWithLoading();

    try {
      // Get quiz notifier to load new card
      final quizNotifier = _ref.read(quizNotifierProvider.notifier);
      await quizNotifier.loadNewCard();

      // Check if there was an error in the async operation
      final asyncValue = _ref.read(quizNotifierProvider);
      if (asyncValue.hasError) {
        state = state.copyWithError(
          'Failed to load quiz card: ${asyncValue.error}',
        );
        return;
      }

      // Get the loaded card from provider
      final card = _ref.read(currentCardProvider);

      if (card == null) {
        state = state.copyWithError(
          'Failed to load quiz card: No card was created. '
          'This might mean the question cache is empty or question generation failed.',
        );
        return;
      }

      // Update state with new card
      state = QuizState(
        currentCard: card,
        currentQuestionIndex: 0,
        answers: {for (final category in Category.values) category: null},
        timeStarted: DateTime.now(),
        isLoading: false,
      );
    } catch (error, stackTrace) {
      state = state.copyWithError(
        'Error loading card: $error',
      );
      // In debug mode, you might want to print stackTrace
      // ignore: avoid_print
      print('Quiz card loading error: $error\n$stackTrace');
    }
  }

  /// Select an answer for the current question
  void selectAnswer(int optionIndex) {
    if (state.currentCard == null) return;
    if (state.currentQuestionIndex < 0 || state.currentQuestionIndex >= 5) {
      return;
    }

    final question = state.currentCard!.questions[state.currentQuestionIndex];
    final newAnswers = {...state.answers};
    newAnswers[question.category] = optionIndex;

    state = state.copyWith(answers: newAnswers);

    // Also update the quiz providers
    _ref.read(cardAnswersProvider.notifier).state = newAnswers;
  }

  /// Move to the next question
  /// Returns true if moved, false if at end
  bool nextQuestion() {
    if (state.currentQuestionIndex < 4) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
      _ref.read(currentQuestionIndexProvider.notifier).state =
          state.currentQuestionIndex;
      return true;
    }
    return false;
  }

  /// Move to the previous question
  /// Returns true if moved, false if at start
  bool previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
      _ref.read(currentQuestionIndexProvider.notifier).state =
          state.currentQuestionIndex;
      return true;
    }
    return false;
  }

  /// Go to a specific question by index (0-4)
  void goToQuestion(int index) {
    if (index >= 0 && index < 5) {
      state = state.copyWith(currentQuestionIndex: index);
      _ref.read(currentQuestionIndexProvider.notifier).state = index;
    }
  }

  /// Build CardResult from current state
  /// Returns null if card is not complete
  CardResult? getCardResult() {
    if (state.currentCard == null || !state.isComplete) return null;

    final card = state.currentCard!;
    final resultMap = <Category, bool>{};

    // Check each answer against correct answer
    for (final question in card.questions) {
      final selectedAnswer = state.answers[question.category];
      final isCorrect = selectedAnswer == question.correctIndex;
      resultMap[question.category] = isCorrect;
    }

    // Calculate time taken (or use zero if no start time)
    final timeTaken = state.duration ?? Duration.zero;

    return CardResult(
      cardId: card.id,
      timeTaken: timeTaken,
      results: resultMap,
    );
  }

  /// Submit the completed card and record results
  Future<void> submitCard() async {
    if (!state.isComplete) {
      state = state.copyWithError('Cannot submit incomplete card');
      return;
    }

    final result = getCardResult();
    if (result == null) {
      state = state.copyWithError('Failed to build card result');
      return;
    }

    try {
      // Record the result in stats
      final statsNotifier = _ref.read(statsNotifierProvider.notifier);
      await statsNotifier.recordCardResult(result);

      // Clear the card after successful submission
      clearCard();
    } catch (error) {
      state = state.copyWithError('Error submitting card: $error');
    }
  }

  /// Clear current card and reset state
  void clearCard() {
    state = QuizState.initial();
    _ref.read(currentCardProvider.notifier).state = null;
    _ref.read(currentQuestionIndexProvider.notifier).state = 0;
    _ref.read(cardAnswersProvider.notifier).state = {
      for (final category in Category.values) category: null,
    };
  }

  /// Check if current question has been answered
  bool isCurrentQuestionAnswered() {
    if (state.currentCard == null) return false;
    final question = state.currentQuestion;
    if (question == null) return false;
    return state.answers[question.category] != null;
  }

  /// Get answer for current question
  int? getCurrentAnswer() {
    if (state.currentCard == null) return null;
    final question = state.currentQuestion;
    if (question == null) return null;
    return state.answers[question.category];
  }

  /// Get number of answered questions
  int getAnsweredCount() {
    return state.answers.values.where((answer) => answer != null).length;
  }

  /// Check if can advance to next question
  bool canAdvance() {
    return state.currentQuestionIndex < 4;
  }

  /// Check if can go back to previous question
  bool canGoBack() {
    return state.currentQuestionIndex > 0;
  }
}
