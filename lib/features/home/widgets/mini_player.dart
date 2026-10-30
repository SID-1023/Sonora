
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.title,
    required this.artist,
    required this.artwork,
    required this.isPlaying,
    required this.progress,
    required this.accentColor,
    required this.onTap,
    required this.onPlayPause,
  });

  final String title;
  final String artist;
  final String artwork;
  final bool isPlaying;
  final double progress;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;

  bool get _isNetworkImage =>
      artwork.startsWith('https://') ||
      artwork.startsWith('http://');

  bool get _hasArtwork => artwork.trim().isNotEmpty;

  Widget _buildArtwork() {
    if (!_hasArtwork) {
      return _buildPlaceholder();
    }

    return Image(
      image: _isNetworkImage
          ? NetworkImage(artwork)
          : AssetImage(artwork) as ImageProvider,
      width: 49,
      height: 49,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: accentColor,
        size: 27,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _buildArtwork(),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.warmCream,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: onPlayPause,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: accentColor,
                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 5),
                ],
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: AppColors.progressTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    accentColor,
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
