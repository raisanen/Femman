import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:femman/core/constants/app_spacing.dart';
import 'package:femman/core/constants/app_strings.dart';
import 'package:femman/core/theme/app_colors.dart';
import 'package:femman/core/theme/app_theme.dart';
import 'package:femman/features/home/home_screen.dart';
import 'package:femman/features/quiz/quiz_screen.dart';
import 'package:femman/features/results/results_screen.dart';
import 'package:femman/features/settings/settings_screen.dart';
import 'package:femman/features/stats/stats_screen.dart';
import 'package:femman/models/card_result.dart';
import 'package:femman/providers/quiz_providers.dart';
import 'package:femman/providers/settings_providers.dart';
import 'package:femman/providers/stats_providers.dart';

/// Root Femman app widget.
///
/// Handles:
/// - Firebase initialization
/// - Hive initialization
/// - Core service initialization (settings, stats, questions)
/// - Loading / error states during startup
class FemmanApp extends ConsumerStatefulWidget {
  const FemmanApp({super.key});

  @override
  ConsumerState<FemmanApp> createState() => _FemmanAppState();
}

class _FemmanAppState extends ConsumerState<FemmanApp> {
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize(ref);
  }

  Future<void> _retryInit() async {
    setState(() {
      _initFuture = _initialize(ref);
    });
  }

  static Future<void> _initialize(WidgetRef ref) async {
    // Initialize Hive
    await Hive.initFlutter();

    // Initialize Firebase (best-effort)
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // In this minimalist app, failure to init Firebase should not crash the UI.
    }

    // Initialize settings (SharedPreferences)
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.init();

    // Initialize stats (Hive boxes)
    final statsService = ref.read(statsServiceProvider);
    await statsService.init();

    // Initialize question service (Hive cache + Gemini)
    final questionService = ref.read(questionServiceProvider);
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isNotEmpty) {
      await questionService.init(geminiApiKey: apiKey);
      // Optionally warm up cache on startup
      await ref.read(quizNotifierProvider.notifier).warmupCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: _LoadingScreen(language: language),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: _ErrorScreen(
              language: language,
              onRetry: _retryInit,
            ),
          );
        }

        return MaterialApp(
          title: 'Femman',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(
            scaffoldBackgroundColor: AppColors.background,
          ),
          initialRoute: '/',
          routes: {
            '/': (_) => const HomeScreen(),
            '/quiz': (_) => const QuizScreen(),
            '/stats': (_) => const StatsScreen(),
            '/settings': (_) => const SettingsScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/results') {
              final args = settings.arguments;
              if (args is CardResult) {
                return MaterialPageRoute(
                  builder: (_) => ResultsScreen(result: args),
                  settings: settings,
                );
              }
            }
            return null;
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.textPrimary,
              strokeWidth: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.loading(language),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.language,
    required this.onRetry,
  });

  final AppLanguage language;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.error(language),
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                language == AppLanguage.sv
                    ? 'Kunde inte starta appen.'
                    : 'Failed to initialize the app.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(AppStrings.retry(language)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
