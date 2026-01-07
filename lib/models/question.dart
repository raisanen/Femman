import 'dart:math';
import 'package:hive/hive.dart';
import '../core/constants/app_strings.dart';
import 'category.dart';
import 'difficulty.dart';

part 'question.g.dart';

/// A trivia question with bilingual support.
/// Contains question text, answer options, and optional fun facts in both Swedish and English.
@HiveType(typeId: 0)
class Question {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Category category;

  @HiveField(2)
  final String textSv;

  @HiveField(3)
  final String textEn;

  @HiveField(4)
  final List<String> optionsSv;

  @HiveField(5)
  final List<String> optionsEn;

  @HiveField(6)
  final int correctIndex;

  @HiveField(7)
  final Difficulty difficulty;

  @HiveField(8)
  final String? funFactSv;

  @HiveField(9)
  final String? funFactEn;

  @HiveField(10)
  final DateTime generatedAt;

  Question({
    required this.id,
    required this.category,
    required this.textSv,
    required this.textEn,
    required this.optionsSv,
    required this.optionsEn,
    required this.correctIndex,
    required this.difficulty,
    this.funFactSv,
    this.funFactEn,
    required this.generatedAt,
  }) : assert(optionsSv.length == 4, 'Must have exactly 4 Swedish options'),
       assert(optionsEn.length == 4, 'Must have exactly 4 English options'),
       assert(correctIndex >= 0 && correctIndex <= 3, 'correctIndex must be 0-3');

  /// Get the question text in the specified language
  String getText(AppLanguage lang) {
    return lang == AppLanguage.sv ? textSv : textEn;
  }

  /// Get the answer options in the specified language
  List<String> getOptions(AppLanguage lang) {
    return lang == AppLanguage.sv ? optionsSv : optionsEn;
  }
  
  /// Get shuffled options with the correct index adjusted
  /// Returns a tuple of (shuffled options, new correct index)
  /// Uses a deterministic shuffle based on question ID for consistency
  (List<String>, int) getShuffledOptions(AppLanguage lang, {int? seed}) {
    final options = List<String>.from(getOptions(lang));
    final random = Random(seed ?? id.hashCode);
    final shuffled = <String>[];
    final originalIndices = <int>[0, 1, 2, 3];
    
    // Fisher-Yates shuffle
    while (originalIndices.isNotEmpty) {
      final index = random.nextInt(originalIndices.length);
      final originalIndex = originalIndices.removeAt(index);
      shuffled.add(options[originalIndex]);
    }
    
    // Find the new index of the correct answer
    final correctAnswer = options[correctIndex];
    final newCorrectIndex = shuffled.indexOf(correctAnswer);
    
    return (shuffled, newCorrectIndex);
  }

  /// Get the fun fact in the specified language (if available)
  String? getFunFact(AppLanguage lang) {
    return lang == AppLanguage.sv ? funFactSv : funFactEn;
  }

  /// Get the correct answer text in the specified language
  String getCorrectAnswer(AppLanguage lang) {
    final options = getOptions(lang);
    return options[correctIndex];
  }

  /// Create a Question from JSON (for parsing AI responses and cache)
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      category: Category.values.firstWhere(
        (c) => c.toString() == 'Category.${json['category']}',
      ),
      textSv: json['textSv'] as String,
      textEn: json['textEn'] as String,
      optionsSv: (json['optionsSv'] as List<dynamic>).map((e) => e.toString()).toList(),
      optionsEn: (json['optionsEn'] as List<dynamic>).map((e) => e.toString()).toList(),
      correctIndex: json['correctIndex'] as int,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.toString() == 'Difficulty.${json['difficulty']}',
      ),
      funFactSv: json['funFactSv'] as String?,
      funFactEn: json['funFactEn'] as String?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  /// Convert Question to JSON (for caching and API responses)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.toString().split('.').last,
      'textSv': textSv,
      'textEn': textEn,
      'optionsSv': optionsSv,
      'optionsEn': optionsEn,
      'correctIndex': correctIndex,
      'difficulty': difficulty.toString().split('.').last,
      'funFactSv': funFactSv,
      'funFactEn': funFactEn,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this question with optional field changes
  Question copyWith({
    String? id,
    Category? category,
    String? textSv,
    String? textEn,
    List<String>? optionsSv,
    List<String>? optionsEn,
    int? correctIndex,
    Difficulty? difficulty,
    String? funFactSv,
    String? funFactEn,
    DateTime? generatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      category: category ?? this.category,
      textSv: textSv ?? this.textSv,
      textEn: textEn ?? this.textEn,
      optionsSv: optionsSv ?? this.optionsSv,
      optionsEn: optionsEn ?? this.optionsEn,
      correctIndex: correctIndex ?? this.correctIndex,
      difficulty: difficulty ?? this.difficulty,
      funFactSv: funFactSv ?? this.funFactSv,
      funFactEn: funFactEn ?? this.funFactEn,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
