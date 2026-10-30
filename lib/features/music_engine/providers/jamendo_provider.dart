import '../../player/models/song.dart';
import '../models/music_provider_page.dart';
import '../utils/music_api_client.dart';
import 'music_provider.dart';

class JamendoProvider implements MusicProvider {
  JamendoProvider({required MusicApiClient client, String? clientId})
    : _client = client,
      _clientId = clientId?.trim();

  final MusicApiClient _client;
  final String? _clientId;

  @override
  String get id => 'jamendo';

  @override
  String get displayName => 'Jamendo';

  @override
  bool get isEnabled => _clientId?.isNotEmpty == true;

  @override
  String? get disabledReason => isEnabled
      ? null
      : 'Jamendo requires a registered client ID. Configure it through a '
            'backend proxy; do not embed a private ID in the app.';

  @override
  Future<MusicProviderPage> search(
    String query, {
    required int offset,
    required int limit,
  }) async {
    final clientId = _clientId;
    if (clientId == null || clientId.isEmpty) {
      throw const MusicProviderException(
        'Jamendo is not configured with a registered client ID.',
      );
    }

    final response = await _client.getJson(
      Uri.https('api.jamendo.com', '/v3.0/tracks/', {
        'client_id': clientId,
        'format': 'json',
        'search': query,
        'limit': '${limit.clamp(1, 25)}',
        'offset': '$offset',
        'include': 'licenses',
        'audioformat': 'mp31',
        'imagesize': '300',
      }),
    );

    final headers = response['headers'];
    if (headers is Map && headers['status'] == 'failed') {
      final message = headers['error_message'] is String
          ? headers['error_message'] as String
          : 'Jamendo rejected the request.';
      throw MusicProviderException(message);
    }

    final results = response['results'];
    if (results is! List) {
      throw const MusicProviderException('Jamendo returned no track results.');
    }

    final tracks = <Song>[];
    for (final item in results) {
      if (item is! Map) continue;
      final track = _trackFromJson(Map<String, dynamic>.from(item));
      if (track != null) tracks.add(track);
    }

    return MusicProviderPage(
      tracks: tracks,
      nextOffset: results.length >= limit ? offset + results.length : null,
    );
  }

  Song? _trackFromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final trackId = rawId?.toString();
    final title = _string(json['name']);
    final artist = _string(json['artist_name']);
    final audioUrl = _string(json['audio']);
    if (trackId == null ||
        title == null ||
        audioUrl == null ||
        !_isHttpsUrl(audioUrl)) {
      return null;
    }

    final rawDuration = json['duration'];
    final seconds = rawDuration is num
        ? rawDuration
        : num.tryParse(rawDuration?.toString() ?? '');
    final licenses = json['licenses'];
    final license =
        _string(json['license_ccurl']) ??
        (licenses is List && licenses.isNotEmpty
            ? licenses.first.toString()
            : null);
    final licenseUrl = _string(json['license_ccurl']);
    final image = _string(json['image']);
    final artistName = artist ?? 'Unknown artist';

    return Song(
      id: 'jamendo:$trackId',
      providerId: id,
      providerTrackId: trackId,
      title: title,
      artist: artistName,
      album: _string(json['album_name']) ?? 'Single',
      artwork: image ?? '',
      audioSource: audioUrl,
      duration: Duration(seconds: seconds?.round() ?? 0),
      genre: _string(
        json['musicinfo'] is Map
            ? (json['musicinfo'] as Map)['tags']?.toString()
            : null,
      ),
      license: license ?? 'Not specified by the provider',
      licenseUrl: licenseUrl,
      attribution: '“$title” by $artistName via Jamendo',
      playbackAllowed: license != null,
    );
  }

  String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
