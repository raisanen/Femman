import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/category.dart';
import '../models/difficulty.dart';

/// Service for loading questions from JSON assets
class JsonQuestionLoader {
  static const String _questionsAssetPath = 'assets/questions.json';
  
  List<Question>? _cachedQuestions;

  /// Load all questions from JSON asset
  Future<List<Question>> loadQuestions() async {
    if (_cachedQuestions != null) {
      return _cachedQuestions!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_questionsAssetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      
      _cachedQuestions = jsonList.map((json) => _parseQuestion(json)).toList();
      return _cachedQuestions!;
    } catch (e) {
      throw Exception('Failed to load questions from JSON: $e');
    }
  }

  /// Parse a single question from JSON
  Question _parseQuestion(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      category: _parseCategory(json['category'] as String),
      difficulty: _parseDifficulty(json['difficulty'] as String),
      textSv: json['textSv'] as String,
      textEn: json['textEn'] as String,
      optionsSv: (json['optionsSv'] as List<dynamic>).map((e) => e.toString()).toList(),
      optionsEn: (json['optionsEn'] as List<dynamic>).map((e) => e.toString()).toList(),
      correctIndex: json['correctIndex'] as int,
      funFactSv: json['funFactSv'] as String?,
      funFactEn: json['funFactEn'] as String?,
      generatedAt: DateTime.now(), // Use current time for loaded questions
    );
  }

  /// Parse category string to Category enum
  Category _parseCategory(String categoryStr) {
    switch (categoryStr) {
      case 'nowThen':
        return Category.nowThen;
      case 'entertainment':
        return Category.entertainment;
      case 'nearFar':
        return Category.nearFar;
      case 'sportMisc':
        return Category.sportMisc;
      case 'scienceTech':
        return Category.scienceTech;
      default:
        throw ArgumentError('Unknown category: $categoryStr');
    }
  }

  /// Parse difficulty string to Difficulty enum
  Difficulty _parseDifficulty(String difficultyStr) {
    switch (difficultyStr) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        throw ArgumentError('Unknown difficulty: $difficultyStr');
    }
  }

  /// Clear cached questions (useful for testing or reloading)
  void clearCache() {
    _cachedQuestions = null;
  }
}

