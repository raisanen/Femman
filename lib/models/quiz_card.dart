import 'package:hive/hive.dart';
import 'question.dart';
import 'category.dart';

part 'quiz_card.g.dart';

/// A quiz card containing exactly 5 questions, one from each category.
/// Matches the MIG card game format.
@HiveType(typeId: 3)
class QuizCard {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<Question> questions;

  @HiveField(2)
  final DateTime createdAt;

  QuizCard({
    required this.id,
    required this.questions,
    required this.createdAt,
  }) : assert(questions.length == 5, 'Must have exactly 5 questions') {
    // Validate that we have exactly one question per category
    final categories = questions.map((q) => q.category).toSet();
    assert(
      categories.length == 5,
      'Must have exactly one question from each category',
    );
    assert(
      categories.containsAll(Category.values),
      'Must include all 5 categories',
    );
  }

  /// Create a QuizCard from a list of 5 questions (one per category)
  factory QuizCard.fromQuestions({
    required String id,
    required List<Question> questions,
    DateTime? createdAt,
  }) {
    if (questions.length != 5) {
      throw ArgumentError('Must provide exactly 5 questions');
    }

    // Verify one question per category
    final categoryCounts = <Category, int>{};
    for (final question in questions) {
      categoryCounts[question.category] =
          (categoryCounts[question.category] ?? 0) + 1;
    }

    if (categoryCounts.length != 5) {
      throw ArgumentError('Must have questions from all 5 categories');
    }

    for (final count in categoryCounts.values) {
      if (count != 1) {
        throw ArgumentError(
          'Must have exactly one question per category, found $count',
        );
      }
    }

    return QuizCard(
      id: id,
      questions: questions,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Get question for a specific category
  Question getQuestionForCategory(Category category) {
    return questions.firstWhere((q) => q.category == category);
  }

  /// Get question at index (0-4)
  Question getQuestionAtIndex(int index) {
    assert(index >= 0 && index < 5, 'Index must be 0-4');
    return questions[index];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
