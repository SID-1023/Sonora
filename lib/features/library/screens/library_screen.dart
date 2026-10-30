
import 'package:flutter/material.dart';

import 'package:sonora/core/theme/app_colors.dart';
import 'package:sonora/features/player/models/song.dart';
import 'package:sonora/features/player/state/player_scope.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _filterSongs(List<Song> songs) {
    return songs.where((song) {
      final matchesSearch = song.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.album.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = switch (_selectedFilter) {
        'Favorites' => song.isFavorite,
        'Albums' => true,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlayerScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final songs = _filterSongs(controller.queue);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'YOUR COLLECTION',
                                    style: TextStyle(
                                      color: AppColors.fieryOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Your Library',
                                    style: TextStyle(
                                      color: AppColors.warmCream,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '${controller.queue.length} tracks in your soundspace',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.library_music_rounded,
                                color: AppColors.fieryOrange,
                                size: 23,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Search
                        Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.divider,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            style: const TextStyle(
                              color: AppColors.warmCream,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search your music...',
                              hintStyle: const TextStyle(
                                color: AppColors.secondaryText,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.secondaryText,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: AppColors.secondaryText,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Favorites', 'Albums']
                                .map((filter) {
                              final selected = _selectedFilter == filter;

                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedFilter = filter);
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.cosmicRed
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.cosmicRed
                                            : AppColors.divider,
                                      ),
                                    ),
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.secondaryText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'All tracks',
                              style: TextStyle(
                                color: AppColors.warmCream,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${songs.length} SONGS',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                if (songs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = songs[index];

                          return _buildSongTile(
                            song: song,
                            isPlaying: controller.currentSong?.id == song.id &&
                                controller.isPlaying,
                            isCurrent: controller.currentSong?.id == song.id,
                            onTap: () async {
                              await controller.loadSong(song);
                              await controller.play();
                            },
                          );
                        },
                        childCount: songs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.album_rounded,
                size: 45,
                color: AppColors.fieryOrange,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No tracks found'
                  : 'Your soundspace is waiting',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.warmCream,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with a different title or artist.'
                  : 'Your music collection will appear here once you add tracks to SONORA.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile({
    required Song song,
    required bool isPlaying,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final artworkProvider = song.isNetworkArtwork
        ? NetworkImage(song.artwork) as ImageProvider
        : AssetImage(song.artwork) as ImageProvider;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: isCurrent
            ? AppColors.elevatedSurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image(
                    image: artworkProvider,
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 55,
                      height: 55,
                      color: AppColors.elevatedSurface,
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: AppColors.fieryOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                              ? AppColors.fieryOrange
                              : AppColors.warmCream,
                          fontSize: 14,
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
                Text(
                  song.formattedDuration,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 9),
                Icon(
                  isPlaying
                      ? Icons.equalizer_rounded
                      : Icons.play_circle_outline_rounded,
                  color: isCurrent
                      ? AppColors.fieryOrange
                      : AppColors.secondaryText,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
