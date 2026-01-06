import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_strings.dart';

/// Service for managing app settings using SharedPreferences.
/// Provides typed access to user preferences with reactive updates.
class SettingsService {
  static const _keyLanguage = 'language';
  static const _keyHasCompletedOnboarding = 'hasCompletedOnboarding';

  SharedPreferences? _prefs;

  // Stream controller for language changes
  final _languageController = StreamController<AppLanguage>.broadcast();

  /// Stream of language changes for reactive UI updates
  Stream<AppLanguage> get languageStream => _languageController.stream;

  /// Initialize the service and load preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the current language preference
  /// Defaults to Swedish if not set
  /// Returns default if service hasn't been initialized yet
  AppLanguage getLanguage() {
    if (_prefs == null) {
      return AppLanguage.sv; // Default if not initialized
    }

    final languageString = _prefs!.getString(_keyLanguage);
    if (languageString == null) {
      return AppLanguage.sv; // Default to Swedish
    }

    try {
      return AppLanguage.values.firstWhere(
        (lang) => lang.toString() == 'AppLanguage.$languageString',
      );
    } catch (_) {
      return AppLanguage.sv; // Fallback to Swedish on error
    }
  }

  /// Set the language preference
  /// Notifies listeners via stream
  Future<void> setLanguage(AppLanguage language) async {
    if (_prefs == null) {
      // Service not initialized, just update stream
      _languageController.add(language);
      return;
    }
    final languageString = language.toString().split('.').last;
    await _prefs!.setString(_keyLanguage, languageString);
    _languageController.add(language);
  }

  /// Get onboarding completion status
  bool hasCompletedOnboarding() {
    if (_prefs == null) return false;
    return _prefs!.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  /// Set onboarding completion status
  Future<void> setHasCompletedOnboarding(bool completed) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_keyHasCompletedOnboarding, completed);
  }

  /// Clear all settings (useful for testing or reset functionality)
  Future<void> clearAll() async {
    if (_prefs == null) return;
    await _prefs!.clear();
    _languageController.add(AppLanguage.sv); // Reset to default
  }

  /// Dispose resources
  void dispose() {
    _languageController.close();
  }
}
