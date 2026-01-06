import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/quiz_card.dart';
import '../models/category.dart';
import '../models/difficulty.dart';
import 'question_cache_service.dart';
import 'json_question_loader.dart';

/// Orchestrates question loading from JSON and caching.
/// Loads questions from JSON assets and caches them for quick access.
class QuestionService {
  final QuestionCacheService _cacheService;
  final JsonQuestionLoader _jsonLoader;

  // Cache health thresholds
  static const int _minQuestionsPerCategoryDifficulty = 10;

  QuestionService({
    required QuestionCacheService cacheService,
    required JsonQuestionLoader jsonLoader,
  })  : _cacheService = cacheService,
        _jsonLoader = jsonLoader;

  /// Initialize all sub-services.
  /// Loads questions from JSON and caches them.
  Future<void> init() async {
    await _cacheService.init();
    
    // Load questions from JSON and cache them
    final questions = await _jsonLoader.loadQuestions();
    await _cacheService.cacheQuestions(questions);
  }

  /// Get a quiz card with 5 questions (one per category) at specified difficulties
  /// Uses cached questions from JSON
  Future<QuizCard> getQuizCard(Map<Category, Difficulty> difficulties) async {
    final questions = <Question>[];
    final missingCategories = <Category>[];

    // Try to get questions from cache
    for (final category in Category.values) {
      final difficulty = difficulties[category] ?? Difficulty.easy;
      Question? question = _cacheService.getQuestion(category, difficulty);

      // If cache miss for requested difficulty, try any difficulty for this category
      if (question == null) {
        for (final fallbackDifficulty in Difficulty.values) {
          if (fallbackDifficulty != difficulty) {
            question = _cacheService.getQuestion(category, fallbackDifficulty);
            if (question != null) break;
          }
        }
      }

      // Add question if found
      if (question != null) {
        questions.add(question);
      } else {
        missingCategories.add(category);
      }
    }

    // If we don't have 5 questions, throw a clear error with diagnostics
    if (questions.length != 5) {
      final cacheCounts = _cacheService.getQuestionCounts();
      final totalCacheCount = _cacheService.getTotalQuestionCount();
      
      // Build a detailed error message
      final buffer = StringBuffer();
      buffer.writeln('Failed to load quiz card: Only found ${questions.length}/5 questions.');
      buffer.writeln('Missing categories: ${missingCategories.map((c) => c.toString().split('.').last).join(', ')}.');
      buffer.writeln('Total questions in cache: $totalCacheCount');
      
      if (totalCacheCount == 0) {
        buffer.writeln('Cache is empty. Questions may not have loaded from JSON properly.');
      } else {
        buffer.writeln('Cache breakdown by category/difficulty:');
        for (final category in Category.values) {
          final catName = category.toString().split('.').last;
          final counts = cacheCounts[category] ?? {};
          final catTotal = counts.values.fold(0, (a, b) => a + b);
          if (catTotal > 0) {
            buffer.writeln('  $catName: ${counts.entries.map((e) => '${e.key.toString().split('.').last}=${e.value}').join(', ')}');
          } else {
            buffer.writeln('  $catName: none');
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

  /// Get cache health statistics
  CacheStats getCacheHealth() {
    return _cacheService.getCacheStats();
  }

  /// Warmup cache on app startup
  /// Ensures questions are loaded from JSON
  Future<void> warmupCache() async {
    // Questions are already loaded from JSON during init
    // This method is kept for compatibility but does nothing
  }

  /// Check if cache is healthy (has minimum questions for all combinations)
  bool isCacheHealthy() {
    final health = getCacheHealth();

    for (final category in Category.values) {
      for (final difficulty in Difficulty.values) {
        if (health.getCount(category, difficulty) <
            _minQuestionsPerCategoryDifficulty) {
          return false;
        }
      }
    }

    return true;
  }

  /// Get cache health summary
  CacheHealthSummary getCacheHealthSummary() {
    final health = getCacheHealth();
    int healthyCount = 0;
    int lowCount = 0;
    int emptyCount = 0;

    for (final category in Category.values) {
      for (final difficulty in Difficulty.values) {
        final count = health.getCount(category, difficulty);
        if (count >= _minQuestionsPerCategoryDifficulty) {
          healthyCount++;
        } else if (count > 0) {
          lowCount++;
        } else {
          emptyCount++;
        }
      }
    }

    return CacheHealthSummary(
      totalCombinations: Category.values.length * Difficulty.values.length,
      healthyCombinations: healthyCount,
      lowCombinations: lowCount,
      emptyCombinations: emptyCount,
      totalQuestions: health.totalQuestions,
      isGenerating: false,
    );
  }

  /// Clear all cached questions
  Future<void> clearCache() async {
    await _cacheService.clearAll();
  }

  /// Clear usage history (allows questions to be repeated)
  Future<void> clearUsageHistory() async {
    await _cacheService.clearUsageHistory();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _cacheService.dispose();
  }
}

/// Summary of cache health across all category/difficulty combinations
class CacheHealthSummary {
  final int totalCombinations;
  final int healthyCombinations;
  final int lowCombinations;
  final int emptyCombinations;
  final int totalQuestions;
  final bool isGenerating;

  CacheHealthSummary({
    required this.totalCombinations,
    required this.healthyCombinations,
    required this.lowCombinations,
    required this.emptyCombinations,
    required this.totalQuestions,
    required this.isGenerating,
  });

  /// Overall health percentage (0.0 to 1.0)
  double get healthPercentage =>
      totalCombinations > 0 ? healthyCombinations / totalCombinations : 0.0;

  /// Whether the cache is considered healthy overall
  bool get isHealthy => emptyCombinations == 0 && lowCombinations == 0;

  /// Status message
  String get statusMessage {
    if (isHealthy) {
      return 'Cache is healthy with $totalQuestions questions';
    } else if (emptyCombinations > 0) {
      return 'Cache needs warmup: $emptyCombinations empty slots';
    } else {
      return 'Cache is low: $lowCombinations slots need refill';
    }
  }
}

/// Helper to run futures without awaiting (for fire-and-forget)
void unawaited(Future<void> future) {
  future.catchError((error) {
    // In production, this should use proper logging
    // ignore: avoid_print
    print('Background task error: $error');
  });
}
