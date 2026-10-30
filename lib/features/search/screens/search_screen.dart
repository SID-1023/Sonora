import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../music_engine/models/music_provider_page.dart';
import '../../music_engine/providers/music_provider.dart';
import '../../music_engine/services/music_search_service.dart';
import '../../player/models/song.dart';
import '../../player/state/player_scope.dart';
import '../../player/screens/now_playing_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.searchService});

  final MusicSearchService searchService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  List<Song> _tracks = [];
  List<MusicProviderFailure> _failures = [];
  Map<String, int> _nextOffsets = {};
  int _requestId = 0;
  bool _didSearch = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final requestId = ++_requestId;
    final query = value.trim();

    setState(() {
      _tracks = [];
      _failures = [];
      _nextOffsets = {};
      _didSearch = query.isNotEmpty;
      _isLoading = query.isNotEmpty;
      _isLoadingMore = false;
    });

    if (query.isEmpty) return;

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(query, requestId: requestId),
    );
  }

  Future<void> _search(
    String query, {
    required int requestId,
    Map<String, int> offsets = const {},
    bool loadMore = false,
  }) async {
    final response = await widget.searchService.search(query, offsets: offsets);
    if (!mounted ||
        requestId != _requestId ||
        query != _searchController.text.trim()) {
      return;
    }

    setState(() {
      _tracks = widget.searchService.deduplicateTracks(
        loadMore ? [..._tracks, ...response.tracks] : response.tracks,
      );
      _nextOffsets = response.nextOffsets;
      _failures = response.failures;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _isLoadingMore || _nextOffsets.isEmpty) return;

    final requestId = ++_requestId;
    setState(() => _isLoadingMore = true);
    await _search(
      query,
      requestId: requestId,
      offsets: _nextOffsets,
      loadMore: true,
    );
  }

  Future<void> _playTrack(Song song) async {
    if (!song.playbackAllowed) return;

    final player = PlayerScope.of(context);
    await player.loadSong(song);
    if (!mounted) return;

    final error = player.playbackError;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NowPlayingScreen(controller: player),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabledProviders = widget.searchService.disabledProviders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(
            color: AppColors.warmCream,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: AppColors.warmCream),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, and albums',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (disabledProviders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _buildDisabledProviderNotice(disabledProviders),
              ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledProviderNotice(List<MusicProvider> providers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Some sources need setup',
            style: TextStyle(
              color: AppColors.warmCream,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final provider in providers)
            Text(
              '${provider.displayName}: ${provider.disabledReason}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading && _tracks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cosmicRed),
      );
    }

    if (!_didSearch) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Search across supported music sources.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
      );
    }

    if (_tracks.isEmpty && _failures.isEmpty) {
      return const Center(
        child: Text(
          'No playable tracks found.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        if (_tracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
              '${_tracks.length} ${_tracks.length == 1 ? 'track' : 'tracks'}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (final song in _tracks) _buildTrackTile(song),
        for (final failure in _failures) _buildFailure(failure),
        if (_nextOffsets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton(
              onPressed: _isLoadingMore ? null : _loadMore,
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more'),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackTile(Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: song.playbackAllowed ? () => _playTrack(song) : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: song.artwork.isEmpty
                          ? _artworkPlaceholder()
                          : Image.network(
                              song.artwork,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _artworkPlaceholder(),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: song.playbackAllowed
                                  ? AppColors.warmCream
                                  : AppColors.secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${song.artist} · ${_providerName(song.providerId)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            song.playbackAllowed
                                ? song.license ?? 'Licence details unavailable'
                                : 'Rights not verified · playback disabled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: song.playbackAllowed
                                  ? AppColors.secondaryText
                                  : AppColors.fieryOrange,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Track source and attribution',
            onPressed: () => _showTrackDetails(song),
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.secondaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      width: 54,
      height: 54,
      color: AppColors.elevatedSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.secondaryText,
      ),
    );
  }

  Widget _buildFailure(MusicProviderFailure failure) {
    final retryDelay = failure.retryAfter;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${failure.providerName}: ${failure.message}'
        '${retryDelay == null ? '' : ' Retry in ${retryDelay.inSeconds} seconds.'}',
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }

  Future<void> _showTrackDetails(Song song) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.elevatedSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: const TextStyle(
                  color: AppColors.warmCream,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _detailLine('Source', _providerName(song.providerId)),
              _detailLine('Licence / rights', song.license ?? 'Not provided'),
              _detailLine(
                'Attribution',
                song.attribution ?? 'No attribution details provided',
              ),
              if (song.licenseUrl != null)
                _detailLine('Licence URL', song.licenseUrl!),
              if (!song.playbackAllowed)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Playback is disabled because the item’s rights could not '
                    'be verified.',
                    style: TextStyle(
                      color: AppColors.fieryOrange,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  String _providerName(String providerId) => switch (providerId) {
    'audius' => 'Audius',
    'jamendo' => 'Jamendo',
    'internet_archive' => 'Internet Archive',
    _ => providerId,
  };
}
