
import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../core/theme/app_theme.dart';
import '../features/music_engine/services/music_search_service.dart';
import '../features/player/data/local_song_catalogue.dart';
import '../features/player/services/audio_player_service.dart';
import '../features/player/state/player_controller.dart';
import '../features/player/state/player_scope.dart';

class SonoraApp extends StatefulWidget {
  const SonoraApp({super.key});

  @override
  State<SonoraApp> createState() => _SonoraAppState();
}

class _SonoraAppState extends State<SonoraApp> {
  late final AudioPlayerService _audioService;
  late final PlayerController _playerController;
  late final MusicSearchService _musicSearchService;

  @override
  void initState() {
    super.initState();

    // Create one shared audio service.
    _audioService = AudioPlayerService();

    // Load the local song catalogue into the existing player queue.
    _playerController = PlayerController(
      audioService: _audioService,
      initialQueue: LocalSongCatalogue.songs,
    );

    _musicSearchService = MusicSearchService.createDefault();
  }

  @override
  void dispose() {
    _playerController.dispose();
    _musicSearchService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerScope(
      controller: _playerController,
      child: MaterialApp(
        title: 'SONORA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes(
          musicSearchService: _musicSearchService,
        ),
      ),
    );
  }
}
