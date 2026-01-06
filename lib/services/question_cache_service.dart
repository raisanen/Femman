import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/question.dart';
import '../models/category.dart';
import '../models/difficulty.dart';
import '../data/seed_questions.dart';

/// Service for managing the local question cache using Hive.
/// Implements caching strategy with usage tracking and automatic rotation.
class QuestionCacheService {
  static const String _questionsBoxName = 'questions';
  static const String _usedQuestionsBoxName = 'used_questions';
  static const int _maxCacheSize = 1500;
  static const int _recentUsageWindow = 50; // Avoid repeating last 50 questions

  late Box<Question> _questionsBox;
  late Box<List<String>> _usedQuestionsBox;
  final _random = Random();

  /// Initialize Hive and open boxes
  Future<void> init() async {
    // Register Hive adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DifficultyAdapter());
    }

    // Open boxes with error handling for corrupted cache
    bool cacheWasCleared = false;
    try {
      _questionsBox = await Hive.openBox<Question>(_questionsBoxName);
      _usedQuestionsBox = await Hive.openBox<List<String>>(_usedQuestionsBoxName);
      
      // Try to read a question to verify the cache is readable
      // This will catch type errors early
      if (_questionsBox.isNotEmpty) {
        try {
          // Try to read all questions to check for type errors
          final testQuestions = <Question>[];
          for (final q in _questionsBox.values) {
            try {
              // Access properties to trigger deserialization
              final _ = q.id;
              final __ = q.category;
              testQuestions.add(q);
            } catch (e) {
              // Question is corrupted, skip it
            }
          }
          
          // If we couldn't read any questions, clear the cache
          if (testQuestions.isEmpty && _questionsBox.isNotEmpty) {
            await _questionsBox.clear();
            await _usedQuestionsBox.clear();
            cacheWasCleared = true;
          }
        } catch (e) {
          // Cache is corrupted, clear it
          await _questionsBox.clear();
          await _usedQuestionsBox.clear();
          cacheWasCleared = true;
        }
      }
    } catch (e) {
      // If there's a type error opening the box, clear and recreate
      // This can happen when the adapter format changes
      try {
        await Hive.deleteBoxFromDisk(_questionsBoxName);
        await Hive.deleteBoxFromDisk(_usedQuestionsBoxName);
      } catch (_) {
        // Ignore deletion errors
      }
      _questionsBox = await Hive.openBox<Question>(_questionsBoxName);
      _usedQuestionsBox = await Hive.openBox<List<String>>(_usedQuestionsBoxName);
      cacheWasCleared = true;
    }

    // Initialize used questions list if empty
    if (_usedQuestionsBox.isEmpty) {
      await _usedQuestionsBox.put('recent', <String>[]);
    }

    // Seed initial questions if cache is empty to enable offline play.
    // This includes cases where cache was cleared due to corruption
    if (_questionsBox.isEmpty || cacheWasCleared) {
      try {
        // ignore: avoid_print
        print('Caching ${seedQuestions.length} seed questions...');
        await cacheQuestions(seedQuestions);
        // Verify questions were cached
        final cachedCount = _questionsBox.length;
        if (cachedCount == 0) {
          throw Exception('Failed to cache seed questions: cache is still empty after caching');
        }
        // ignore: avoid_print
        print('Successfully cached $cachedCount seed questions');
      } catch (e, stackTrace) {
        // If caching fails, log and rethrow
        // ignore: avoid_print
        print('Error caching seed questions: $e');
        // ignore: avoid_print
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }
  }

  /// Cache a single question
  Future<void> cacheQuestion(Question question) async {
    await _questionsBox.put(question.id, question);
    await _enforceCacheLimit();
  }

  /// Cache multiple questions
  Future<void> cacheQuestions(List<Question> questions) async {
    final entries = {for (var q in questions) q.id: q};
    await _questionsBox.putAll(entries);
    await _enforceCacheLimit();
  }

  /// Get a random question for the specified category and difficulty
  /// Returns null if no suitable question is found
  /// Avoids recently used questions
  Question? getQuestion(Category category, Difficulty difficulty) {
    try {
      final recentlyUsed = _getRecentlyUsedIds();

      // Find all questions matching category and difficulty
      // Wrap in try-catch to handle type errors from corrupted cache
      final candidates = <Question>[];
      for (final q in _questionsBox.values) {
        try {
          if (q.category == category &&
              q.difficulty == difficulty &&
              !recentlyUsed.contains(q.id)) {
            candidates.add(q);
          }
        } catch (e) {
          // Skip corrupted questions
          continue;
        }
      }

      if (candidates.isEmpty) {
        // If no unused questions, try getting any question for this category/difficulty
        final allCandidates = <Question>[];
        for (final q in _questionsBox.values) {
          try {
            if (q.category == category && q.difficulty == difficulty) {
              allCandidates.add(q);
            }
          } catch (e) {
            // Skip corrupted questions
            continue;
          }
        }

        if (allCandidates.isEmpty) return null;

        // Return random from all candidates
        final question = allCandidates[_random.nextInt(allCandidates.length)];
        _markAsUsed(question.id);
        return question;
      }

      // Return random from unused candidates
      final question = candidates[_random.nextInt(candidates.length)];
      _markAsUsed(question.id);
      return question;
    } catch (e) {
      // If there's a type error, the cache might be corrupted
      // Return null and let the service handle it
      return null;
    }
  }


