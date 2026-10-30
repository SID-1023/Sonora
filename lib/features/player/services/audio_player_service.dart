
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerService {
  AudioPlayerService({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<bool> get playingStream => _player.playingStream;

  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  Duration get position => _player.position;

  Duration? get duration => _player.duration;

  bool get isPlaying => _player.playing;

  Future<void> loadSong(Song song) async {
    if (song.isNetworkAudio) {
      await _player.setUrl(song.audioSource);
    } else {
      await _player.setAsset(song.audioSource);
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekForward({Duration interval = const Duration(seconds: 10)}) async {
    final currentPosition = _player.position;
    final totalDuration = _player.duration;

    final target = currentPosition + interval;

    await _player.seek(
      totalDuration != null && target > totalDuration
          ? totalDuration
          : target,
    );
  }

  Future<void> seekBackward({
    Duration interval = const Duration(seconds: 10),
  }) async {
    final target = _player.position - interval;

    await _player.seek(
      target.isNegative ? Duration.zero : target,
    );
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
