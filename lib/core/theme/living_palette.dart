
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'app_colors.dart';

/// SONORA Living Palette.
///
/// Extracts colors from album artwork and generates
/// a dark, readable palette for the music player.
@immutable
class LivingPaletteData {
  const LivingPaletteData({
    required this.dominant,
    required this.background,
    required this.surface,
    required this.accent,
    required this.secondary,
    required this.waveformStart,
    required this.waveformEnd,
  });

  final Color dominant;
  final Color background;
  final Color surface;
  final Color accent;
  final Color secondary;
  final Color waveformStart;
  final Color waveformEnd;

  /// SONORA's default palette when artwork is unavailable.
  static const LivingPaletteData fallback = LivingPaletteData(
    dominant: AppColors.fallbackDominant,
    background: AppColors.fallbackBackground,
    surface: AppColors.surface,
    accent: AppColors.fallbackAccent,
    secondary: AppColors.fallbackSecondary,
    waveformStart: AppColors.fallbackAccent,
    waveformEnd: AppColors.fallbackSecondary,
  );

  /// Gradient used by the player background.
  LinearGradient get backgroundGradient {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        background,
        surface,
        const Color(0xFF090606),
      ],
    );
  }

  /// Gradient used by waveform and progress accents.
  LinearGradient get accentGradient {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        waveformStart,
        waveformEnd,
      ],
    );
  }
}

/// Extracts and caches palettes from album artwork.
abstract final class LivingPalette {
  LivingPalette._();

  static const int _maximumCacheEntries = 50;

  static final Map<String, Future<LivingPaletteData>> _cache = {};

  /// Extracts the dominant, vibrant and secondary colors
  /// from an album artwork image.
  ///
  /// Pass a unique cacheKey for each artwork to enable caching.
  static Future<LivingPaletteData> extract({
    required ImageProvider<Object> artwork,
    String? cacheKey,
  }) async {
    // Return cached palette if available.
    if (cacheKey != null && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final extraction = _extractPalette(artwork);

    if (cacheKey != null) {
      _cache[cacheKey] = extraction;

      // Keep the cache size limited.
      if (_cache.length > _maximumCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
    }

    return extraction;
  }

  /// Performs actual artwork color extraction.
  static Future<LivingPaletteData> _extractPalette(
    ImageProvider<Object> artwork,
  ) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        artwork,
        size: const Size(200, 200),
        maximumColorCount: 24,
      );

      final dominant =
          palette.dominantColor?.color ??
          AppColors.fallbackDominant;

      final vibrant =
          palette.vibrantColor?.color ??
          palette.darkVibrantColor?.color ??
          dominant;

      final secondary =
          palette.lightVibrantColor?.color ??
          palette.mutedColor?.color ??
          palette.darkMutedColor?.color ??
          AppColors.fallbackSecondary;

      // Generate a dark background that preserves
      // the identity of the album artwork.
      final background =
          AppColors.createDynamicBackground(dominant);

      final surface =
          AppColors.createDynamicSurface(dominant);

      // Keep accent colors bright enough for controls.
      final accent =
          AppColors.createDynamicAccent(vibrant);

      final waveformEnd =
          AppColors.createDynamicAccent(secondary);

      return LivingPaletteData(
        dominant: dominant,
        background: background,
        surface: surface,
        accent: accent,
        secondary: secondary,
        waveformStart: accent,
        waveformEnd: waveformEnd,
      );
    } catch (error, stackTrace) {
      debugPrint('SONORA Living Palette extraction failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      return LivingPaletteData.fallback;
    }
  }

  /// Clears all cached artwork palettes.
  static void clearCache() {
    _cache.clear();
  }

  /// Removes a particular artwork palette from cache.
  static void removeFromCache(String cacheKey) {
    _cache.remove(cacheKey);
  }

  /// Returns the current number of cached palettes.
  static int get cacheSize => _cache.length;
}
