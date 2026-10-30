
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_formatter.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../state/player_controller.dart';
import '../widgets/progress_arc.dart';
import '../widgets/waveform_visualizer.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key, this.controller});

  final PlayerController? controller;

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {
  late final PlayerController _controller;
  late final bool _ownsController;

  late final AnimationController _entryController;
  late final AnimationController _ambientController;

  String? _lastSongId;

  static const Color _backgroundColor = Color(0xFF080403);
  static const Color _surfaceColor = Color(0xFF1B100D);

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;

    _controller = widget.controller ??
        PlayerController(
          audioService: AudioPlayerService(),
        );

    _lastSongId = _controller.currentSong?.id;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _entryController.forward();

    _controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate() {
    if (!mounted) return;

    final currentSongId = _controller.currentSong?.id;

    if (currentSongId != _lastSongId) {
      _lastSongId = currentSongId;
      _entryController.forward(from: 0);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);

    _entryController.dispose();
    _ambientController.dispose();

    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  bool _hasArtwork(String artwork) {
    return artwork.trim().isNotEmpty;
  }

  bool _isNetworkArtwork(String artwork) {
    return artwork.startsWith('https://') ||
        artwork.startsWith('http://');
  }

  ImageProvider<Object> _artworkProvider(String artwork) {
    if (_isNetworkArtwork(artwork)) {
      return NetworkImage(artwork);
    }

    return AssetImage(artwork);
  }

  @override
  Widget build(BuildContext context) {
    final song = _controller.currentSong;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: song == null
          ? _buildEmptyState()
          : _buildPlayerScreen(song),
    );
  }

  // ------------------------------------------------------------
  // MAIN PLAYER SCREEN
  // ------------------------------------------------------------

  Widget _buildPlayerScreen(Song song) {
    final accent = _controller.palette.accent;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Album artwork background.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 850),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildArtworkBackground(song),
        ),

        // Cinematic dark overlay.
        _buildCinematicOverlay(),

        // Animated Living Palette atmosphere.
        AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            final intensity =
                0.025 + (_ambientController.value * 0.035);

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: intensity),
                    Colors.transparent,
                    accent.withValues(alpha: intensity * 0.8),
                  ],
                ),
              ),
            );
          },
        ),

        // Main interface.
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;

              final topSpacing = (height * 0.025).clamp(10.0, 22.0);
              final artworkSpacing =
                  (height * 0.19).clamp(65.0, 155.0);
              final sectionSpacing =
                  (height * 0.023).clamp(10.0, 20.0);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopBar(),

                        SizedBox(height: topSpacing),

                        SizedBox(height: artworkSpacing),

                        _buildAnimatedTrackInformation(song),

                        SizedBox(height: sectionSpacing),

                        _buildProgressSection(),

                        SizedBox(height: sectionSpacing),

                        _buildPlaybackControls(),

                        SizedBox(height: sectionSpacing),

                        _buildWaveform(),

                        SizedBox(height: sectionSpacing),

                        _buildBottomActions(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ARTWORK BACKGROUND
  // ------------------------------------------------------------

  Widget _buildArtworkBackground(Song song) {
    final artwork = song.artwork;

    if (!_hasArtwork(artwork)) {
      return _buildArtworkPlaceholder(
        key: ValueKey('placeholder_${song.id}'),
      );
    }

    return Image(
      key: ValueKey('${song.id}_$artwork'),
      image: _artworkProvider(artwork),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _buildArtworkPlaceholder(
          key: ValueKey('error_${song.id}'),
        );
      },
    );
  }

  Widget _buildArtworkPlaceholder({Key? key}) {
    final accent = _controller.palette.accent;

    return Container(
      key: key,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.15,
          colors: [
            accent.withValues(alpha: 0.28),
            const Color(0xFF32120E),
            const Color(0xFF100706),
            _backgroundColor,
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            final scale =
                1.0 + (_ambientController.value * 0.045);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 65,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    color: accent.withValues(alpha: 0.85),
                    size: 95,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCinematicOverlay() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.18, 0.42, 0.68, 1.0],
          colors: [
            Color(0x99000000),
            Color(0x26000000),
            Color(0x42000000),
            Color(0xE6100705),
            Color(0xFF080403),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _buildTopBar() {
    return SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _topIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            tooltip: 'Close player',
            onTap: () => Navigator.maybePop(context),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SONORA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),

          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 27,
            ),
            color: const Color(0xFF24130F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'close') {
                Navigator.maybePop(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'close',
                child: Text(
                  'Close player',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 45,
            height: 45,
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TRACK INFORMATION
  // ------------------------------------------------------------

  Widget _buildAnimatedTrackInformation(Song song) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(
          0.05,
          0.75,
          curve: Curves.easeOut,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: _buildTrackInformation(song),
      ),
    );
  }

  Widget _buildTrackInformation(Song song) {
    return Column(
      children: [
        Text(
          song.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 15,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          song.artist,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (song.album.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            song.album,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],

        if (song.attribution != null &&
            song.attribution!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            song.attribution!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // PROGRESS AND SEEKING
  // ------------------------------------------------------------

  Widget _buildProgressSection() {
    return ProgressArc(
      progress: _controller.progress.clamp(0.0, 1.0),
      position: TimeFormatter.formatDuration(
        _controller.position,
      ),
      duration: TimeFormatter.formatDuration(
        _controller.duration,
      ),
      accentColor: _controller.palette.accent,
      onSeek: (value) {
        final safeProgress = value.clamp(0.0, 1.0);

        final milliseconds =
            (_controller.duration.inMilliseconds * safeProgress)
                .round();

        _controller.seek(
          Duration(milliseconds: milliseconds),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // PLAYBACK CONTROLS
  // ------------------------------------------------------------

  Widget _buildPlaybackControls() {
    final accent = _controller.palette.accent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _smallControl(
          icon: Icons.shuffle_rounded,
          active: _controller.isShuffleEnabled,
          activeColor: accent,
          tooltip: 'Shuffle',
          onTap: _controller.toggleShuffle,
        ),

        _smallControl(
          icon: Icons.skip_previous_rounded,
          size: 38,
          tooltip: 'Previous track',
          onTap: _controller.previous,
        ),

        _buildMainPlayButton(accent),

        _smallControl(
          icon: Icons.skip_next_rounded,
          size: 38,
          tooltip: 'Next track',
          onTap: _controller.next,
        ),

        _smallControl(
          icon: _controller.repeatMode == RepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          active: _controller.repeatMode != RepeatMode.off,
          activeColor: accent,
          tooltip: 'Repeat',
          onTap: _controller.cycleRepeatMode,
        ),
      ],
    );
  }

  Widget _buildMainPlayButton(Color accent) {
    return GestureDetector(
      onTap: _controller.isLoading
          ? null
          : _controller.togglePlayPause,
      child: AnimatedScale(
        scale: _controller.isPlaying ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.18),
            border: Border.all(
              color: accent.withValues(alpha: 0.95),
              width: _controller.isPlaying ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(
                  alpha: _controller.isPlaying ? 0.27 : 0.13,
                ),
                blurRadius: _controller.isPlaying ? 30 : 18,
                spreadRadius: _controller.isPlaying ? 4 : 2,
              ),
            ],
          ),
          child: Center(
            child: _controller.isLoading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 2.2,
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      _controller.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey(_controller.isPlaying),
                      color: Colors.white,
                      size: 51,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _smallControl({
    required IconData icon,
    required VoidCallback onTap,
    double size = 25,
    bool active = false,
    Color activeColor = Colors.white,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 43,
            height: 55,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  icon,
                  key: ValueKey('$icon-$active'),
                  color: active ? activeColor : Colors.white,
                  size: size,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // WAVEFORM VISUALIZER
  // ------------------------------------------------------------

  Widget _buildWaveform() {
    return AnimatedOpacity(
      opacity: _controller.isPlaying ? 1.0 : 0.62,
      duration: const Duration(milliseconds: 350),
      child: WaveformVisualizer(
        progress: _controller.progress,
        accentColor: _controller.palette.accent,
      ),
    );
  }

  // ------------------------------------------------------------
  // LYRICS AND QUEUE ACTIONS
  // ------------------------------------------------------------

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: _bottomAction(
            icon: Icons.lyrics_outlined,
            label: 'Lyrics',
            onTap: _showLyricsUnavailable,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: _bottomAction(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: _showQueueUnavailable,
          ),
        ),
      ],
    );
  }

  Widget _bottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          height: 61,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.09),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 23,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLyricsUnavailable() {
    _showFeatureMessage(
      'Lyrics',
      'Lyrics support will be connected in a later step.',
    );
  }

  void _showQueueUnavailable() {
    _showFeatureMessage(
      'Queue',
      'Queue interface will be connected in a later step.',
    );
  }

  void _showFeatureMessage(String title, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surfaceColor,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ------------------------------------------------------------
  // EMPTY PLAYER STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    final accent = _controller.palette.accent;

    return Container(
      decoration: BoxDecoration(
        gradient: _controller.palette.backgroundGradient,
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: _topIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: 'Go back',
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, child) {
                      final scale =
                          1.0 + (_ambientController.value * 0.06);

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.08),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.12),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.album_rounded,
                            color: accent,
                            size: 65,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Nothing playing yet',
                    style: TextStyle(
                      color: AppColors.warmCream,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Choose a track to enter your soundspace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Go back',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
