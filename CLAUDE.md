# Femman

A minimalist infinite quiz game inspired by the Swedish card game MIG. Players receive "cards" of 5 questions (one per category), answer them, then draw a new card. Questions are loaded from a GitHub repository at startup, with fallback to local JSON assets for offline play.

## Core Concept

- **Format**: 5 questions per card, one from each category
- **Categories**: Now & Then, Entertainment & Culture, Near & Far, Sport & Misc, Science & Tech
- **Question Loading**: Questions loaded from GitHub repository at startup, with fallback to local JSON assets for offline play
- **Bilingual**: Swedish and English support
- **Adaptive**: Difficulty adjusts based on player performance

## Tech Stack

- **Framework**: Flutter (targeting Web & Android)
- **Questions**: Loaded from GitHub repository (https://github.com/raisanen/femman_questions) with fallback to JSON assets
- **Storage**: Local storage (SharedPreferences + Hive for stats)
- **State Management**: Riverpod
- **Fonts**: Google Fonts (Inter)

## Design System

### Swiss Typography Style

The visual design follows International Typographic Style principles:

- Grid-based layouts with mathematical proportions
- Generous whitespace
- Sans-serif typography (Inter family)
- Limited colour palette
- Typography as the primary design element
- No decorative elements — every element serves a function

### Colour Palette

```dart
// Core palette
static const background = Color(0xFFFAFAFA);     // Off-white
static const textPrimary = Color(0xFF1A1A1A);    // Near-black
static const textSecondary = Color(0xFF6B6B6B);  // Grey
static const accent = Color(0xFFE63946);          // Confident red

// Category accents (subtle, used sparingly)
static const categoryNowThen = Color(0xFFD4A574);      // Muted ochre
static const categoryEntertainment = Color(0xFFD4A5A5); // Dusty rose
static const categoryNearFar = Color(0xFF7C9299);       // Slate blue
static const categorySportMisc = Color(0xFF9CAF88);     // Sage green
static const categoryScienceTech = Color(0xFF9E9E9E);   // Cool grey
```

### Typography Scale

```dart
// Display — large numbers, scores
displayLarge: 72pt, Inter Tight, weight 700

// Headlines — category labels, screen titles
headlineLarge: 32pt, Inter, weight 600
headlineMedium: 24pt, Inter, weight 600

// Body — questions
bodyLarge: 20pt, Inter, weight 500
bodyMedium: 18pt, Inter, weight 400

// Labels — metadata, hints
labelLarge: 14pt, Inter, weight 500, uppercase, tracking 0.5
labelMedium: 12pt, Inter, weight 400, uppercase, tracking 0.5
```

### Spacing System

```dart
// Base unit: 8px
xs: 4px
sm: 8px
md: 16px
lg: 24px
xl: 32px
xxl: 48px
```

### UI Components

**Answer buttons**:
- Full-width, minimal border (1px textSecondary at 20% opacity)
- Generous padding (16px vertical, 20px horizontal)
- On hover/tap: border becomes textPrimary
- Selected correct: accent background, white text
- Selected wrong: textSecondary background, subtle

**Progress indicators**:
- Five dots representing the card's questions
- Filled (●) = answered, Half (◐) = current, Empty (○) = upcoming
- Horizontal layout, centered at bottom

**Cards/Containers**:
- No shadows, no rounded corners (or very subtle 4px radius)
- Borders only when necessary for grouping
- Background matches page background

### Animation Principles

- Subtle and functional, never decorative
- Transitions: 200-300ms ease-out
- Card transitions: horizontal slide or crossfade
- Answer feedback: brief highlight (150ms)
- Score counter: number tick-up animation

## Data Models

### Question

```dart
class Question {
  final String id;
  final Category category;
  final String textSv;           // Swedish question text
  final String textEn;           // English question text
  final List<String> optionsSv;  // 4 Swedish options
  final List<String> optionsEn;  // 4 English options
  final int correctIndex;        // 0-3
  final Difficulty difficulty;
  final String? funFactSv;       // Optional Swedish fun fact
  final String? funFactEn;       // Optional English fun fact
  final DateTime generatedAt;
}
```

### Category

```dart
enum Category {
  nowThen,        // Nu & Då / Now & Then
  entertainment,  // Nöje & Kultur / Entertainment & Culture
  nearFar,        // Nära & Fjärran / Near & Far
  sportMisc,      // Sport & Blandat / Sport & Misc
  scienceTech,    // Vetenskap & Teknik / Science & Tech
}
```

### Difficulty

```dart
enum Difficulty { easy, medium, hard }
```

### QuizCard

```dart
class QuizCard {
  final String id;
  final List<Question> questions;  // Always 5, one per category
  final DateTime createdAt;
}
```

### GameSession

```dart
class GameSession {
  final String id;
  final List<CardResult> completedCards;
  final int currentStreak;         // Consecutive cards with 5/5
  final DateTime startedAt;
}
```

### CardResult

```dart
class CardResult {
  final String cardId;
  final Map<Category, bool> results;  // Category -> correct/incorrect
  final int score;                     // 0-5
  final Duration timeTaken;
}
```

### PlayerStats

```dart
class PlayerStats {
  final int totalCardsPlayed;
  final int totalCorrect;
  final int bestStreak;
  final Map<Category, CategoryStats> categoryStats;
  final Difficulty currentDifficulty;  // Adaptive difficulty level
}
```

### CategoryStats

```dart
class CategoryStats {
  final int attempted;
  final int correct;
  double get accuracy => attempted > 0 ? correct / attempted : 0.0;
}
```

## Adaptive Difficulty Algorithm

```dart
// Difficulty adjusts based on rolling window of last 10 questions per category
// 
// If accuracy > 75% for 10+ questions: increase difficulty
// If accuracy < 40% for 10+ questions: decrease difficulty
// Otherwise: maintain current difficulty
//
// Each category tracks difficulty independently
// Questions are selected from the JSON pool at the player's current difficulty for that category
```

## Question Loading

### GitHub Repository

Questions are hosted in a GitHub repository: `https://github.com/raisanen/femman_questions`

The repository contains:
- `manifest.json`: Lists all available question JSON files
- Multiple question JSON files: Can be split across multiple files for organization

### Manifest Format

The `manifest.json` file can be structured in multiple ways:
- `{ "files": ["file1.json", "file2.json", ...] }`
- `{ "questions": ["file1.json", "file2.json", ...] }`
- `["file1.json", "file2.json", ...]` (direct array)

### JSON Question Format

Each question JSON file contains an array of question objects:

```json
[
  {
    "id": "unique_id",
    "category": "nowThen|entertainment|nearFar|sportMisc|scienceTech",
    "difficulty": "easy|medium|hard",
    "textSv": "Swedish question text",
    "textEn": "English question text",
    "optionsSv": ["option1", "option2", "option3", "option4"],
    "optionsEn": ["option1", "option2", "option3", "option4"],
    "correctIndex": 0,
    "funFactSv": "Swedish fun fact (optional)",
    "funFactEn": "English fun fact (optional)"
  }
]
```

### Loading Strategy

1. **GitHub loading (primary)**: On app startup, attempts to load questions from GitHub repository
   - Fetches `manifest.json` to discover available question files
   - Downloads and merges all question files listed in the manifest
   - Prevents duplicate questions by checking question IDs
2. **Asset fallback**: If GitHub loading fails (offline, network issues, etc.), falls back to `assets/questions.json`
3. **In-memory storage**: All questions kept in memory for fast access during gameplay
4. **Usage tracking**: Tracks recently used questions to avoid immediate repetition
5. **Manual reload**: Settings screen provides option to reload questions from GitHub
6. **Offline play**: App works fully offline using asset fallback or previously loaded questions

## Architecture

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_typography.dart
│   ├── constants/
│   │   └── app_strings.dart      # Bilingual strings
│   └── utils/
│       └── extensions.dart
│
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │
│   ├── quiz/
│   │   ├── quiz_screen.dart      # Main game screen
│   │   ├── quiz_controller.dart
│   │   └── widgets/
│   │       ├── question_view.dart
│   │       ├── answer_button.dart
│   │       ├── progress_dots.dart
│   │       └── category_label.dart
│   │
│   ├── results/
│   │   ├── results_screen.dart
│   │   └── widgets/
│   │       ├── score_display.dart
│   │       └── category_breakdown.dart
│   │
│   ├── stats/
│   │   ├── stats_screen.dart
│   │   └── widgets/
│   │
│   └── settings/
│       ├── settings_screen.dart
│       └── settings_controller.dart
│
├── models/
│   ├── question.dart
│   ├── quiz_card.dart
│   ├── game_session.dart
│   ├── player_stats.dart
│   ├── category.dart
│   └── difficulty.dart
│
├── services/
│   ├── question_service.dart       # Orchestrates loading from GitHub/assets
│   ├── github_question_loader.dart # Loads questions from GitHub repository
│   ├── json_question_loader.dart   # Loads questions from JSON assets (fallback)
│   ├── stats_service.dart          # Player statistics
│   └── settings_service.dart       # App preferences
│
├── data/
│   └── (removed - questions now in assets/questions.json)
│
└── assets/
    └── questions.json              # Question database
│
└── providers/
    ├── quiz_providers.dart
    ├── stats_providers.dart
    └── settings_providers.dart
```

## Screen Flow

```
┌─────────────┐
│    Home     │
│             │
│  [SPELA]    │──────────────────┐
│  [Statistik]│───┐              │
│  [Inställn.]│─┐ │              │
└─────────────┘ │ │              │
                │ │              ▼
                │ │      ┌─────────────┐
                │ │      │    Quiz     │
                │ │      │             │
                │ │      │  Q1 → Q2 →  │
                │ │      │  Q3 → Q4 →  │
                │ │      │  Q5         │
                │ │      └──────┬──────┘
                │ │             │
                │ │             ▼
                │ │      ┌─────────────┐
                │ │      │   Results   │
                │ │      │             │
                │ │      │   4/5       │
                │ │      │  [NÄSTA]    │────► Quiz (new card)
                │ │      │  [HEM]      │────► Home
                │ │      └─────────────┘
                │ │
                │ └────► ┌─────────────┐
                │        │    Stats    │
                │        └─────────────┘
                │
                └──────► ┌─────────────┐
                         │  Settings   │
                         │             │
                         │  Language   │
                         │  [SV] [EN]  │
                         │  Reload Q's │
                         │  Theme      │
                         └─────────────┘
```

## Bilingual Support

### Implementation

```dart
// AppStrings provides all UI text in both languages
class AppStrings {
  static String playButton(AppLanguage lang) =>
    lang == AppLanguage.sv ? 'SPELA' : 'PLAY';
  
  static String categoryName(Category cat, AppLanguage lang) {
    switch (cat) {
      case Category.nowThen:
        return lang == AppLanguage.sv ? 'Nu & Då' : 'Now & Then';
      // ...
    }
  }
}

// Questions have both languages stored
// User preference determines which to display
```

### Language Toggle

- Settings screen offers SV/EN toggle
- Persisted in SharedPreferences
- Affects all UI text and question display
- Category names shown in selected language

## Key Interactions

### Answering a Question

1. User taps answer option
2. Brief highlight animation (150ms)
3. Correct/incorrect state shown
4. Fun fact appears below question (if available)
5. After 1.5s (or tap), advance to next question
6. If last question, transition to Results screen

### Card Completion

1. Results screen shows score prominently (e.g., "4/5")
2. Category breakdown shows which were correct/incorrect
3. Streak counter updates
4. Stats updated in background
5. "Next Card" loads a new card from the question pool
6. "Home" returns to home screen

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Local storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.0
  
  # Utilities
  uuid: ^4.2.0
  google_fonts: ^6.1.0
  http: ^1.1.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  hive_generator: ^2.0.0
```

## Platform Configuration

### Android

- minSdkVersion: 21
- targetSdkVersion: 34
- Internet permission required for GitHub question loading (falls back to assets if unavailable)

### Web

- CanvasKit renderer for consistent typography
- No external dependencies required

## Testing Strategy

- **Unit tests**: Models, difficulty algorithm, stats calculations
- **Widget tests**: Core UI components (answer buttons, progress dots)
- **Integration tests**: Full card flow from question to results

## Future Considerations (Out of Scope for v1)

- Multiplayer pass-and-play mode
- Daily challenge cards
- Achievement system
- Social sharing of scores
- Question difficulty voting/feedback