import 'package:flutter/material.dart';

/// SONORA — Dynamic Living Palette Design System.
///
/// Provides permanent fallback colors and reusable
/// dynamic colors for artwork-driven music experiences.
abstract final class AppColors {
  AppColors._();

  // ==================================================
  // 1. DEFAULT SONORA IDENTITY
  // ==================================================

  static const Color background = Color(0xFF090606);
  static const Color surface = Color(0xFF1B0A0B);

  static const Color cosmicRed = Color(0xFFFF3038);
  static const Color fieryOrange = Color(0xFFFF713D);

  static const Color warmCream = Color(0xFFF6E8DC);
  static const Color secondaryText = Color(0xFFA7A7A7);

  // ==================================================
  // 2. DEFAULT SURFACE COLORS
  // ==================================================

  static const Color cardBackground = Color(0xFF160B0C);
  static const Color elevatedSurface = Color(0xFF241011);

  static const Color divider = Color(0xFF382022);
  static const Color progressTrack = Color(0xFF422326);

  // ==================================================
  // 3. PLAYER DEFAULT COLORS
  // ==================================================

  static const Color waveformRed = cosmicRed;
  static const Color waveformOrange = fieryOrange;

  static const Color activeIcon = warmCream;
  static const Color inactiveIcon = Color(0xFF777070);

  static const Color playerOverlay = Color(0xCC090606);

  // ==================================================
  // 4. LIVING PALETTE FALLBACK COLORS
  // ==================================================

  /// Default background tint when artwork is unavailable.
  static const Color fallbackBackground = Color(0xFF14090B);

  /// Default dominant artwork color.
  static const Color fallbackDominant = Color(0xFF651C25);

  /// Default vibrant accent color.
  static const Color fallbackAccent = cosmicRed;

  /// Default secondary accent.
  static const Color fallbackSecondary = fieryOrange;

  // ==================================================
  // 5. DYNAMIC COLOR GENERATION HELPERS
  // ==================================================

  /// Creates a dark background from an extracted artwork color.
  ///
  /// Keeps the interface dark even when album artwork
  /// contains extremely bright or saturated colors.
  static Color createDynamicBackground(Color dominant) {
    final hsl = HSLColor.fromColor(dominant);

    return hsl
        .withLightness((hsl.lightness * 0.16).clamp(0.025, 0.12))
        .withSaturation((hsl.saturation * 0.65).clamp(0.15, 0.85))
        .toColor();
  }

  /// Creates a subtle elevated surface based on artwork.
  static Color createDynamicSurface(Color dominant) {
    final hsl = HSLColor.fromColor(dominant);

    return hsl
        .withLightness((hsl.lightness * 0.25).clamp(0.045, 0.18))
        .withSaturation((hsl.saturation * 0.55).clamp(0.10, 0.75))
        .toColor();
  }

  /// Creates a readable accent from extracted artwork colors.
  static Color createDynamicAccent(Color vibrant) {
    final hsl = HSLColor.fromColor(vibrant);

    return hsl
        .withSaturation(hsl.saturation.clamp(0.45, 0.95))
        .withLightness(hsl.lightness.clamp(0.48, 0.72))
        .toColor();
  }

  // ==================================================
  // 6. STATIC GRADIENTS
  // ==================================================

  static const LinearGradient cinematicBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF240B0D), background, Color(0xFF090606)],
  );

  static const LinearGradient albumArtworkOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x33090606), Color(0xFF090606)],
    stops: [0.0, 0.65, 1.0],
  );

  static const LinearGradient cosmicRedOrangeGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cosmicRed, fieryOrange],
  );

  static const LinearGradient miniPlayerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF281012), Color(0xFF16090A)],
  );

  // ==================================================
  // 7. DYNAMIC GRADIENT GENERATOR
  // ==================================================

  /// Creates a gradient using the currently selected song's
  /// extracted artwork colors.
  static LinearGradient createLivingGradient({
    required Color dominant,
    required Color vibrant,
    required Color secondary,
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        createDynamicBackground(dominant),
        createDynamicSurface(dominant),
        vibrant.withValues(alpha: 0.16),
        secondary.withValues(alpha: 0.08),
      ],
    );
  }
}
