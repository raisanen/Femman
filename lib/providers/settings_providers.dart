import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../core/constants/app_strings.dart';

/// Provider for the SettingsService singleton instance
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the current app language
/// This is a StateNotifier that allows reactive updates when language changes
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
  (ref) => LanguageNotifier(ref.watch(settingsServiceProvider)),
);

/// Notifier for managing language state
class LanguageNotifier extends StateNotifier<AppLanguage> {
  final SettingsService _settingsService;

  LanguageNotifier(this._settingsService)
      : super(_settingsService.getLanguage()) {
    // Listen to language changes from the service
    _settingsService.languageStream.listen((language) {
      state = language;
    });
  }

  /// Change the app language
  Future<void> setLanguage(AppLanguage language) async {
    await _settingsService.setLanguage(language);
    state = language;
  }

  /// Toggle between Swedish and English
  Future<void> toggleLanguage() async {
    final newLanguage =
        state == AppLanguage.sv ? AppLanguage.en : AppLanguage.sv;
    await setLanguage(newLanguage);
  }
}

/// Provider for onboarding completion status
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return service.hasCompletedOnboarding();
});

/// Provider to set onboarding completion
final setOnboardingCompletedProvider =
    Provider.family<Future<void> Function(), bool>((ref, completed) {
  return () async {
    final service = ref.read(settingsServiceProvider);
    await service.setHasCompletedOnboarding(completed);
    // Refresh the onboarding status provider
    ref.invalidate(hasCompletedOnboardingProvider);
  };
});
