class AppConstants {
  // App Information
  static const String appName = 'Menutri';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://www.menutri.nl/api/v1';
  static const String apiVersion = 'v1';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String isFirstLaunchKey = 'is_first_launch';

  // User Roles
  static const String guestRole = 'gast';
  static const String cateraarRole = 'cateraar';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Image Sizes
  static const double avatarSize = 40.0;
  static const double largeAvatarSize = 80.0;
  static const double restaurantImageHeight = 200.0;
  static const double dishImageHeight = 150.0;

  // Map Configuration
  static const double defaultZoom = 14.0;
  static const double searchRadius = 10.0; // km

  // Nutrition Targets (default values)
  static const int defaultCalorieTarget = 2000;
  static const int defaultProteinTarget = 150; // grams
  static const int defaultCarbsTarget = 250; // grams
  static const int defaultFatTarget = 65; // grams

  // File Upload
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // QR Code
  static const double qrCodeSize = 200.0;
  static const String qrCodePrefix = 'menutri://';

  // External App URLs
  static const String myFitnessPalScheme = 'myfitnesspal://';
  static const String googleFitPackage = 'com.google.android.apps.fitness';
  static const String appleHealthBundle = 'com.apple.Health';

  // Error Messages
  static const String networkErrorMessage =
      'Netwerkfout. Controleer je internetverbinding.';
  static const String serverErrorMessage =
      'Serverfout. Probeer het later opnieuw.';
  static const String unknownErrorMessage =
      'Er is een onbekende fout opgetreden.';
  static const String authErrorMessage = 'Authenticatiefout. Log opnieuw in.';

  // Success Messages
  static const String loginSuccessMessage = 'Succesvol ingelogd!';
  static const String registerSuccessMessage = 'Account succesvol aangemaakt!';
  static const String profileUpdateSuccessMessage = 'Profiel bijgewerkt!';
  static const String favoriteAddedMessage = 'Toegevoegd aan favorieten!';
  static const String favoriteRemovedMessage = 'Verwijderd uit favorieten!';
}
