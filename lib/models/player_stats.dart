import 'package:hive/hive.dart';
import 'category.dart';
import 'category_stats.dart';
import 'difficulty.dart';
import 'card_result.dart';

part 'player_stats.g.dart';

/// Overall player statistics across all game sessions.
/// Tracks performance per category and manages adaptive difficulty.
@HiveType(typeId: 7)
class PlayerStats {
  @HiveField(0)
  final int totalCardsPlayed;

  @HiveField(1)
  final int totalCorrect;

  @HiveField(2)
  final int bestStreak;

  @HiveField(3)
  final Map<Category, CategoryStats> categoryStats;

  @HiveField(4)
  final Map<Category, Difficulty> currentDifficulty;

  PlayerStats({
    required this.totalCardsPlayed,
    required this.totalCorrect,
    required this.bestStreak,
    required this.categoryStats,
    required this.currentDifficulty,
  });

  /// Create initial player stats (no games played)
  factory PlayerStats.initial() {
    return PlayerStats(
      totalCardsPlayed: 0,
      totalCorrect: 0,
      bestStreak: 0,
      categoryStats: {
        for (final category in Category.values)
          category: CategoryStats.initial(),
      },
      currentDifficulty: {
        for (final category in Category.values) category: Difficulty.easy,
      },
    );
  }

  /// Update stats with a new card result
  PlayerStats updateWithResult(CardResult result, int newStreak) {
    final newCategoryStats = Map<Category, CategoryStats>.from(categoryStats);
    final newDifficulty = Map<Category, Difficulty>.from(currentDifficulty);

    // Update stats for each category
    for (final category in Category.values) {
      final wasCorrect = result.isCorrect(category);
      final oldStats = categoryStats[category]!;
      newCategoryStats[category] = oldStats.withResult(wasCorrect);

      // Update difficulty based on performance (adaptive difficulty)
      newDifficulty[category] =
          _calculateNewDifficulty(category, newCategoryStats[category]!);
    }

    return PlayerStats(
      totalCardsPlayed: totalCardsPlayed + 1,
      totalCorrect: totalCorrect + result.score,
      bestStreak: newStreak > bestStreak ? newStreak : bestStreak,
      categoryStats: newCategoryStats,
      currentDifficulty: newDifficulty,
    );
  }

  /// Calculate new difficulty based on recent performance
  /// Rolling window of last 10 questions per category
  Difficulty _calculateNewDifficulty(
    Category category,
    CategoryStats stats,
  ) {
    final currentDiff = currentDifficulty[category]!;
    final attempts = stats.attempted;

    // Need at least 10 attempts to adjust difficulty
    if (attempts < 10) return currentDiff;

    final accuracy = stats.accuracy;

    // Increase difficulty if accuracy > 75%
    if (accuracy > 0.75) {
      if (currentDiff == Difficulty.easy) return Difficulty.medium;
      if (currentDiff == Difficulty.medium) return Difficulty.hard;
      return Difficulty.hard;
    }

    // Decrease difficulty if accuracy < 40%
    if (accuracy < 0.40) {
      if (currentDiff == Difficulty.hard) return Difficulty.medium;
      if (currentDiff == Difficulty.medium) return Difficulty.easy;
      return Difficulty.easy;
    }

    // Otherwise maintain current difficulty
    return currentDiff;
  }

  /// Get overall accuracy across all questions
  double get overallAccuracy {
    final totalAttempts = categoryStats.values.fold(
      0,
      (sum, stats) => sum + stats.attempted,
    );
    final totalCorrectAnswers = categoryStats.values.fold(
      0,
      (sum, stats) => sum + stats.correct,
    );

    return totalAttempts > 0 ? totalCorrectAnswers / totalAttempts : 0.0;
  }

  /// Get stats for a specific category
  CategoryStats getStatsForCategory(Category category) {
    return categoryStats[category] ?? CategoryStats.initial();
  }

  /// Get current difficulty for a specific category
  Difficulty getDifficultyForCategory(Category category) {
    return currentDifficulty[category] ?? Difficulty.easy;
  }

  /// Total questions attempted across all categories
  int get totalQuestionsAttempted =>
      categoryStats.values.fold(0, (sum, stats) => sum + stats.attempted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStats &&
          runtimeType == other.runtimeType &&
          totalCardsPlayed == other.totalCardsPlayed &&
          totalCorrect == other.totalCorrect &&
          bestStreak == other.bestStreak;

  @override
  int get hashCode =>
      totalCardsPlayed.hashCode ^ totalCorrect.hashCode ^ bestStreak.hashCode;
}
