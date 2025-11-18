/// Application-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================================
  // UI Constants
  // ============================================

  /// Default padding used throughout the app
  static const double defaultPadding = 16.0;

  /// Small padding for compact layouts
  static const double smallPadding = 8.0;

  /// Large padding for spacious layouts
  static const double largePadding = 24.0;

  /// Card elevation
  static const double cardElevation = 8.0;

  /// Default border radius
  static const double borderRadius = 12.0;

  /// Icon sizes
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 64.0;

  // ============================================
  // Search & Input
  // ============================================

  /// Debounce delay for search input (milliseconds)
  static const int searchDebounceMs = 300;

  /// Maximum length for contact notes
  static const int maxNoteLength = 5000;

  /// Minimum search query length
  static const int minSearchLength = 2;

  // ============================================
  // Database
  // ============================================

  /// Database name
  static const String databaseName = 'context_keeper.db';

  /// Database version
  static const int databaseVersion = 1;

  /// Maximum number of notes to load at once (for pagination)
  static const int notesPageSize = 50;

  /// Maximum total notes allowed
  static const int maxNotesCount = 10000;

  // ============================================
  // Android Overlay
  // ============================================

  /// Overlay display duration (seconds)
  static const int overlayDurationSeconds = 30;

  /// Overlay Y position from top (pixels)
  static const int overlayYPosition = 100;

  /// Overlay window margin
  static const double overlayMargin = 16.0;

  // ============================================
  // Notifications
  // ============================================

  /// SnackBar display duration (seconds)
  static const int snackBarDurationSeconds = 2;

  /// Error SnackBar duration (seconds)
  static const int errorSnackBarDurationSeconds = 4;

  // ============================================
  // Permissions
  // ============================================

  /// Delay before checking permissions (milliseconds)
  static const int permissionsCheckDelayMs = 500;

  // ============================================
  // Animation Durations
  // ============================================

  /// Short animation duration (milliseconds)
  static const int animationShort = 200;

  /// Medium animation duration (milliseconds)
  static const int animationMedium = 300;

  /// Long animation duration (milliseconds)
  static const int animationLong = 500;

  // ============================================
  // Text Styles
  // ============================================

  /// Empty state icon size
  static const double emptyStateIconSize = 80.0;

  /// Title font size
  static const double titleFontSize = 20.0;

  /// Body font size
  static const double bodyFontSize = 16.0;

  /// Caption font size
  static const double captionFontSize = 14.0;

  // ============================================
  // Limits
  // ============================================

  /// Maximum contacts to load from device
  static const int maxContactsToLoad = 5000;

  /// Maximum phone number variations to try for matching
  static const int maxPhoneVariations = 4;

  // ============================================
  // App Info
  // ============================================

  /// App version
  static const String appVersion = '1.0.0';

  /// Build number
  static const int buildNumber = 1;

  /// App name
  static const String appName = 'Context Keeper';

  /// Package name
  static const String packageName = 'com.example.context_keeper';

  // ============================================
  // Method Channel Names
  // ============================================

  /// Phone service method channel
  static const String phoneChannelName = 'com.example.context_keeper/phone';

  /// CallKit method channel (iOS)
  static const String callKitChannelName = 'com.example.context_keeper/callkit';

  // ============================================
  // Firebase
  // ============================================

  /// FCM topic for all users
  static const String fcmTopicAll = 'all_users';

  // ============================================
  // Colors (for consistency)
  // ============================================

  /// Success color hex
  static const int successColorValue = 0xFF4CAF50;

  /// Error color hex
  static const int errorColorValue = 0xFFF44336;

  /// Warning color hex
  static const int warningColorValue = 0xFFFF9800;

  /// Info color hex
  static const int infoColorValue = 0xFF2196F3;
}
