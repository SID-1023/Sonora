import '../../player/models/song.dart';

class MusicProviderPage {
  const MusicProviderPage({required this.tracks, required this.nextOffset});

  final List<Song> tracks;
  final int? nextOffset;
}

class MusicProviderFailure {
  const MusicProviderFailure({
    required this.providerId,
    required this.providerName,
    required this.message,
    this.retryAfter,
  });

  final String providerId;
  final String providerName;
  final String message;
  final Duration? retryAfter;
}

class MusicSearchResponse {
  const MusicSearchResponse({
    required this.tracks,
    required this.nextOffsets,
    required this.failures,
  });

  final List<Song> tracks;
  final Map<String, int> nextOffsets;
  final List<MusicProviderFailure> failures;

  bool get hasMore => nextOffsets.isNotEmpty;
}
