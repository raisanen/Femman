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

  late Box<PlayerStats> _statsBox;
  late Box<GameSession> _sessionBox;

  PlayerStats? _currentStats;
  GameSession? _currentSession;

  /// Initialize Hive boxes and load current stats
  Future<void> init() async {
    // Register Hive adapters if not already registered
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(PlayerStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(GameSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CategoryStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CardResultAdapter());
    }

    // Open boxes
    _statsBox = await Hive.openBox<PlayerStats>(_statsBoxName);
    _sessionBox = await Hive.openBox<GameSession>(_sessionBoxName);

    // Load or create initial stats
    _currentStats = _statsBox.get(_statsKey);
    if (_currentStats == null) {
      _currentStats = PlayerStats.initial();
      await _saveStats();
    }
  }

  /// Get current player statistics
  PlayerStats getStats() {
    return _currentStats ?? PlayerStats.initial();
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
    // Update current session
    final session = getCurrentSession();
    _currentSession = session.addResult(result);

    // Save session to history
    await _sessionBox.put(_currentSession!.id, _currentSession!);

    // Update overall player stats
    final stats = getStats();
    _currentStats = stats.updateWithResult(result, _currentSession!.currentStreak);

    // Save updated stats
    await _saveStats();
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
    if (_currentSession != null) {
      await _sessionBox.put(_currentSession!.id, _currentSession!);
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
    final sessions = _sessionBox.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions.take(count).toList();
  }

  /// Reset all statistics (careful - this is permanent!)
  Future<void> resetStats() async {
    _currentStats = PlayerStats.initial();
    _currentSession = null;
    await _statsBox.clear();
    await _sessionBox.clear();
    await _saveStats();
  }

  /// Clear only session history, keep overall stats
  Future<void> clearSessionHistory() async {
    await _sessionBox.clear();
    _currentSession = null;
  }

  /// Save current stats to Hive
  Future<void> _saveStats() async {
    if (_currentStats != null) {
      await _statsBox.put(_statsKey, _currentStats!);
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
    await _statsBox.close();
    await _sessionBox.close();
  }
}
