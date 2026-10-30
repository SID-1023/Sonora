
abstract final class AppConstants {
  AppConstants._();

  // App information
  static const String appName = 'SONORA';
  static const String appTagline = 'Feel every frequency.';

  // Player configuration
  static const Duration defaultTrackDuration = Duration(minutes: 3, seconds: 30);
  static const Duration paletteTransitionDuration =
      Duration(milliseconds: 700);

  // Artwork configuration
  static const double artworkBorderRadius = 22.0;
  static const double artworkAspectRatio = 1.0;

  // Player configuration
  static const double miniPlayerHeight = 68.0;
  static const double progressBarHeight = 3.0;

  // Animation configuration
  static const Duration shortAnimationDuration =
      Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration =
      Duration(milliseconds: 350);
  static const Duration longAnimationDuration =
      Duration(milliseconds: 700);

  // Layout configuration
  static const double screenHorizontalPadding = 22.0;
  static const double sectionSpacing = 28.0;
  static const double cardBorderRadius = 18.0;
}
