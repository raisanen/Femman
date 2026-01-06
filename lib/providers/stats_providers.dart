import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stats_service.dart';
import '../models/player_stats.dart';
import '../models/category.dart';
import '../models/category_stats.dart';
import '../models/difficulty.dart';
import '../models/card_result.dart';

/// Provider for the StatsService singleton instance
final statsServiceProvider = Provider<StatsService>((ref) {
  final service = StatsService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for current player statistics (refreshable)
final playerStatsProvider = StateProvider<PlayerStats>((ref) {
  final service = ref.watch(statsServiceProvider);
  return service.getStats();
});

/// Provider for the current difficulty of a specific category
/// Uses adaptive difficulty based on player performance
final categoryDifficultyProvider =
    Provider.family<Difficulty, Category>((ref, category) {
  final stats = ref.watch(playerStatsProvider);
  return stats.getDifficultyForCategory(category);
});

/// Provider for all category difficulties (map of Category -> Difficulty)
final allDifficultiesProvider = Provider<Map<Category, Difficulty>>((ref) {
  final service = ref.watch(statsServiceProvider);
  return service.getAllDifficulties();
});

/// Provider for category-specific stats
final categoryStatsProvider =
    Provider.family<CategoryStats, Category>((ref, category) {
  final stats = ref.watch(playerStatsProvider);
  return stats.getStatsForCategory(category);
});

/// Provider for current streak
final currentStreakProvider = Provider<int>((ref) {
  final service = ref.watch(statsServiceProvider);
  return service.getCurrentStreak();
});

/// Provider for all-time best streak
final allTimeBestStreakProvider = Provider<int>((ref) {
  final stats = ref.watch(playerStatsProvider);
  return stats.bestStreak;
});

/// Provider for overall accuracy percentage (0-100)
final overallAccuracyProvider = Provider<double>((ref) {
  final service = ref.watch(statsServiceProvider);
  return service.getOverallAccuracyPercentage();
});

/// Provider for category accuracy percentage (0-100)
final categoryAccuracyProvider =
    Provider.family<double, Category>((ref, category) {
  final service = ref.watch(statsServiceProvider);
  return service.getCategoryAccuracyPercentage(category);
});

/// Provider for total cards played
final totalCardsPlayedProvider = Provider<int>((ref) {
  final stats = ref.watch(playerStatsProvider);
  return stats.totalCardsPlayed;
});

/// Provider for total correct answers
final totalCorrectAnswersProvider = Provider<int>((ref) {
  final stats = ref.watch(playerStatsProvider);
  return stats.totalCorrect;
});

/// Provider to check if player has played any cards
final hasPlayedCardsProvider = Provider<bool>((ref) {
  final service = ref.watch(statsServiceProvider);
  return service.hasPlayedCards();
});

/// Notifier for recording card results and updating stats
final statsNotifierProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<void>>((ref) {
  return StatsNotifier(ref.watch(statsServiceProvider), ref);
});

/// Notifier for managing stats operations
class StatsNotifier extends StateNotifier<AsyncValue<void>> {
  final StatsService _statsService;
  final Ref _ref;

  StatsNotifier(this._statsService, this._ref) : super(const AsyncValue.data(null));

  /// Record a card result and update all statistics
  Future<void> recordCardResult(CardResult result) async {
    state = const AsyncValue.loading();
    try {
      await _statsService.recordCardResult(result);
      // Refresh the player stats provider
      _ref.invalidate(playerStatsProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reset all statistics
  Future<void> resetStats() async {
    state = const AsyncValue.loading();
    try {
      await _statsService.resetStats();
      // Refresh the player stats provider
      _ref.invalidate(playerStatsProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// End the current session
  Future<void> endSession() async {
    try {
      await _statsService.endSession();
      // Refresh relevant providers
      _ref.invalidate(currentStreakProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
