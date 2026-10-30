
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AlbumArtworkView extends StatelessWidget {
  const AlbumArtworkView({
    super.key,
    required this.artwork,
    this.size = 280,
    this.borderRadius = 24,
  });

  final String artwork;
  final double size;
  final double borderRadius;

  bool get _isNetworkImage =>
      artwork.startsWith('https://') ||
      artwork.startsWith('http://');

  ImageProvider get _imageProvider {
    return _isNetworkImage
        ? NetworkImage(artwork)
        : AssetImage(artwork);
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'sonora_album_artwork_$artwork',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.cosmicRed.withValues(alpha: 0.28),
              blurRadius: 45,
              spreadRadius: 2,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: _imageProvider,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                frameBuilder: (
                  context,
                  child,
                  frame,
                  wasSynchronouslyLoaded,
                ) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  }

                  return Container(
                    color: AppColors.cardBackground,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppColors.cosmicRed,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.cardBackground,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.secondaryText,
                      size: 65,
                    ),
                  );
                },
              ),

              // Subtle cinematic artwork shading.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