  /// Get cache statistics
  CacheStats getCacheStats() {
    final statsByCategory = <Category, Map<Difficulty, int>>{};

    // Initialize counts
    for (final category in Category.values) {
      statsByCategory[category] = {
        Difficulty.easy: 0,
        Difficulty.medium: 0,
        Difficulty.hard: 0,
      };
    }

    // Count questions
    for (final question in _questionsBox.values) {
      statsByCategory[question.category]![question.difficulty] =
          statsByCategory[question.category]![question.difficulty]! + 1;
    }

    return CacheStats(
      totalQuestions: _questionsBox.length,
      questionsByCategory: statsByCategory,
    );
  }

  /// Clear old questions to maintain cache limit
  Future<void> _enforceCacheLimit() async {
    if (_questionsBox.length <= _maxCacheSize) return;

    // Sort questions by generatedAt (oldest first)
    final sortedQuestions = _questionsBox.values.toList()
      ..sort((a, b) => a.generatedAt.compareTo(b.generatedAt));

    // Calculate how many to remove
    final toRemove = _questionsBox.length - _maxCacheSize;

    // Remove oldest questions
    for (var i = 0; i < toRemove; i++) {
      await _questionsBox.delete(sortedQuestions[i].id);
    }
  }

  /// Clear all old questions (manual cleanup)
  Future<void> clearOldQuestions() async {
    await _enforceCacheLimit();
  }

  /// Get list of recently used question IDs
  List<String> _getRecentlyUsedIds() {
    final recent = _usedQuestionsBox.get('recent');
    if (recent == null) return <String>[];
    // Handle web platform where Hive returns List<dynamic>
    if (recent is List<dynamic>) {
      return recent.map((e) => e.toString()).toList();
    }
    return recent as List<String>;
  }

  /// Get count of valid questions in cache by category and difficulty
  Map<Category, Map<Difficulty, int>> getQuestionCounts() {
    final counts = <Category, Map<Difficulty, int>>{};
    
    for (final category in Category.values) {
      counts[category] = <Difficulty, int>{};
      for (final difficulty in Difficulty.values) {
        counts[category]![difficulty] = 0;
      }
    }
    
    for (final q in _questionsBox.values) {
      try {
        final category = q.category;
        final difficulty = q.difficulty;
        counts[category]![difficulty] = (counts[category]![difficulty] ?? 0) + 1;
      } catch (e) {
        // Skip corrupted questions
        continue;
      }
    }
    
    return counts;
  }

  /// Get total count of valid questions in cache
  int getTotalQuestionCount() {
    int count = 0;
    for (final q in _questionsBox.values) {
      try {
        // Access properties to verify question is valid
        final _ = q.id;
        final __ = q.category;
        count++;
      } catch (e) {
        // Skip corrupted questions
        continue;
      }
    }
    return count;
  }

  /// Mark a question as used
  Future<void> _markAsUsed(String questionId) async {
    final recent = _getRecentlyUsedIds();

    // Add to beginning of list
    recent.insert(0, questionId);

    // Keep only last N questions
    if (recent.length > _recentUsageWindow) {
      recent.removeRange(_recentUsageWindow, recent.length);
    }

    await _usedQuestionsBox.put('recent', recent);
  }

  /// Clear usage history
  Future<void> clearUsageHistory() async {
    await _usedQuestionsBox.put('recent', <String>[]);
  }

  /// Get total number of cached questions
  int get totalCached => _questionsBox.length;

  /// Check if a question exists in cache
  bool hasQuestion(String questionId) {
    return _questionsBox.containsKey(questionId);
  }

  /// Get a specific question by ID
  Question? getQuestionById(String id) {
    return _questionsBox.get(id);
  }

  /// Delete a specific question
  Future<void> deleteQuestion(String id) async {
    await _questionsBox.delete(id);
  }

  /// Clear all cached questions
  Future<void> clearAll() async {
    await _questionsBox.clear();
    await _usedQuestionsBox.clear();
    await _usedQuestionsBox.put('recent', <String>[]);
  }

  /// Close Hive boxes
  Future<void> dispose() async {
    await _questionsBox.close();
    await _usedQuestionsBox.close();
  }
}

/// Cache statistics
class CacheStats {
  final int totalQuestions;
  final Map<Category, Map<Difficulty, int>> questionsByCategory;

  CacheStats({
    required this.totalQuestions,
    required this.questionsByCategory,
  });

  /// Get count for specific category and difficulty
  int getCount(Category category, Difficulty difficulty) {
    return questionsByCategory[category]?[difficulty] ?? 0;
  }

  /// Get total count for a category
  int getCategoryTotal(Category category) {
    final categoryMap = questionsByCategory[category];
    if (categoryMap == null) return 0;
    return categoryMap.values.fold(0, (sum, count) => sum + count);
  }

  /// Get total count for a difficulty
  int getDifficultyTotal(Difficulty difficulty) {
    int total = 0;
    for (final categoryMap in questionsByCategory.values) {
      total += categoryMap[difficulty] ?? 0;
    }
    return total;
  }
}
