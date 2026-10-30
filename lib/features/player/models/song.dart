import 'package:flutter/foundation.dart';

@immutable
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artwork,
    required this.audioSource,
    required this.duration,
    this.albumArtist,
    this.genre,
    this.releaseYear,
    this.isFavorite = false,
    this.providerId = 'local',
    this.providerTrackId,
    this.license,
    this.licenseUrl,
    this.attribution,
    this.playbackAllowed = true,
  });

  final String id;
  final String title;
  final String artist;
  final String album;

  /// Asset path or network URL for album artwork.
  final String artwork;

  /// Asset path or network URL for the audio file.
  final String audioSource;

  final Duration duration;
  final String? albumArtist;
  final String? genre;
  final int? releaseYear;
  final bool isFavorite;
  final String providerId;
  final String? providerTrackId;
  final String? license;
  final String? licenseUrl;
  final String? attribution;
  final bool playbackAllowed;

  bool get isNetworkArtwork =>
      artwork.startsWith('https://') || artwork.startsWith('http://');

  bool get isNetworkAudio =>
      audioSource.startsWith('https://') || audioSource.startsWith('http://');

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artwork,
    String? audioSource,
    Duration? duration,
    String? albumArtist,
    String? genre,
    int? releaseYear,
    bool? isFavorite,
    String? providerId,
    String? providerTrackId,
    String? license,
    String? licenseUrl,
    String? attribution,
    bool? playbackAllowed,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artwork: artwork ?? this.artwork,
      audioSource: audioSource ?? this.audioSource,
      duration: duration ?? this.duration,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      isFavorite: isFavorite ?? this.isFavorite,
      providerId: providerId ?? this.providerId,
      providerTrackId: providerTrackId ?? this.providerTrackId,
      license: license ?? this.license,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      attribution: attribution ?? this.attribution,
      playbackAllowed: playbackAllowed ?? this.playbackAllowed,
    );
  }
}
