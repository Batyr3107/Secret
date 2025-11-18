/// Конфигурация приложения
class AppConfig {
  // Версия приложения
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // Database
  static const String databaseName = 'context_keeper.db';
  static const int databaseVersion = 1;

  // UI
  static const int searchDebounceMs = 300;
  static const int maxNoteLengthChars = 5000;
  static const int overlayDisplayDurationSeconds = 30;

  // Permissions
  static const List<String> requiredAndroidPermissions = [
    'android.permission.READ_PHONE_STATE',
    'android.permission.READ_CONTACTS',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.POST_NOTIFICATIONS',
  ];

  static const List<String> requiredIOSPermissions = [
    'NSContactsUsageDescription',
    'NSUserNotificationsUsageDescription',
  ];

  // Features flags
  static const bool enableVoiceInput = false; // TODO: Implement
  static const bool enableCloudSync = false; // TODO: Implement
  static const bool enableAISuggestions = false; // TODO: Implement
  static const bool enableBiometrics = false; // TODO: Implement

  // Limits
  static const int maxNotesCount = 10000; // Защита от переполнения
  static const int maxContactsToLoad = 5000;

  // Analytics (если будет)
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;

  // Developer
  static const bool isDevelopment = true;
  static const bool showDebugInfo = true;

  /// Получить строку с информацией о версии
  static String get versionString => 'v$appVersion ($buildNumber)';

  /// Проверить доступность фичи
  static bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'voice_input':
        return enableVoiceInput;
      case 'cloud_sync':
        return enableCloudSync;
      case 'ai_suggestions':
        return enableAISuggestions;
      case 'biometrics':
        return enableBiometrics;
      default:
        return false;
    }
  }
}
