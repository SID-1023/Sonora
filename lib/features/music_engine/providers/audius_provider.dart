import '../../player/models/song.dart';
import '../models/music_provider_page.dart';
import '../utils/music_api_client.dart';
import 'music_provider.dart';

class AudiusProvider implements MusicProvider {
  AudiusProvider({required MusicApiClient client}) : _client = client;

  final MusicApiClient _client;

  static const String _appName = 'SONORA';
  @override
  String get id => 'audius';

  @override
  String get displayName => 'Audius';

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
    final response = await _client.getJson(
      Uri.https('api.audius.co', '/v1/tracks/search', {
        'query': query,
        'app_name': _appName,
        'offset': '$offset',
        'limit': '${limit.clamp(1, 25)}',
      }),
    );

    final data = response['data'];
    if (data is! List) {
      throw const MusicProviderException('Audius returned no track results.');
    }

    final tracks = <Song>[];
    for (final item in data) {
      if (item is! Map) continue;

      final track = _trackFromJson(Map<String, dynamic>.from(item));
      if (track != null) tracks.add(track);
    }

    return MusicProviderPage(
      tracks: tracks,
      nextOffset: data.length >= limit ? offset + data.length : null,
    );
  }

  Song? _trackFromJson(Map<String, dynamic> json) {
    if (json['is_streamable'] != true ||
        json['is_stream_gated'] == true ||
        json['is_available'] == false ||
        json['is_delete'] == true ||
        json['is_unlisted'] == true) {
      return null;
    }

    final rawId = json['track_id'] ?? json['id'];
    final trackId = rawId?.toString();
    final title = _string(json['title']);
    final stream = json['stream'];
    final streamUrl = stream is Map ? _string(stream['url']) : null;
    if (trackId == null ||
        title == null ||
        streamUrl == null ||
        !_isHttpsUrl(streamUrl)) {
      return null;
    }

    final user = json['user'];
    final artist = user is Map
        ? _string(user['name']) ?? _string(user['handle'])
        : null;
    final album = json['album_backlink'];
    final albumName = album is Map ? _string(album['playlist_name']) : null;
    final artwork = json['artwork'];
    final artworkUrl = artwork is Map
        ? _string(artwork['480x480']) ?? _string(artwork['150x150'])
        : null;
    final seconds = _number(json['duration']);
    final license = _string(json['license']);
    final playbackUrl = Uri.https(
      'api.audius.co',
      '/v1/tracks/$trackId/stream',
      {'app_name': _appName},
    );

    return Song(
      id: 'audius:$trackId',
      providerId: id,
      providerTrackId: trackId,
      title: title,
      artist: artist ?? 'Unknown artist',
      album: albumName ?? 'Audius',
      artwork: artworkUrl ?? '',
      audioSource: playbackUrl.toString(),
      duration: Duration(seconds: seconds?.round() ?? 0),
      genre: _string(json['genre']),
      license: license ?? 'Not specified by the provider',
      attribution: 'Track by ${artist ?? 'unknown artist'} on Audius',
    );
  }

  String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  num? _number(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
