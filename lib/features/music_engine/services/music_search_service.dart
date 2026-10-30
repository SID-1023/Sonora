import 'package:flutter/foundation.dart';

import '../../player/models/song.dart';
import '../models/music_provider_page.dart';
import '../providers/audius_provider.dart';
import '../providers/internet_archive_provider.dart';
import '../providers/jamendo_provider.dart';
import '../providers/music_provider.dart';
import '../utils/music_api_client.dart';

class MusicSearchService {
  factory MusicSearchService.createDefault() {
    final client = MusicApiClient();
    return MusicSearchService(
      providers: [
        AudiusProvider(client: client),
        JamendoProvider(client: client),
        InternetArchiveProvider(client: client),
      ],
      onDispose: client.close,
    );
  }

  MusicSearchService({
    required List<MusicProvider> providers,
    required VoidCallback onDispose,
  }) : _providers = List.unmodifiable(providers),
       _onDispose = onDispose;

  final List<MusicProvider> _providers;
  final VoidCallback _onDispose;

  List<MusicProvider> get enabledProviders =>
      _providers.where((provider) => provider.isEnabled).toList();

  List<MusicProvider> get disabledProviders =>
      _providers.where((provider) => !provider.isEnabled).toList();

  Future<MusicSearchResponse> search(
    String query, {
    Map<String, int> offsets = const {},
    int limit = 20,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const MusicSearchResponse(
        tracks: [],
        nextOffsets: {},
        failures: [],
      );
    }

    final pageSize = limit.clamp(1, 25);
    final tracks = <Song>[];
    final nextOffsets = <String, int>{};
    final failures = <MusicProviderFailure>[];
    final requests = enabledProviders.where(
      (provider) => offsets.containsKey(provider.id) || offsets.isEmpty,
    );

    await Future.wait(
      requests.map((provider) async {
        final offset = offsets[provider.id] ?? 0;
        try {
          final page = await provider.search(
            normalizedQuery,
            offset: offset,
            limit: pageSize,
          );
          tracks.addAll(page.tracks);
          if (page.nextOffset != null) {
            nextOffsets[provider.id] = page.nextOffset!;
          }
        } on MusicProviderException catch (error) {
          failures.add(
            MusicProviderFailure(
              providerId: provider.id,
              providerName: provider.displayName,
              message: error.message,
              retryAfter: error.retryAfter,
            ),
          );
          nextOffsets[provider.id] = offset;
        } catch (error, stackTrace) {
          debugPrint('SONORA: ${provider.displayName} search failed: $error');
          debugPrintStack(stackTrace: stackTrace);
          failures.add(
            MusicProviderFailure(
              providerId: provider.id,
              providerName: provider.displayName,
              message: 'Search failed unexpectedly. Please try again.',
            ),
          );
          nextOffsets[provider.id] = offset;
        }
      }),
    );

    return MusicSearchResponse(
      tracks: deduplicateTracks(tracks),
      nextOffsets: nextOffsets,
      failures: failures,
    );
  }

  List<Song> deduplicateTracks(Iterable<Song> tracks) {
    final seen = <String>{};
    return tracks.where((track) {
      final title = track.title.toLowerCase().trim();
      final artist = track.artist.toLowerCase().trim();
      final key = '$title\u0000$artist';
      return title.isNotEmpty && seen.add(key);
    }).toList();
  }

  void dispose() => _onDispose();
}
