
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/song.dart';
import '../state/player_controller.dart';

class TrackOptionsSheet extends StatelessWidget {
  const TrackOptionsSheet({
    super.key,
    required this.song,
    required this.controller,
    this.accentColor = AppColors.cosmicRed,
    this.onFavorite,
    this.onShare,
    this.onAlbumDetails,
  });

  final Song song;
  final PlayerController controller;
  final Color accentColor;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onAlbumDetails;

  static Future<void> show(
    BuildContext context, {
    required Song song,
    required PlayerController controller,
    Color accentColor = AppColors.cosmicRed,
    VoidCallback? onFavorite,
    VoidCallback? onShare,
    VoidCallback? onAlbumDetails,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => TrackOptionsSheet(
        song: song,
        controller: controller,
        accentColor: accentColor,
        onFavorite: onFavorite,
        onShare: onShare,
        onAlbumDetails: onAlbumDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _buildArtwork(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.warmCream,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: AppColors.divider.withValues(alpha: 0.8)),
                _option(
                  icon: Icons.queue_music_rounded,
                  title: 'Add to queue',
                  subtitle: 'Play this track later',
                  onTap: () async {
                    await controller.addToQueue(song);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _option(
                  icon: Icons.favorite_border_rounded,
                  title: 'Add to favourites',
                  subtitle: 'Keep this track close',
                  onTap: () {
                    Navigator.pop(context);
                    onFavorite?.call();
                  },
                ),
                _option(
                  icon: Icons.album_rounded,
                  title: 'Album details',
                  subtitle: song.album,
                  onTap: () {
                    Navigator.pop(context);
                    onAlbumDetails?.call();
                  },
                ),
                _option(
                  icon: Icons.share_outlined,
                  title: 'Share track',
                  subtitle: 'Share your music',
                  onTap: () {
                    Navigator.pop(context);
                    onShare?.call();
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    final imageProvider = song.isNetworkArtwork
        ? NetworkImage(song.artwork) as ImageProvider
        : AssetImage(song.artwork) as ImageProvider;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: imageProvider,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 58,
          height: 58,
          color: AppColors.cardBackground,
          child: const Icon(
            Icons.music_note_rounded,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.warmCream, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.warmCream,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 11,
        ),
      ),
      onTap: onTap,
    );
  }
}
