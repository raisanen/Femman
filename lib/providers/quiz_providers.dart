import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_service.dart';
import '../services/json_question_loader.dart';
import '../services/github_question_loader.dart';
import '../models/quiz_card.dart';
import '../models/category.dart';
import 'stats_providers.dart';

/// Provider for JsonQuestionLoader singleton (fallback)
final jsonQuestionLoaderProvider = Provider<JsonQuestionLoader>((ref) {
  return JsonQuestionLoader();
});

/// Provider for GitHubQuestionLoader singleton
final githubQuestionLoaderProvider = Provider<GitHubQuestionLoader>((ref) {
  final loader = GitHubQuestionLoader();
  ref.onDispose(() => loader.dispose());
  return loader;
});

/// Provider for the QuestionService singleton instance
final questionServiceProvider = Provider<QuestionService>((ref) {
  final service = QuestionService(
    jsonLoader: ref.watch(jsonQuestionLoaderProvider),
    githubLoader: ref.watch(githubQuestionLoaderProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the current quiz card (nullable)
final currentCardProvider = StateProvider<QuizCard?>((ref) => null);

/// Provider for the current question index (0-4)
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for card answers (Map of Category to int? where int is option index)
final cardAnswersProvider = StateProvider<Map<Category, int?>>((ref) {
  return {
    for (final category in Category.values) category: null,
  };
});

/// Provider to check if all 5 questions have been answered
final isCardCompleteProvider = Provider<bool>((ref) {
  final answers = ref.watch(cardAnswersProvider);
  return answers.values.every((answer) => answer != null);
});

/// Provider for the current question (derived from card and index)
final currentQuestionProvider = Provider((ref) {
  final card = ref.watch(currentCardProvider);
  final index = ref.watch(currentQuestionIndexProvider);

  if (card == null || index < 0 || index >= 5) return null;
  return card.questions[index];
});

/// Notifier for managing quiz state and operations
final quizNotifierProvider =
    StateNotifierProvider<QuizNotifier, AsyncValue<void>>((ref) {
  return QuizNotifier(
    ref.watch(questionServiceProvider),
    ref,
  );
});

/// Notifier for quiz operations
class QuizNotifier extends StateNotifier<AsyncValue<void>> {
  final QuestionService _questionService;
  final Ref _ref;

  QuizNotifier(this._questionService, this._ref)
      : super(const AsyncValue.data(null));

  /// Load a new quiz card with questions at current difficulties
  Future<void> loadNewCard() async {
    state = const AsyncValue.loading();
    try {
      // Get difficulties from stats (adaptive)
      final difficulties = _ref.read(allDifficultiesProvider);

      // Get a new quiz card
      final card = await _questionService.getQuizCard(difficulties);

      // Update providers
      _ref.read(currentCardProvider.notifier).state = card;
      _ref.read(currentQuestionIndexProvider.notifier).state = 0;
      _ref.read(cardAnswersProvider.notifier).state = {
        for (final category in Category.values) category: null,
      };

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Set the answer for the current question
  void answerCurrentQuestion(int optionIndex) {
    final card = _ref.read(currentCardProvider);
    final index = _ref.read(currentQuestionIndexProvider);

    if (card == null || index < 0 || index >= 5) return;

    final question = card.questions[index];
    final answers = {..._ref.read(cardAnswersProvider)};
    answers[question.category] = optionIndex;

    _ref.read(cardAnswersProvider.notifier).state = answers;
  }

  /// Move to the next question (if not at the end)
  void nextQuestion() {
    final index = _ref.read(currentQuestionIndexProvider);
    if (index < 4) {
      _ref.read(currentQuestionIndexProvider.notifier).state = index + 1;
    }
  }

  /// Move to the previous question (if not at the start)
  void previousQuestion() {
    final index = _ref.read(currentQuestionIndexProvider);
    if (index > 0) {
      _ref.read(currentQuestionIndexProvider.notifier).state = index - 1;
    }
  }

  /// Go to a specific question by index
  void goToQuestion(int index) {
    if (index >= 0 && index < 5) {
      _ref.read(currentQuestionIndexProvider.notifier).state = index;
    }
  }

  /// Clear current card and reset state
  void clearCard() {
    _ref.read(currentCardProvider.notifier).state = null;
    _ref.read(currentQuestionIndexProvider.notifier).state = 0;
    _ref.read(cardAnswersProvider.notifier).state = {
      for (final category in Category.values) category: null,
    };
  }


  /// Warmup on app startup (ensures questions are loaded)
  Future<void> warmupCache() async {
    try {
      await _questionService.warmupCache();
    } catch (error) {
      // Silent fail for warmup
      // In production, log this error
    }
  }
}
