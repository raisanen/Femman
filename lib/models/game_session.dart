import 'package:hive/hive.dart';
import 'card_result.dart';

part 'game_session.g.dart';

/// A game session tracking completed cards and streaks.
/// Streak = consecutive cards with perfect scores (5/5).
@HiveType(typeId: 6)
class GameSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<CardResult> completedCards;

  @HiveField(2)
  final int currentStreak;

  @HiveField(3)
  final DateTime startedAt;

  GameSession({
    required this.id,
    required this.completedCards,
    required this.currentStreak,
    required this.startedAt,
  });

  /// Create a new game session
  factory GameSession.create({required String id}) {
    return GameSession(
      id: id,
      completedCards: [],
      currentStreak: 0,
      startedAt: DateTime.now(),
    );
  }

  /// Add a card result and recalculate streak
  GameSession addResult(CardResult result) {
    final newCompletedCards = [...completedCards, result];
    final newStreak = _calculateStreak(newCompletedCards);

    return GameSession(
      id: id,
      completedCards: newCompletedCards,
      currentStreak: newStreak,
      startedAt: startedAt,
    );
  }

  /// Calculate current streak (consecutive perfect scores from the end)
  static int _calculateStreak(List<CardResult> cards) {
    if (cards.isEmpty) return 0;

    int streak = 0;
    for (int i = cards.length - 1; i >= 0; i--) {
      if (cards[i].isPerfect) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get the best streak in this session
  int get bestStreak {
    if (completedCards.isEmpty) return 0;

    int maxStreak = 0;
    int currentCount = 0;

    for (final card in completedCards) {
      if (card.isPerfect) {
        currentCount++;
        if (currentCount > maxStreak) {
          maxStreak = currentCount;
        }
      } else {
        currentCount = 0;
      }
    }

    return maxStreak;
  }

  /// Total number of cards played
  int get totalCards => completedCards.length;

  /// Total correct answers across all cards
  int get totalCorrect =>
      completedCards.fold(0, (sum, card) => sum + card.score);

  /// Total possible answers
  int get totalPossible => totalCards * 5;

  /// Overall accuracy
  double get accuracy =>
      totalPossible > 0 ? totalCorrect / totalPossible : 0.0;

  /// Session duration
  Duration get duration => DateTime.now().difference(startedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSession && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
