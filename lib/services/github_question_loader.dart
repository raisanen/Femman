import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/category.dart';
import '../models/difficulty.dart';

/// Service for loading questions from GitHub repository.
/// Falls back to asset loading if GitHub fetch fails.
class GitHubQuestionLoader {
  static const String _baseUrl = 'https://raw.githubusercontent.com/raisanen/femman_questions/main';
  static const String _manifestPath = '/manifest.json';
  
  final http.Client _client;
  
  GitHubQuestionLoader({http.Client? client}) : _client = client ?? http.Client();

  /// Load manifest.json from GitHub
  /// Returns dynamic to handle both Map and List formats
  Future<dynamic> _loadManifest() async {
    final uri = Uri.parse('$_baseUrl$_manifestPath');
    final response = await _client.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Timeout loading manifest from GitHub');
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load manifest: HTTP ${response.statusCode}');
    }

    return json.decode(response.body);
  }

  /// Load a question JSON file from GitHub
  Future<List<dynamic>> _loadQuestionFile(String filename) async {
    final uri = Uri.parse('$_baseUrl/$filename');
    final response = await _client.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Timeout loading $filename from GitHub');
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load $filename: HTTP ${response.statusCode}');
    }

    return json.decode(response.body) as List<dynamic>;
  }

  /// Load all questions from GitHub repository
  /// Returns empty list if loading fails (caller should fall back to assets)
  Future<List<Question>> loadQuestions() async {
    try {
      // Load manifest to get list of question files
      final manifest = await _loadManifest();
      
      // Parse manifest - expect a list of filenames or a structure with files
      // Support multiple manifest formats:
      // 1. { "files": ["file1.json", "file2.json"] }
      // 2. { "questions": ["file1.json", "file2.json"] }
      // 3. ["file1.json", "file2.json"] (direct array)
      List<String> questionFiles;
      if (manifest is Map) {
        final manifestMap = manifest as Map<String, dynamic>;
        if (manifestMap.containsKey('files') && manifestMap['files'] is List) {
          questionFiles = (manifestMap['files'] as List<dynamic>)
              .map((e) => e.toString())
              .where((f) => f.endsWith('.json') && f != 'manifest.json')
              .toList();
        } else if (manifestMap.containsKey('questions') && manifestMap['questions'] is List) {
          questionFiles = (manifestMap['questions'] as List<dynamic>)
              .map((e) => e.toString())
              .where((f) => f.endsWith('.json') && f != 'manifest.json')
              .toList();
        } else {
          // If manifest structure is unexpected, try loading questions.json directly
          questionFiles = ['questions.json'];
        }
      } else if (manifest is List) {
        // Manifest is a direct array
        questionFiles = (manifest as List<dynamic>)
            .map((e) => e.toString())
            .where((f) => f.endsWith('.json') && f != 'manifest.json')
            .toList();
      } else {
        // If manifest structure is unexpected, try loading questions.json directly
        questionFiles = ['questions.json'];
      }

      if (questionFiles.isEmpty) {
        throw Exception('No question files found in manifest');
      }

      // Load all question files and merge them
      final allQuestions = <Question>[];
      for (final filename in questionFiles) {
        try {
          final questionsJson = await _loadQuestionFile(filename);
          final questions = questionsJson
              .map((json) => _parseQuestion(json as Map<String, dynamic>))
              .toList();
          allQuestions.addAll(questions);
        } catch (e) {
          // Log error but continue loading other files
          // ignore: avoid_print
          print('Warning: Failed to load $filename: $e');
        }
      }

      if (allQuestions.isEmpty) {
        throw Exception('No questions loaded from GitHub files');
      }

      // ignore: avoid_print
      print('Loaded ${allQuestions.length} questions from GitHub');
      return allQuestions;
    } catch (e) {
      // Return empty list to signal failure - caller should fall back
      // ignore: avoid_print
      print('Failed to load questions from GitHub: $e');
      rethrow;
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

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

