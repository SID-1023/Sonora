
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/song.dart';
import '../state/player_controller.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({
    super.key,
    required this.controller,
    this.accentColor = AppColors.cosmicRed,
  });

  final PlayerController controller;
  final Color accentColor;

  static Future<void> show(
    BuildContext context, {
    required PlayerController controller,
    Color accentColor = AppColors.cosmicRed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => QueueSheet(
        controller: controller,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 20,
              sigmaY: 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.97),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final songs = controller.queue;

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildHandle(),
                      _buildHeader(context, songs.length),
                      _buildCurrentTrack(),
                      const Divider(
                        color: AppColors.divider,
                        height: 1,
                      ),
                      Expanded(
                        child: songs.isEmpty
                            ? _buildEmptyQueue()
                            : ReorderableListView.builder(
                                scrollController: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  30,
                                ),
                                itemCount: songs.length,
                                onReorder: controller.reorderQueue,
                                itemBuilder: (context, index) {
                                  final song = songs[index];
                                  final isCurrent =
                                      index == controller.currentIndex;

                                  return _QueueSongTile(
                                    key: ValueKey(song.id),
                                    song: song,
                                    index: index,
                                    isCurrent: isCurrent,
                                    accentColor: accentColor,
                                    onRemove: () {
                                      controller.removeFromQueue(index);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 16, 20),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR SOUNDSPACE',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Playing queue',
                  style: TextStyle(
                    color: AppColors.warmCream,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count TRACKS',
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.warmCream,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTrack() {
    final song = controller.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.graphic_eq_rounded,
            color: AppColors.cosmicRed,
            size: 21,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'CURRENTLY PLAYING',
              style: TextStyle(
                color: AppColors.warmCream,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            song.formattedDuration,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueue() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 48,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: 14),
          Text(
            'Your queue is empty',
            style: TextStyle(
              color: AppColors.warmCream,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add some music to keep listening.',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueSongTile extends StatelessWidget {
  const _QueueSongTile({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.accentColor,
    required this.onRemove,
  });

  final Song song;
  final int index;
  final bool isCurrent;
  final Color accentColor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final artwork = song.isNetworkArtwork
        ? NetworkImage(song.artwork) as ImageProvider
        : AssetImage(song.artwork) as ImageProvider;

    return Container(
      key: ValueKey('${song.id}_$index'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: artwork,
              width: 49,
              height: 49,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 49,
                height: 49,
                color: AppColors.cardBackground,
                child: const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent
                        ? accentColor
                        : AppColors.warmCream,
                    fontSize: 13,
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
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            song.formattedDuration,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 10,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.secondaryText,
              size: 18,
            ),
          ),
          const Icon(
            Icons.drag_handle_rounded,
            color: AppColors.secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }
}
