import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/quiz_card.dart';
import '../models/category.dart';
import '../models/difficulty.dart';
import 'json_question_loader.dart';
import 'github_question_loader.dart';

/// Service for loading and selecting questions from GitHub or JSON assets.
/// Questions are kept in memory with simple usage tracking to avoid repetition.
class QuestionService {
  final JsonQuestionLoader _jsonLoader;
  final GitHubQuestionLoader _githubLoader;
  List<Question> _allQuestions = [];
  final Set<String> _recentlyUsedIds = {};
  static const int _recentUsageWindow = 20; // Avoid repeating last 20 questions (reduced for small question pools)
  final _random = Random();
  bool _loadedFromGitHub = false;

  QuestionService({
    required JsonQuestionLoader jsonLoader,
    required GitHubQuestionLoader githubLoader,
  }) : _jsonLoader = jsonLoader,
       _githubLoader = githubLoader;

  /// Initialize the service by loading questions from GitHub, falling back to assets.
  Future<void> init() async {
    try {
      // Try loading from GitHub first
      _allQuestions = await _githubLoader.loadQuestions();
      _loadedFromGitHub = true;
      // ignore: avoid_print
      print('Successfully loaded questions from GitHub');
    } catch (e) {
      // Fall back to asset loading
      // ignore: avoid_print
      print('GitHub loading failed, falling back to assets: $e');
      _allQuestions = await _jsonLoader.loadQuestions();
      _loadedFromGitHub = false;
    }
  }

  /// Reload questions from GitHub, ensuring no duplicates
  /// Merges new questions with existing ones, removing duplicates by ID
  Future<void> reloadFromGitHub() async {
    try {
      final newQuestions = await _githubLoader.loadQuestions();
      
      // Create a map of existing question IDs for quick lookup
      final existingIds = _allQuestions.map((q) => q.id).toSet();
      
      // Filter out questions that already exist
      final uniqueNewQuestions = newQuestions
          .where((q) => !existingIds.contains(q.id))
          .toList();
      
      // Merge: keep existing questions, add only new ones
      _allQuestions = [..._allQuestions, ...uniqueNewQuestions];
      _loadedFromGitHub = true;
      
      // Clear usage history since we have new questions
      _recentlyUsedIds.clear();
      
      // ignore: avoid_print
      print('Reloaded questions from GitHub: ${uniqueNewQuestions.length} new questions added, ${_allQuestions.length} total');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to reload questions from GitHub: $e');
      rethrow;
    }
  }

  /// Check if questions were loaded from GitHub
  bool get loadedFromGitHub => _loadedFromGitHub;

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
        // Use a simple approach: if we exceed the window, clear half of it
        if (_recentlyUsedIds.length > _recentUsageWindow * 2) {
          // Clear the set and start fresh to avoid memory issues
          // This allows questions to be reused after a while
          _recentlyUsedIds.clear();
          // Re-add current question to the fresh set
          _recentlyUsedIds.add(question.id);
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
      // If no unused questions, clear the tracking for this category/difficulty
      // and try again, or fall back to any question
      final allCandidates = _allQuestions.where((q) {
        return q.category == category && q.difficulty == difficulty;
      }).toList();

      if (allCandidates.isEmpty) return null;

      // If we have very few questions, allow reuse by clearing tracking
      if (allCandidates.length <= 5) {
        // Clear recently used IDs for this category to allow reuse
        final categoryQuestionIds = allCandidates.map((q) => q.id).toSet();
        _recentlyUsedIds.removeWhere((id) => categoryQuestionIds.contains(id));
        // Try again with fresh candidates
        final freshCandidates = _allQuestions.where((q) {
          return q.category == category &&
              q.difficulty == difficulty &&
              !_recentlyUsedIds.contains(q.id);
        }).toList();
        if (freshCandidates.isNotEmpty) {
          return freshCandidates[_random.nextInt(freshCandidates.length)];
        }
      }

      // Return random from all candidates as fallback
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
