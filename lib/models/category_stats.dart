import 'package:hive/hive.dart';

part 'category_stats.g.dart';

/// Statistics for a specific category.
/// Tracks attempts, correct answers, and calculates accuracy.
@HiveType(typeId: 5)
class CategoryStats {
  @HiveField(0)
  final int attempted;

  @HiveField(1)
  final int correct;

  CategoryStats({
    required this.attempted,
    required this.correct,
  }) : assert(correct <= attempted, 'Correct cannot exceed attempted');

  /// Computed accuracy (0.0 to 1.0)
  double get accuracy => attempted > 0 ? correct / attempted : 0.0;

  /// Accuracy as percentage (0-100)
  double get accuracyPercentage => accuracy * 100;

  /// Number of incorrect answers
  int get incorrect => attempted - correct;

  /// Create initial stats (no attempts)
  factory CategoryStats.initial() {
    return CategoryStats(attempted: 0, correct: 0);
  }

  /// Create updated stats after answering a question
  CategoryStats withResult(bool isCorrect) {
    return CategoryStats(
      attempted: attempted + 1,
      correct: correct + (isCorrect ? 1 : 0),
    );
  }

  /// Copy with updated values
  CategoryStats copyWith({
    int? attempted,
    int? correct,
  }) {
    return CategoryStats(
      attempted: attempted ?? this.attempted,
      correct: correct ?? this.correct,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryStats &&
          runtimeType == other.runtimeType &&
          attempted == other.attempted &&
          correct == other.correct;

  @override
  int get hashCode => attempted.hashCode ^ correct.hashCode;
}
