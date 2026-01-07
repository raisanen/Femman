# Femman

A minimalist infinite quiz game inspired by the Swedish card game MIG. Players receive "cards" of 5 questions (one per category), answer them, then draw a new card. Questions are loaded from a GitHub repository at startup, with fallback to local JSON assets for offline play.

## Features

- **5 Questions Per Card**: One question from each category (Now & Then, Entertainment & Culture, Near & Far, Sport & Misc, Science & Tech)
- **Bilingual Support**: Swedish and English language support
- **Adaptive Difficulty**: Difficulty adjusts based on player performance
- **GitHub Question Loading**: Questions loaded from [femman_questions](https://github.com/raisanen/femman_questions) repository with automatic fallback to local assets
- **Dark & Light Themes**: Toggle between themes in settings
- **Statistics Tracking**: Track your progress, streaks, and accuracy per category
- **Offline Play**: Works fully offline using local question assets

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd femman
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Question Loading

Questions are loaded from the GitHub repository `https://github.com/raisanen/femman_questions` at app startup. The repository should contain:

- `manifest.json`: Lists all available question JSON files
- Question JSON files: Array of question objects

If GitHub loading fails (offline, network issues), the app automatically falls back to `assets/questions.json`.

You can manually reload questions from GitHub via the Settings screen.

## Project Structure

```
lib/
├── core/           # Theme, constants, utilities
├── features/       # Screen implementations
├── models/         # Data models
├── services/       # Business logic (question loading, stats, settings)
└── providers/      # Riverpod state management
```

## Dependencies

- **flutter_riverpod**: State management
- **hive**: Local storage for statistics
- **shared_preferences**: App preferences
- **http**: GitHub question loading
- **google_fonts**: Typography
- **uuid**: Unique ID generation

## Platform Support

- **Web**: Full support
- **Android**: Full support (minSdkVersion 21)

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).

See the [LICENSE](LICENSE) file for details.
