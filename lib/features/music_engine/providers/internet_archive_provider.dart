import 'package:flutter/foundation.dart';

import '../../player/models/song.dart';
import '../models/music_provider_page.dart';
import '../utils/music_api_client.dart';
import 'music_provider.dart';

class InternetArchiveProvider implements MusicProvider {
  InternetArchiveProvider({required MusicApiClient client}) : _client = client;

  final MusicApiClient _client;
  static const Set<String> _audioExtensions = {
    'aac',
    'flac',
    'm4a',
    'mp3',
    'oga',
    'ogg',
    'opus',
    'wav',
  };

  @override
  String get id => 'internet_archive';

  @override
  String get displayName => 'Internet Archive';

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
    final pageSize = limit.clamp(1, 10);
    final escapedQuery = query.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    final response = await _client.getJson(
      Uri.https('archive.org', '/advancedsearch.php', {
        'q': 'mediatype:audio AND "$escapedQuery"',
        'fl[]': 'identifier,title,creator,year,mediatype',
        'rows': '$pageSize',
        'page': '${(offset ~/ pageSize) + 1}',
        'output': 'json',
      }),
    );

    final search = response['response'];
    final docs = search is Map ? search['docs'] : null;
    if (docs is! List) {
      throw const MusicProviderException(
        'Internet Archive returned no audio results.',
      );
    }

    final tracks = <Song>[];
    final searchResults = docs
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    for (var start = 0; start < searchResults.length; start += 5) {
      final batch = searchResults.skip(start).take(5);
      final batchTracks = await Future.wait(
        batch.map((doc) async {
          final identifier = _string(doc['identifier']);
          if (identifier == null) return null;

          try {
            return await _loadItem(identifier, doc);
          } on MusicProviderException catch (error) {
            debugPrint(
              'SONORA: Skipping Internet Archive item $identifier: $error',
            );
            return null;
          }
        }),
      );
      tracks.addAll(batchTracks.whereType<Song>());
    }

    return MusicProviderPage(
      tracks: tracks,
      nextOffset: docs.length >= pageSize ? offset + docs.length : null,
    );
  }

  Future<Song?> _loadItem(
    String identifier,
    Map<String, dynamic> searchResult,
  ) async {
    final metadata = await _client.getJson(
      Uri.https('archive.org', '/metadata/$identifier'),
    );
    final itemMetadata = metadata['metadata'];
    final files = metadata['files'];
    if (itemMetadata is! Map ||
        files is! List ||
        _isTrue(metadata['is_dark']) ||
        _isTrue(metadata['nodownload']) ||
        _isTrue(itemMetadata['is_dark']) ||
        _isTrue(itemMetadata['nodownload']) ||
        _isTrue(itemMetadata['access-restricted-item'])) {
      return null;
    }

    final licenseUrl = _string(itemMetadata['licenseurl']);
    final rights = _string(itemMetadata['rights']);
    final license = licenseUrl ?? rights;
    final playbackAllowed = _allowsPlayback(licenseUrl, rights);
    final file = files.whereType<Map>().firstWhere(
      _isAccessibleAudioFile,
      orElse: () => const <String, Object>{},
    );
    final fileName = _string(file['name']);
    if (fileName == null) return null;

    final creator =
        _string(searchResult['creator']) ??
        _string(itemMetadata['creator']) ??
        'Unknown contributor';
    final title =
        _string(searchResult['title']) ??
        _string(itemMetadata['title']) ??
        fileName;
    final length = file['length'];
    final seconds = length is num ? length : num.tryParse('$length');
    final artworkUrl = Uri.https('archive.org', '/services/img/$identifier');
    final audioUrl = Uri.https(
      'archive.org',
      '/download/$identifier/$fileName',
    );

    return Song(
      id: 'internet_archive:$identifier',
      providerId: id,
      providerTrackId: identifier,
      title: title,
      artist: creator,
      album:
          _string(
            itemMetadata['collection'] is List
                ? (itemMetadata['collection'] as List).join(', ')
                : itemMetadata['collection'],
          ) ??
          'Internet Archive',
      artwork: artworkUrl.toString(),
      audioSource: audioUrl.toString(),
      duration: Duration(seconds: seconds?.round() ?? 0),
      genre: _string(
        itemMetadata['subject'] is List
            ? (itemMetadata['subject'] as List).join(', ')
            : itemMetadata['subject'],
      ),
      license: license ?? 'Rights not stated; playback disabled',
      licenseUrl: licenseUrl,
      attribution: '$title by $creator (Internet Archive item $identifier)',
      playbackAllowed: playbackAllowed,
    );
  }

  bool _isAccessibleAudioFile(Map file) {
    if (_isTrue(file['private'])) return false;
    final name = _string(file['name']);
    if (name == null) return false;

    final extension = name.split('.').last.toLowerCase();
    if (!_audioExtensions.contains(extension)) return false;

    final size = file['size'];
    return size == null || (num.tryParse('$size') ?? 0) > 0;
  }

  bool _allowsPlayback(String? licenseUrl, String? rights) {
    final license = (licenseUrl ?? rights ?? '').toLowerCase();
    if (license.contains('publicdomain/zero') ||
        license.contains('publicdomain/mark') ||
        license.contains('creativecommons.org/licenses/by/') ||
        license.contains('creativecommons.org/licenses/by-sa/') ||
        license.contains('creativecommons.org/licenses/by-nd/')) {
      return !license.contains('/nc/');
    }

    return false;
  }

  bool _isTrue(Object? value) =>
      value == true || value?.toString().toLowerCase() == 'true';

  String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}
