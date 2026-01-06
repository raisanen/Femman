import 'package:hive/hive.dart';
import 'category.dart';

part 'card_result.g.dart';

/// Result of completing a quiz card.
/// Tracks which categories were answered correctly and the total score.
@HiveType(typeId: 4)
class CardResult {
  @HiveField(0)
  final String cardId;

  @HiveField(1)
  final Map<Category, bool> results;

  @HiveField(2)
  final Duration timeTaken;

  CardResult({
    required this.cardId,
    required this.results,
    required this.timeTaken,
  }) : assert(
          results.length == 5,
          'Must have results for all 5 categories',
        ) {
    // Validate that all categories are present
    assert(
      results.keys.toSet().containsAll(Category.values),
      'Results must include all 5 categories',
    );
  }

  /// Computed score (0-5) based on correct answers
  int get score => results.values.where((correct) => correct).length;

  /// Check if a specific category was answered correctly
  bool isCorrect(Category category) => results[category] ?? false;

  /// Check if this was a perfect score (5/5)
  bool get isPerfect => score == 5;

  /// Get list of categories answered correctly
  List<Category> get correctCategories =>
      results.entries.where((e) => e.value).map((e) => e.key).toList();

  /// Get list of categories answered incorrectly
  List<Category> get incorrectCategories =>
      results.entries.where((e) => !e.value).map((e) => e.key).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardResult &&
          runtimeType == other.runtimeType &&
          cardId == other.cardId;

  @override
  int get hashCode => cardId.hashCode;
}
