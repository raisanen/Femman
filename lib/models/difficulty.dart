import 'package:hive/hive.dart';
import '../core/constants/app_strings.dart';

part 'difficulty.g.dart';

/// Question difficulty levels for adaptive difficulty system.
/// Each category tracks difficulty independently based on player performance.
@HiveType(typeId: 2)
enum Difficulty {
  @HiveField(0)
  easy,

  @HiveField(1)
  medium,

  @HiveField(2)
  hard,
}

/// Extension methods for Difficulty enum
extension DifficultyExtension on Difficulty {
  /// Get the localized display name for this difficulty level
  String displayName(AppLanguage lang) {
    switch (this) {
      case Difficulty.easy:
        return AppStrings.difficultyEasy(lang);
      case Difficulty.medium:
        return AppStrings.difficultyMedium(lang);
      case Difficulty.hard:
        return AppStrings.difficultyHard(lang);
    }
  }

  /// Get a numeric value for this difficulty (useful for calculations)
  int get value {
    switch (this) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 2;
      case Difficulty.hard:
        return 3;
    }
  }
}
