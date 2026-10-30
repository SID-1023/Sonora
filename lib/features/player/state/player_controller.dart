import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/living_palette.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';

enum RepeatMode { off, all, one }

class PlayerController extends ChangeNotifier {
  PlayerController({
    required AudioPlayerService audioService,
    List<Song> initialQueue = const [],
  }) : _audioService = audioService,
       _queue = List<Song>.from(initialQueue) {
    _listenToPlayer();
  }

  final AudioPlayerService _audioService;

  final List<Song> _queue;

  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isShuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  String? _playbackError;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  LivingPaletteData _palette = LivingPaletteData.fallback;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Song? get currentSong => _queue.isEmpty ? null : _queue[_currentIndex];

  List<Song> get queue => List.unmodifiable(_queue);

  int get currentIndex => _currentIndex;

  bool get isPlaying => _audioService.isPlaying;

  bool get isLoading => _isLoading;

  String? get playbackError => _playbackError;

  bool get isShuffleEnabled => _isShuffleEnabled;

  RepeatMode get repeatMode => _repeatMode;

  Duration get position => _position;

  Duration get duration => _duration;

  LivingPaletteData get palette => _palette;

  double get progress {
    if (_duration.inMilliseconds <= 0) return 0;

    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  void _listenToPlayer() {
    _subscriptions.add(
      _audioService.positionStream.listen((value) {
        _position = value;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _audioService.durationStream.listen((value) {
        _duration = value ?? Duration.zero;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _audioService.playerStateStream.listen((state) {
        notifyListeners();

        if (state.processingState == ProcessingState.completed) {
          _handleTrackCompleted();
        }
      }),
    );
  }

  Future<void> loadSong(Song song, {bool autoPlay = true}) async {
    if (!song.playbackAllowed) {
      _playbackError = 'This track is not cleared for playback.';
      notifyListeners();
      return;
    }

    _playbackError = null;
    final existingIndex = _queue.indexWhere((item) => item.id == song.id);

    if (existingIndex >= 0) {
      _currentIndex = existingIndex;
    } else {
      _queue.add(song);
      _currentIndex = _queue.length - 1;
    }

    await _loadCurrentSong(autoPlay: autoPlay);
  }

  Future<void> _loadCurrentSong({bool autoPlay = true}) async {
    final song = currentSong;
    if (song == null) return;
    if (!song.playbackAllowed) {
      _playbackError = 'This track is not cleared for playback.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _position = Duration.zero;
    _duration = song.duration;
    _palette = LivingPaletteData.fallback;
    notifyListeners();

    try {
      await _extractArtworkPalette(song);

      await _audioService.loadSong(song);

      if (autoPlay) {
        await _audioService.play();
      }
    } catch (error, stackTrace) {
      debugPrint('SONORA: Unable to load song: $error');
      debugPrintStack(stackTrace: stackTrace);
      _playbackError =
          'Unable to play this track. Check your connection or try another source.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _extractArtworkPalette(Song song) async {
    try {
      final ImageProvider<Object> artwork = song.isNetworkArtwork
          ? NetworkImage(song.artwork)
          : AssetImage(song.artwork);

      _palette = await LivingPalette.extract(
        artwork: artwork,
        cacheKey: song.id,
      );
    } catch (error, stackTrace) {
      debugPrint('SONORA: Unable to extract artwork palette: $error');
      debugPrintStack(stackTrace: stackTrace);
      _palette = LivingPaletteData.fallback;
    }

    notifyListeners();
  }

  Future<void> play() async {
    await _audioService.play();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  Future<void> seek(Duration value) async {
    await _audioService.seek(value);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    if (_repeatMode == RepeatMode.one) {
      await _audioService.seek(Duration.zero);
      await _audioService.play();
      return;
    }

    if (_isShuffleEnabled && _queue.length > 1) {
      final availableIndices = List<int>.generate(
        _queue.length,
        (index) => index,
      )..remove(_currentIndex);

      availableIndices.shuffle();
      _currentIndex = availableIndices.first;
    } else if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
    } else {
      await _audioService.pause();
      return;
    }

    await _loadCurrentSong();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_position.inSeconds > 3) {
      await _audioService.seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _queue.length - 1;
    } else {
      await _audioService.seek(Duration.zero);
      return;
    }

    await _loadCurrentSong();
  }

  Future<void> addToQueue(Song song) async {
    if (!song.playbackAllowed) {
      _playbackError = 'This track is not cleared for playback.';
      notifyListeners();
      return;
    }

    _queue.add(song);
    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _queue.removeAt(index);

    if (_queue.isEmpty) {
      _currentIndex = 0;
      await _audioService.stop();
    } else if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
      await _loadCurrentSong();
    }

    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length) {
      return;
    }

    if (newIndex > oldIndex) {
      newIndex--;
    }

    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void cycleRepeatMode() {
    _repeatMode =
        RepeatMode.values[(_repeatMode.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }

  Future<void> _handleTrackCompleted() async {
    if (_repeatMode == RepeatMode.one) {
      await _audioService.seek(Duration.zero);
      await _audioService.play();
    } else {
      await next();
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }

    _audioService.dispose();
    super.dispose();
  }
}
