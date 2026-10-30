import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sonora/features/music_engine/models/music_provider_page.dart';
import 'package:sonora/features/music_engine/providers/audius_provider.dart';
import 'package:sonora/features/music_engine/providers/internet_archive_provider.dart';
import 'package:sonora/features/music_engine/providers/jamendo_provider.dart';
import 'package:sonora/features/music_engine/providers/music_provider.dart';
import 'package:sonora/features/music_engine/services/music_search_service.dart';
import 'package:sonora/features/music_engine/utils/music_api_client.dart';
import 'package:sonora/features/player/models/song.dart';

void main() {
  group('AudiusProvider', () {
    test(
      'maps playable tracks and uses a refreshable stream endpoint',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/v1/tracks/search');
          expect(request.url.queryParameters['query'], 'ambient');
          expect(request.url.queryParameters['app_name'], 'SONORA');
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'track_id': 42,
                  'title': 'Night Drive',
                  'duration': 181,
                  'genre': 'Electronic',
                  'is_streamable': true,
                  'is_stream_gated': false,
                  'stream': {'url': 'https://provider.example/signed-stream'},
                  'user': {'name': 'Sample Artist'},
                  'artwork': {'480x480': 'https://img.example/cover.jpg'},
                },
                {
                  'track_id': 43,
                  'title': 'Restricted',
                  'is_streamable': false,
                  'stream': {'url': 'https://provider.example/restricted'},
                },
              ],
            }),
            200,
          );
        });
        final api = MusicApiClient(client: client);
        addTearDown(client.close);

        final page = await AudiusProvider(
          client: api,
        ).search('ambient', offset: 0, limit: 2);

        expect(page.tracks, hasLength(1));
        expect(page.tracks.single.id, 'audius:42');
        expect(page.tracks.single.artist, 'Sample Artist');
        expect(
          page.tracks.single.audioSource,
          contains('/v1/tracks/42/stream'),
        );
        expect(page.tracks.single.attribution, contains('Audius'));
        expect(page.nextOffset, 2);
      },
    );
  });

  group('InternetArchiveProvider', () {
    test(
      'returns public audio but disables playback without a clear licence',
      () async {
        final client = MockClient((request) async {
          if (request.url.path == '/advancedsearch.php') {
            return http.Response(
              jsonEncode({
                'response': {
                  'docs': [
                    {
                      'identifier': 'sample-item',
                      'title': 'Sample recording',
                      'creator': 'Sample artist',
                    },
                  ],
                },
              }),
              200,
            );
          }

          expect(request.url.path, '/metadata/sample-item');
          return http.Response(
            jsonEncode({
              'metadata': {
                'identifier': 'sample-item',
                'title': 'Sample recording',
                'creator': 'Sample artist',
                'mediatype': 'audio',
              },
              'files': [
                {
                  'name': 'sample.mp3',
                  'format': 'MP3',
                  'size': '1024',
                  'length': '90',
                },
              ],
            }),
            200,
          );
        });
        final api = MusicApiClient(client: client);
        addTearDown(client.close);

        final page = await InternetArchiveProvider(
          client: api,
        ).search('sample', offset: 0, limit: 10);

        expect(page.tracks, hasLength(1));
        expect(page.tracks.single.duration.inSeconds, 90);
        expect(page.tracks.single.playbackAllowed, isFalse);
        expect(page.tracks.single.license, contains('Rights not stated'));
      },
    );

    test(
      'permits a publicly accessible file with an explicit CC BY licence',
      () async {
        final client = MockClient((request) async {
          if (request.url.path == '/advancedsearch.php') {
            return http.Response(
              jsonEncode({
                'response': {
                  'docs': [
                    {'identifier': 'cc-item', 'title': 'CC track'},
                  ],
                },
              }),
              200,
            );
          }

          return http.Response(
            jsonEncode({
              'metadata': {
                'identifier': 'cc-item',
                'title': 'CC track',
                'licenseurl': 'https://creativecommons.org/licenses/by/4.0/',
              },
              'files': [
                {'name': 'track.ogg', 'size': '512', 'length': '42'},
              ],
            }),
            200,
          );
        });
        final api = MusicApiClient(client: client);
        addTearDown(client.close);

        final page = await InternetArchiveProvider(
          client: api,
        ).search('track', offset: 0, limit: 10);

        expect(page.tracks.single.playbackAllowed, isTrue);
        expect(page.tracks.single.licenseUrl, contains('creativecommons.org'));
      },
    );
  });

  test('Jamendo remains disabled without a registered client ID', () {
    final client = MusicApiClient(
      client: MockClient((_) async {
        fail('A disabled provider must not issue API requests.');
      }),
    );

    final provider = JamendoProvider(client: client);

    expect(provider.isEnabled, isFalse);
    expect(provider.disabledReason, contains('backend proxy'));
    client.close();
  });

  test(
    'search combines providers, deduplicates results and isolates failures',
    () async {
      final firstSong = _song(
        id: 'audius:one',
        providerId: 'audius',
        title: 'Same track',
        artist: 'Same artist',
      );
      final duplicate = _song(
        id: 'jamendo:two',
        providerId: 'jamendo',
        title: 'Same track',
        artist: 'Same artist',
      );
      final service = MusicSearchService(
        providers: [
          _FakeProvider(id: 'audius', page: [firstSong], nextOffset: 1),
          _FakeProvider(id: 'jamendo', page: [duplicate]),
          _FailingProvider(),
        ],
        onDispose: () {},
      );

      final result = await service.search('same');

      expect(result.tracks, hasLength(1));
      expect(result.tracks.single.id, 'audius:one');
      expect(result.nextOffsets['audius'], 1);
      expect(result.failures, hasLength(1));
      expect(result.failures.single.retryAfter, const Duration(seconds: 8));
    },
  );
}

Song _song({
  required String id,
  required String providerId,
  required String title,
  required String artist,
}) {
  return Song(
    id: id,
    providerId: providerId,
    providerTrackId: id,
    title: title,
    artist: artist,
    album: 'Test album',
    artwork: 'https://example.test/cover.jpg',
    audioSource: 'https://example.test/audio.mp3',
    duration: Duration.zero,
  );
}

class _FakeProvider implements MusicProvider {
  _FakeProvider({required this.id, required this.page, this.nextOffset});

  @override
  final String id;

  final List<Song> page;
  final int? nextOffset;

  @override
  String get displayName => id;

  @override
  bool get isEnabled => true;

  @override
  String? get disabledReason => null;

  @override
  Future<MusicProviderPage> search(
    String query, {
    required int offset,
    required int limit,
  }) async {
    return MusicProviderPage(tracks: page, nextOffset: nextOffset);
  }
}

class _FailingProvider extends _FakeProvider {
  _FailingProvider() : super(id: 'failing', page: const []);

  @override
  Future<MusicProviderPage> search(
    String query, {
    required int offset,
    required int limit,
  }) async {
    throw const MusicProviderException(
      'Rate limited',
      statusCode: 429,
      retryAfter: Duration(seconds: 8),
    );
  }
}
