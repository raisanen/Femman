import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/quiz_card.dart';
import '../models/category.dart';
import '../models/difficulty.dart';
import 'question_cache_service.dart';
import 'gemini_ai_service.dart';

/// Orchestrates question caching and generation.
/// Prefers cached questions for instant response, generates on-demand when needed.
class QuestionService {
  final QuestionCacheService _cacheService;
  final GeminiAIService _aiService;

  bool _mockMode = false;

  // Cache health thresholds
  static const int _minQuestionsPerCategoryDifficulty = 10;
  static const int _prefetchBatchSize = 5;

  // Track ongoing generation to avoid duplicates
  final _generationLocks = <String, Future<void>>{};

  QuestionService({
    required QuestionCacheService cacheService,
    required GeminiAIService aiService,
  })  : _cacheService = cacheService,
        _aiService = aiService;

  /// Initialize all sub-services.
  ///
  /// If [geminiApiKey] is empty, the service runs in "mock" mode:
  /// - Only cached / seeded questions are used
  /// - No calls are made to Gemini Developer API
  Future<void> init({required String geminiApiKey}) async {
    await _cacheService.init();
    if (geminiApiKey.isEmpty) {
      _mockMode = true;
      return;
    }
    _mockMode = false;
    await _aiService.init(apiKey: geminiApiKey);
  }

  /// Get a quiz card with 5 questions (one per category) at specified difficulties
  /// Prefers cached questions, generates on-demand if needed
  Future<QuizCard> getQuizCard(Map<Category, Difficulty> difficulties) async {
    final questions = <Question>[];
    final missingCategories = <Category>[];

    // Try to get questions from cache first
    for (final category in Category.values) {
      final difficulty = difficulties[category] ?? Difficulty.easy;
      Question? question = _cacheService.getQuestion(category, difficulty);

      // If cache miss, generate on-demand (unless in mock mode)
      if (question == null && !_mockMode) {
        try {
          question = await _generateQuestionOnDemand(category, difficulty);
        } catch (e) {
          // If generation fails, try any difficulty for this category
          for (final fallbackDifficulty in Difficulty.values) {
            if (fallbackDifficulty != difficulty) {
              question = _cacheService.getQuestion(category, fallbackDifficulty);
              if (question != null) break;
            }
          }
          
          // If still null, add to missing list
          if (question == null) {
            missingCategories.add(category);
            continue;
          }
        }
      }

      // In mock mode, if still null, try any difficulty
      if (question == null && _mockMode) {
        for (final fallbackDifficulty in Difficulty.values) {
          if (fallbackDifficulty != difficulty) {
            question = _cacheService.getQuestion(category, fallbackDifficulty);
            if (question != null) break;
          }
        }
        if (question == null) {
          missingCategories.add(category);
          continue;
        }
      }

      // Add question (should be non-null at this point)
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
        buffer.writeln('Cache is empty. Seed questions may not have loaded properly.');
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
      
      if (_mockMode) {
        buffer.writeln('Running in mock mode (no AI generation).');
      }
      
      throw Exception(buffer.toString());
    }

    // Create quiz card
    final quizCard = QuizCard.fromQuestions(
      id: const Uuid().v4(),
      questions: questions,
    );

    // Trigger background prefetch if cache is getting low
    _triggerPrefetchIfNeeded();

    return quizCard;
  }

  /// Generate a question on-demand when cache misses
  Future<Question> _generateQuestionOnDemand(
    Category category,
    Difficulty difficulty,
  ) async {
    final question = await _aiService.generateQuestion(category, difficulty);

    // Cache the generated question for future use
    await _cacheService.cacheQuestion(question);

    return question;
  }

  /// Prefetch questions to fill the cache in the background
  /// This runs asynchronously and doesn't block the UI
  Future<void> prefetchQuestions() async {
    final health = getCacheHealth();

    // Generate questions for categories/difficulties that are low
    final generationTasks = <Future<void>>[];

    for (final category in Category.values) {
      for (final difficulty in Difficulty.values) {
        final key = '${category.name}_${difficulty.name}';
        final count = health.getCount(category, difficulty);

        if (count < _minQuestionsPerCategoryDifficulty) {
          // Check if we're already generating for this combination
          if (_generationLocks.containsKey(key)) {
            continue;
          }

          // Start generation task
          final task = _generateBatch(category, difficulty, key);
          _generationLocks[key] = task;
          generationTasks.add(task);
        }
      }
    }

    // Wait for all generation tasks to complete
    await Future.wait(generationTasks);
  }

  /// Generate a batch of questions for a specific category/difficulty
  Future<void> _generateBatch(
    Category category,
    Difficulty difficulty,
    String lockKey,
  ) async {
    try {
      final questions = await _aiService.generateQuestions(
        category,
        difficulty,
        _prefetchBatchSize,
      );

      if (questions.isNotEmpty) {
        await _cacheService.cacheQuestions(questions);
      }
    } finally {
      // Always remove the lock when done
      _generationLocks.remove(lockKey);
    }
  }

  /// Trigger background prefetch if cache is below threshold
  void _triggerPrefetchIfNeeded() {
    final health = getCacheHealth();

    // Check if any category/difficulty is low
    bool needsPrefetch = false;
    for (final category in Category.values) {
      for (final difficulty in Difficulty.values) {
        if (health.getCount(category, difficulty) <
            _minQuestionsPerCategoryDifficulty) {
          needsPrefetch = true;
          break;
        }
      }
      if (needsPrefetch) break;
    }

    if (needsPrefetch) {
      // Run prefetch in background without awaiting
      unawaited(prefetchQuestions());
    }
  }

  /// Get cache health statistics
  CacheStats getCacheHealth() {
    return _cacheService.getCacheStats();
  }

  /// Warmup cache on app startup
  /// Generates initial questions for all category/difficulty combinations
  Future<void> warmupCache() async {
    final health = getCacheHealth();

    // Only warmup if cache is empty or very low
    if (health.totalQuestions < 20) {
      await prefetchQuestions();
    }
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
      isGenerating: _generationLocks.isNotEmpty,
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
