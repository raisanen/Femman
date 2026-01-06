import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/category.dart';
import '../models/difficulty.dart';
import '../core/constants/app_strings.dart';

/// Service for generating quiz questions using Gemini Developer API.
/// Handles bilingual question generation with proper error handling and retries.
class GeminiAIService {
  late final GenerativeModel _model;
  static const int _maxRetries = 3;
  static const Duration _initialBackoff = Duration(seconds: 1);

  /// Initialize Gemini Developer API with API key
  /// API key should be provided via environment variable or secure storage
  Future<void> init({required String apiKey}) async {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1.0,
        topP: 0.95,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Generate a single question for the specified category and difficulty
  Future<Question> generateQuestion(
    Category category,
    Difficulty difficulty,
  ) async {
    final prompt = _buildPrompt(category, difficulty);

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        final text = response.text;

        if (text == null || text.isEmpty) {
          throw Exception('Empty response from AI');
        }

        final question = _parseResponse(text, category, difficulty);
        return question;
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          rethrow;
        }

        // Exponential backoff
        final backoffDuration = _initialBackoff * (1 << attempt);
        await Future.delayed(backoffDuration);
      }
    }

    throw Exception('Failed to generate question after $_maxRetries attempts');
  }

  /// Generate multiple questions in batch for the specified category and difficulty
  Future<List<Question>> generateQuestions(
    Category category,
    Difficulty difficulty,
    int count,
  ) async {
    final questions = <Question>[];

    // Generate questions sequentially to avoid rate limits
    for (int i = 0; i < count; i++) {
      try {
        final question = await generateQuestion(category, difficulty);
        questions.add(question);

        // Small delay between requests to be respectful of rate limits
        if (i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        // Log error but continue with other questions
        // In production, this should use a proper logging framework
        // ignore: avoid_print
        print('Failed to generate question ${i + 1}/$count: $e');
      }
    }

    return questions;
  }

  /// Build the prompt for question generation
  String _buildPrompt(Category category, Difficulty difficulty) {
    final categoryNameSv = category.localizedName(AppLanguage.sv);
    final categoryNameEn = category.localizedName(AppLanguage.en);
    final difficultyNameSv = difficulty.displayName(AppLanguage.sv);
    final difficultyNameEn = difficulty.displayName(AppLanguage.en);

    final difficultyGuideline = switch (difficulty) {
      Difficulty.easy =>
        'Common knowledge that most people would know. Straightforward facts.',
      Difficulty.medium =>
        'Specific knowledge requiring some expertise. Less commonly known facts.',
      Difficulty.hard =>
        'Niche facts that only enthusiasts or experts would know. Challenging trivia.',
    };

    return '''
Generate a trivia question for a quiz game.

Category: $categoryNameEn (Swedish: $categoryNameSv)
Difficulty: $difficultyNameEn (Swedish: $difficultyNameSv)

Difficulty Guidelines:
$difficultyGuideline

Requirements:
- Create a question in BOTH Swedish and English
- Provide exactly 4 answer options in BOTH languages
- One option must be correct, the other three must be plausible but wrong
- Include a fun fact that explains the answer in BOTH languages
- The fun fact should be educational and interesting
- Keep questions concise and clear
- Ensure translations are accurate and natural

Response Format (JSON):
{
  "textSv": "Question text in Swedish",
  "textEn": "Question text in English",
  "optionsSv": ["Option 1 in Swedish", "Option 2 in Swedish", "Option 3 in Swedish", "Option 4 in Swedish"],
  "optionsEn": ["Option 1 in English", "Option 2 in English", "Option 3 in English", "Option 4 in English"],
  "correctIndex": 0,
  "funFactSv": "Fun fact in Swedish explaining why this is the correct answer",
  "funFactEn": "Fun fact in English explaining why this is the correct answer"
}

The correctIndex should be the index (0-3) of the correct answer in the options arrays.
Both language versions must have the correct answer at the same index.

Generate the question now:''';
  }

  /// Parse the AI response and create a Question object
  Question _parseResponse(
    String responseText,
    Category category,
    Difficulty difficulty,
  ) {
    try {
      // Remove markdown code blocks if present
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON string to Map
      final jsonMap = json.decode(jsonText) as Map<String, dynamic>;

      // Add required fields that aren't in the AI response
      jsonMap['id'] = const Uuid().v4();
      jsonMap['category'] = category.toString().split('.').last;
      jsonMap['difficulty'] = difficulty.toString().split('.').last;
      jsonMap['generatedAt'] = DateTime.now().toIso8601String();

      // Create Question from the complete JSON map
      final question = Question.fromJson(jsonMap);

      // Validate question
      if (question.optionsSv.length != 4 || question.optionsEn.length != 4) {
        throw Exception('Question must have exactly 4 options');
      }

      if (question.correctIndex < 0 || question.correctIndex > 3) {
        throw Exception('correctIndex must be between 0 and 3');
      }

      if (question.textSv.isEmpty || question.textEn.isEmpty) {
        throw Exception('Question text cannot be empty');
      }

      final funFactSv = question.funFactSv;
      final funFactEn = question.funFactEn;
      if (funFactSv == null || funFactSv.isEmpty ||
          funFactEn == null || funFactEn.isEmpty) {
        throw Exception('Fun facts cannot be empty');
      }

      return question;
    } catch (e) {
      throw Exception('Failed to parse AI response: $e\nResponse: $responseText');
    }
  }
}
