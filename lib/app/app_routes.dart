import 'package:flutter/material.dart';

import '../features/home/screens/home_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/player/screens/now_playing_screen.dart';
import '../features/player/state/player_scope.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/music_engine/services/music_search_service.dart';
import '../features/search/screens/search_screen.dart';

abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String search = '/search';
  static const String library = '/library';
  static const String profile = '/profile';
  static const String nowPlaying = '/now-playing';

  static Map<String, WidgetBuilder> routes({
    required MusicSearchService musicSearchService,
  }) => {
    home: (_) => const HomeScreen(),
    search: (_) => SearchScreen(searchService: musicSearchService),
    library: (_) => const LibraryScreen(),
    profile: (_) => const ProfileScreen(),
    nowPlaying: (context) =>
        NowPlayingScreen(controller: PlayerScope.of(context)),
  };
}
