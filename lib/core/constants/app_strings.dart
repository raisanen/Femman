/// Language options for Femman app
enum AppLanguage {
  sv, // Swedish
  en, // English
}

/// Bilingual string resources for Femman.
/// All UI text available in Swedish and English.
class AppStrings {
  AppStrings._();

  // ===== HOME SCREEN =====

  static String playButton(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Spela' : 'Play';

  static String statsButton(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Statistik' : 'Statistics';

  static String settingsButton(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Inställningar' : 'Settings';

  static String appTitle(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Femman' : 'Femman';

  // ===== QUIZ SCREEN =====

  static String questionNumber(AppLanguage lang, int current, int total) =>
      lang == AppLanguage.sv
          ? 'Fråga $current av $total'
          : 'Question $current of $total';

  static String funFact(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Rolig fakta' : 'Fun fact';

  static String tapToContinue(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Tryck för att fortsätta' : 'Tap to continue';

  static String nextQuestionButton(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Nästa fråga' : 'Next question';

  // ===== CATEGORY NAMES =====

  static String categoryNowThen(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Nu & Då' : 'Now & Then';

  static String categoryEntertainment(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Nöje & Kultur' : 'Entertainment & Culture';

  static String categoryNearFar(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'När & Fjärran' : 'Near & Far';

  static String categorySportMisc(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Sport & Blandat' : 'Sport & Misc';

  static String categoryScienceTech(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Vetenskap & Teknik' : 'Science & Tech';

  // ===== RESULTS SCREEN =====

  static String cardComplete(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Kort slutfört!' : 'Card complete!';

  static String scoreDisplay(AppLanguage lang, int score, int total) =>
      lang == AppLanguage.sv ? '$score av $total rätt' : '$score of $total correct';

  static String perfectScore(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Perfekt!' : 'Perfect!';

  static String goodScore(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Bra jobbat!' : 'Good job!';

  static String keepTrying(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Försök igen!' : 'Keep trying!';

  static String nextCardButton(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Nästa kort' : 'Next card';

  static String homeButton(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Hem' : 'Home';

  static String correct(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Rätt' : 'Correct';

  static String incorrect(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Fel' : 'Incorrect';

  static String categoryBreakdown(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Resultat per kategori' : 'Results by category';

  static String currentStreak(AppLanguage lang, int streak) =>
      lang == AppLanguage.sv
          ? 'Nuvarande serie: $streak'
          : 'Current streak: $streak';

  // ===== STATS SCREEN =====

  static String statsTitle(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Statistik' : 'Statistics';

  static String totalCards(AppLanguage lang, int count) =>
      lang == AppLanguage.sv
          ? 'Totalt kort spelade: $count'
          : 'Total cards played: $count';

  static String totalCorrect(AppLanguage lang, int count) =>
      lang == AppLanguage.sv ? 'Totalt rätt: $count' : 'Total correct: $count';

  static String bestStreak(AppLanguage lang, int streak) =>
      lang == AppLanguage.sv ? 'Bästa serie: $streak' : 'Best streak: $streak';

  static String accuracy(AppLanguage lang, double percentage) =>
      lang == AppLanguage.sv
          ? 'Procent rätt: ${percentage.toStringAsFixed(1)}%'
          : 'Accuracy: ${percentage.toStringAsFixed(1)}%';

  static String categoryStats(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Statistik per kategori' : 'Category statistics';

  static String currentDifficulty(AppLanguage lang, String difficulty) =>
      lang == AppLanguage.sv
          ? 'Nuvarande nivå: $difficulty'
          : 'Current difficulty: $difficulty';

  // ===== SETTINGS SCREEN =====

  static String settingsTitle(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Inställningar' : 'Settings';

  static String languageLabel(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Språk' : 'Language';

  static String languageSwedish(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Svenska' : 'Swedish';

  static String languageEnglish(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Engelska' : 'English';

  // ===== DIFFICULTY LEVELS =====

  static String difficultyEasy(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Lätt' : 'Easy';

  static String difficultyMedium(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Medel' : 'Medium';

  static String difficultyHard(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Svår' : 'Hard';

  // ===== COMMON / STATES =====

  static String loading(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Laddar...' : 'Loading...';

  static String error(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Något gick fel' : 'Something went wrong';

  static String retry(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'FÖRSÖK IGEN' : 'RETRY';

  static String errorLoadingQuestions(AppLanguage lang) =>
      lang == AppLanguage.sv
          ? 'Kunde inte ladda frågor'
          : 'Could not load questions';

  static String noInternet(AppLanguage lang) =>
      lang == AppLanguage.sv
          ? 'Ingen internetanslutning'
          : 'No internet connection';

  static String generatingQuestions(AppLanguage lang) =>
      lang == AppLanguage.sv
          ? 'Genererar nya frågor...'
          : 'Generating new questions...';

  static String ok(AppLanguage lang) => lang == AppLanguage.sv ? 'OK' : 'OK';

  static String cancel(AppLanguage lang) =>
      lang == AppLanguage.sv ? 'Avbryt' : 'Cancel';
}
