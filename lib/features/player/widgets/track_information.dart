import 'package:flutter/material.dart';

class TrackInformation extends StatelessWidget {
  final String title;
  final String artist;
  final String album;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const TrackInformation({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (album.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onFavoriteTap,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? const Color(0xFFFF654F) : Colors.white70,
            size: 25,
          ),
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        ),
      ],
    );
  }
}
