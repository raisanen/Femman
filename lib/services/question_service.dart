import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/quiz_card.dart';
import '../models/category.dart';
import '../models/difficulty.dart';
import 'json_question_loader.dart';

/// Service for loading and selecting questions from JSON assets.
/// Questions are kept in memory with simple usage tracking to avoid repetition.
class QuestionService {
  final JsonQuestionLoader _jsonLoader;
  List<Question> _allQuestions = [];
  final Set<String> _recentlyUsedIds = {};
  static const int _recentUsageWindow = 50; // Avoid repeating last 50 questions
  final _random = Random();

  QuestionService({
    required JsonQuestionLoader jsonLoader,
  }) : _jsonLoader = jsonLoader;

  /// Initialize the service by loading questions from JSON.
  Future<void> init() async {
    _allQuestions = await _jsonLoader.loadQuestions();
  }

  /// Get a quiz card with 5 questions (one per category) at specified difficulties
  Future<QuizCard> getQuizCard(Map<Category, Difficulty> difficulties) async {
    final questions = <Question>[];
    final missingCategories = <Category>[];

    // Get questions for each category
    for (final category in Category.values) {
      final difficulty = difficulties[category] ?? Difficulty.easy;
      Question? question = _getQuestion(category, difficulty);

      // If not found for requested difficulty, try any difficulty for this category
      if (question == null) {
        for (final fallbackDifficulty in Difficulty.values) {
          if (fallbackDifficulty != difficulty) {
            question = _getQuestion(category, fallbackDifficulty);
            if (question != null) break;
          }
        }
      }

      // Add question if found
      if (question != null) {
        questions.add(question);
        _recentlyUsedIds.add(question.id);
        
        // Keep only recent N questions in the set
        if (_recentlyUsedIds.length > _recentUsageWindow) {
          // Remove oldest entries (simple approach: keep set size manageable)
          final idsToRemove = _recentlyUsedIds.toList().take(
            _recentlyUsedIds.length - _recentUsageWindow,
          );
          for (final id in idsToRemove) {
            _recentlyUsedIds.remove(id);
          }
        }
      } else {
        missingCategories.add(category);
      }
    }

    // If we don't have 5 questions, throw a clear error
    if (questions.length != 5) {
      final buffer = StringBuffer();
      buffer.writeln('Failed to load quiz card: Only found ${questions.length}/5 questions.');
      buffer.writeln('Missing categories: ${missingCategories.map((c) => c.toString().split('.').last).join(', ')}.');
      buffer.writeln('Total questions loaded: ${_allQuestions.length}');
      
      if (_allQuestions.isEmpty) {
        buffer.writeln('No questions loaded from JSON. Check assets/questions.json.');
      } else {
        // Show breakdown by category/difficulty
        buffer.writeln('Question breakdown by category/difficulty:');
        for (final category in Category.values) {
          final catName = category.toString().split('.').last;
          final catQuestions = _allQuestions.where((q) => q.category == category).toList();
          if (catQuestions.isEmpty) {
            buffer.writeln('  $catName: none');
          } else {
            final byDifficulty = <Difficulty, int>{};
            for (final q in catQuestions) {
              byDifficulty[q.difficulty] = (byDifficulty[q.difficulty] ?? 0) + 1;
            }
            buffer.writeln('  $catName: ${byDifficulty.entries.map((e) => '${e.key.toString().split('.').last}=${e.value}').join(', ')}');
          }
        }
      }
      
      throw Exception(buffer.toString());
    }

    // Create quiz card
    final quizCard = QuizCard.fromQuestions(
      id: const Uuid().v4(),
      questions: questions,
    );

    return quizCard;
  }

  /// Get a random question for the specified category and difficulty
  /// Avoids recently used questions
  Question? _getQuestion(Category category, Difficulty difficulty) {
    // Filter questions by category and difficulty, excluding recently used
    final candidates = _allQuestions.where((q) {
      return q.category == category &&
          q.difficulty == difficulty &&
          !_recentlyUsedIds.contains(q.id);
    }).toList();

    if (candidates.isEmpty) {
      // If no unused questions, try getting any question for this category/difficulty
      final allCandidates = _allQuestions.where((q) {
        return q.category == category && q.difficulty == difficulty;
      }).toList();

      if (allCandidates.isEmpty) return null;

      // Return random from all candidates
      return allCandidates[_random.nextInt(allCandidates.length)];
    }

    // Return random from unused candidates
    return candidates[_random.nextInt(candidates.length)];
  }

  /// Warmup on app startup (ensures questions are loaded)
  /// Questions are already loaded during init, so this is a no-op
  Future<void> warmupCache() async {
    // Questions are already loaded during init
  }

  /// Clear usage history (allows questions to be repeated immediately)
  void clearUsageHistory() {
    _recentlyUsedIds.clear();
  }

  /// Get total number of loaded questions
  int get totalQuestions => _allQuestions.length;

  /// Dispose resources
  void dispose() {
    _allQuestions.clear();
    _recentlyUsedIds.clear();
  }
}
