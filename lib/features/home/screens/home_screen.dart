
import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../player/data/local_song_catalogue.dart';
import '../../player/state/player_scope.dart';
import '../widgets/mini_player.dart';
import '../widgets/mood_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMood = 'Chill';

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Chill',
      'icon': Icons.nightlight_round,
      'color': const Color(0xFF8876C9),
    },
    {
      'name': 'Focus',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFB66A36),
    },
    {
      'name': 'Energy',
      'icon': Icons.local_fire_department_rounded,
      'color': AppColors.cosmicRed,
    },
    {
      'name': 'Dreamy',
      'icon': Icons.cloud_rounded,
      'color': const Color(0xFF597F9D),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final player = PlayerScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context),
                  const SizedBox(height: 34),
                  _buildGreeting(),
                  const SizedBox(height: 25),
                  _buildFeaturedCard(context),
                  const SizedBox(height: 35),
                  _buildSectionTitle(
                    'Explore your mood',
                    'Find your frequency',
                  ),
                  const SizedBox(height: 18),
                  _buildMoodList(),
                  const SizedBox(height: 35),

                  // Local music catalogue
                  _buildSectionTitle(
                    'Your local music',
                    '${LocalSongCatalogue.songs.length} tracks in your collection',
                  ),
                  const SizedBox(height: 18),
                  ...LocalSongCatalogue.songs.map(
                    (song) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLocalSongCard(
                        context,
                        song,
                        player,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  _buildSectionTitle(
                    'Recently played',
                    'Your listening journey',
                  ),
                  const SizedBox(height: 18),
                  AnimatedBuilder(
                    animation: player,
                    builder: (context, _) {
                      final song = player.currentSong;

                      if (song == null) {
                        return _buildEmptyMusicState();
                      }

                      return _buildCurrentTrackCard(
                        context,
                        song.title,
                        song.artist,
                        song.artwork,
                        player.duration,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: player,
        builder: (context, _) {
          final song = player.currentSong;

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (song != null) ...[
                      MiniPlayer(
                        title: song.title,
                        artist: song.artist,
                        artwork: song.artwork,
                        isPlaying: player.isPlaying,
                        progress: player.progress,
                        accentColor: player.palette.accent,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.nowPlaying,
                          );
                        },
                        onPlayPause: player.togglePlayPause,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildBottomNavigation(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // LOCAL SONG CARD
  // --------------------------------------------------

  Widget _buildLocalSongCard(
    BuildContext context,
    dynamic song,
    dynamic player,
  ) {
    final imageProvider = song.isNetworkArtwork
        ? NetworkImage(song.artwork) as ImageProvider
        : AssetImage(song.artwork) as ImageProvider;

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await player.loadSong(song);

          if (!context.mounted) return;

          if (player.playbackError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(player.playbackError!),
                backgroundColor: AppColors.cardBackground,
              ),
            );
            return;
          }

          Navigator.pushNamed(
            context,
            AppRoutes.nowPlaying,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: imageProvider,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 58,
                    height: 58,
                    color: AppColors.elevatedSurface,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.secondaryText,
                      size: 25,
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
                      style: const TextStyle(
                        color: AppColors.warmCream,
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
              const SizedBox(width: 10),
              const Icon(
                Icons.play_circle_outline_rounded,
                color: AppColors.fieryOrange,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SONORA',
              style: TextStyle(
                color: AppColors.warmCream,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'YOUR WORLD. YOUR SOUND.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const Spacer(),
        _headerButton(
          icon: Icons.search_rounded,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.search);
          },
        ),
        const SizedBox(width: 12),
        _headerButton(
          icon: Icons.person_outline_rounded,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.profile);
          },
        ),
      ],
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: AppColors.warmCream,
            size: 21,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // GREETING
  // --------------------------------------------------

  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR PERSONAL SOUNDSPACE',
          style: TextStyle(
            color: AppColors.fieryOrange,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Let the music\nspeak.',
          style: TextStyle(
            color: AppColors.warmCream,
            fontSize: 37,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // FEATURED CARD
  // --------------------------------------------------

  Widget _buildFeaturedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.library);
      },
      child: Container(
        height: 205,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: AppColors.cosmicRedOrangeGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.cosmicRed.withValues(alpha: 0.16),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              top: -30,
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 210,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: 25,
              bottom: 20,
              child: Icon(
                Icons.album_rounded,
                size: 95,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR PERSONAL SOUNDSPACE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Music without\nboundaries.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'EXPLORE YOUR MUSIC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 39,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECTION TITLE
  // --------------------------------------------------

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.warmCream,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // MOOD LIST
  // --------------------------------------------------

  Widget _buildMoodList() {
    return SizedBox(
      height: 49,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _moods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final mood = _moods[index];
          final name = mood['name'] as String;

          return MoodChip(
            label: name,
            icon: mood['icon'] as IconData,
            color: mood['color'] as Color,
            isSelected: _selectedMood == name,
            onTap: () {
              setState(() {
                _selectedMood = name;
              });
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY MUSIC STATE
  // --------------------------------------------------

  Widget _buildEmptyMusicState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.album_rounded,
            color: AppColors.secondaryText,
            size: 35,
          ),
          SizedBox(height: 12),
          Text(
            'Your music journey starts here',
            style: TextStyle(
              color: AppColors.warmCream,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add your favourite tracks to see them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // CURRENT TRACK CARD
  // --------------------------------------------------

  Widget _buildCurrentTrackCard(
    BuildContext context,
    String title,
    String artist,
    String artwork,
    Duration duration,
  ) {
    final imageProvider = artwork.startsWith('http')
        ? NetworkImage(artwork) as ImageProvider
        : AssetImage(artwork) as ImageProvider;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.nowPlaying);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image(
                image: imageProvider,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 55,
                  height: 55,
                  color: AppColors.elevatedSurface,
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
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.warmCream,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    artist,
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
              '${duration.inMinutes.toString().padLeft(2, '0')}:'
              '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BOTTOM NAVIGATION
  // --------------------------------------------------

  Widget _buildBottomNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(
          icon: Icons.home_filled,
          label: 'Home',
          selected: true,
          onTap: () {},
        ),
        _navItem(
          icon: Icons.search_rounded,
          label: 'Search',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.search);
          },
        ),
        _navItem(
          icon: Icons.library_music_rounded,
          label: 'Library',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.library);
          },
        ),
        _navItem(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.profile);
          },
        ),
      ],
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final color = selected
        ? AppColors.cosmicRed
        : AppColors.secondaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

