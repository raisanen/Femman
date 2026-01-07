import 'package:hive_flutter/hive_flutter.dart';
import '../models/player_stats.dart';
import '../models/game_session.dart';
import '../models/card_result.dart';
import '../models/category.dart';
import '../models/category_stats.dart';
import '../models/difficulty.dart';

/// Service for managing player statistics with Hive persistence.
/// Tracks performance, streaks, and adaptive difficulty per category.
class StatsService {
  static const String _statsBoxName = 'player_stats';
  static const String _statsKey = 'current_stats';
  static const String _sessionBoxName = 'game_sessions';

  Box<PlayerStats>? _statsBox;
  Box<GameSession>? _sessionBox;

  PlayerStats? _currentStats;
  GameSession? _currentSession;
  
  bool get _isInitialized => _statsBox != null && _sessionBox != null;

  /// Initialize Hive boxes and load current stats
  Future<void> init() async {
    // Register Hive adapters if not already registered
    // Register Category and Difficulty adapters for stats storage
    // but we register them here too to be safe
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DifficultyAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CardResultAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CategoryStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(GameSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(PlayerStatsAdapter());
    }

    // Open boxes
    _statsBox = await Hive.openBox<PlayerStats>(_statsBoxName);
    _sessionBox = await Hive.openBox<GameSession>(_sessionBoxName);

    // Load or create initial stats
    _currentStats = _statsBox!.get(_statsKey);
    if (_currentStats == null) {
      _currentStats = PlayerStats.initial();
      await _saveStats();
    }
    
    // ignore: avoid_print
    print('StatsService initialized: totalCards=${_currentStats!.totalCardsPlayed}, totalCorrect=${_currentStats!.totalCorrect}');
  }

  /// Get current player statistics
  /// Always returns the latest in-memory stats
  /// If stats box is open, also tries to reload from Hive to ensure consistency
  PlayerStats getStats() {
    // If _currentStats is null, try loading from Hive
    if (_currentStats == null) {
      if (_isInitialized && _statsBox!.isOpen) {
        _currentStats = _statsBox!.get(_statsKey) ?? PlayerStats.initial();
      } else {
        _currentStats = PlayerStats.initial();
      }
    }
    // Always return a fresh copy to ensure Riverpod detects changes
    // This is important because Riverpod uses object identity for caching
    return _currentStats!;
  }

  /// Get current game session (or create new one)
  GameSession getCurrentSession() {
    _currentSession ??= GameSession.create(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return _currentSession!;
  }

  /// Record a card result and update all statistics
  /// This updates both session and overall player stats
  Future<void> recordCardResult(CardResult result) async {
    try {
      // Ensure boxes are initialized
      if (!_isInitialized) {
        throw StateError('StatsService is not initialized. Call init() first.');
      }
      if (!_statsBox!.isOpen) {
        throw StateError('Stats box is not open. Call init() first.');
      }
      if (!_sessionBox!.isOpen) {
        throw StateError('Session box is not open. Call init() first.');
      }

      // Update current session
      final session = getCurrentSession();
      _currentSession = session.addResult(result);

      // Save session to history
      await _sessionBox!.put(_currentSession!.id, _currentSession!);

      // Update overall player stats
      final stats = getStats();
      _currentStats = stats.updateWithResult(result, _currentSession!.currentStreak);

      // Save updated stats to Hive
      await _saveStats();
      
      // Verify the save worked
      final savedStats = _statsBox!.get(_statsKey);
      if (savedStats != null) {
        _currentStats = savedStats;
      } else {
        // If save didn't work, log and try again
        // ignore: avoid_print
        print('Warning: Stats were not saved to Hive. Retrying...');
        await _saveStats();
        final retryStats = _statsBox!.get(_statsKey);
        if (retryStats != null) {
          _currentStats = retryStats;
        }
      }
      
      // Reload session from Hive to ensure consistency
      final savedSession = _sessionBox!.get(_currentSession!.id);
      if (savedSession != null) {
        _currentSession = savedSession;
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      // ignore: avoid_print
      print('Error recording card result: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get the current adaptive difficulty for a specific category
  /// Based on player's performance history
  Difficulty getDifficultyForCategory(Category category) {
    final stats = getStats();
    return stats.getDifficultyForCategory(category);
  }

  /// Get difficulties for all categories
  Map<Category, Difficulty> getAllDifficulties() {
    final stats = getStats();
    return {
      for (final category in Category.values)
        category: stats.getDifficultyForCategory(category),
    };
  }

  /// Get stats for a specific category
  CategoryStats getStatsForCategory(Category category) {
    final stats = getStats();
    return stats.getStatsForCategory(category);
  }

  /// End the current session and start a new one
  Future<void> endSession() async {
    if (_currentSession != null && _isInitialized) {
      await _sessionBox!.put(_currentSession!.id, _currentSession!);
      _currentSession = null;
    }
  }

  /// Get the current session's best streak
  int getCurrentSessionBestStreak() {
    return _currentSession?.bestStreak ?? 0;
  }

  /// Get the current active streak
  int getCurrentStreak() {
    return _currentSession?.currentStreak ?? 0;
  }

  /// Get all-time best streak
  int getAllTimeBestStreak() {
    return getStats().bestStreak;
  }

  /// Get recent game sessions (up to count)
  List<GameSession> getRecentSessions({int count = 10}) {
    if (!_isInitialized) return [];
    final sessions = _sessionBox!.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions.take(count).toList();
  }

  /// Reset all statistics (careful - this is permanent!)
  Future<void> resetStats() async {
    _currentStats = PlayerStats.initial();
    _currentSession = null;
    if (_isInitialized) {
      await _statsBox!.clear();
      await _sessionBox!.clear();
      await _saveStats();
    }
  }

  /// Clear only session history, keep overall stats
  Future<void> clearSessionHistory() async {
    if (_isInitialized) {
      await _sessionBox!.clear();
    }
    _currentSession = null;
  }

  /// Save current stats to Hive
  Future<void> _saveStats() async {
    if (_currentStats != null && _isInitialized) {
      await _statsBox!.put(_statsKey, _currentStats!);
      // Verify the save
      final saved = _statsBox!.get(_statsKey);
      if (saved == null) {
        // ignore: avoid_print
        print('ERROR: Failed to save stats to Hive!');
      } else if (saved.totalCardsPlayed != _currentStats!.totalCardsPlayed) {
        // ignore: avoid_print
        print('WARNING: Saved stats do not match current stats!');
      } else {
        // ignore: avoid_print
        print('Stats saved successfully: totalCards=${saved.totalCardsPlayed}, totalCorrect=${saved.totalCorrect}');
      }
    }
  }

  /// Get overall accuracy percentage (0-100)
  double getOverallAccuracyPercentage() {
    return getStats().overallAccuracy * 100;
  }

  /// Get accuracy for a specific category as percentage (0-100)
  double getCategoryAccuracyPercentage(Category category) {
    return getStatsForCategory(category).accuracyPercentage;
  }

  /// Check if player has played any cards
  bool hasPlayedCards() {
    return getStats().totalCardsPlayed > 0;
  }

  /// Get total number of cards played
  int getTotalCardsPlayed() {
    return getStats().totalCardsPlayed;
  }

  /// Get total correct answers across all categories
  int getTotalCorrectAnswers() {
    return getStats().totalCorrect;
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_statsBox != null && _statsBox!.isOpen) {
      await _statsBox!.close();
    }
    if (_sessionBox != null && _sessionBox!.isOpen) {
      await _sessionBox!.close();
    }
  }
}
