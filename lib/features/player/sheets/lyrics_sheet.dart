
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LyricsSheet extends StatelessWidget {
  const LyricsSheet({
    super.key,
    required this.songTitle,
    required this.artist,
    required this.lyrics,
    this.currentLineIndex = 0,
    this.accentColor = AppColors.cosmicRed,
  });

  final String songTitle;
  final String artist;
  final List<String> lyrics;
  final int currentLineIndex;
  final Color accentColor;

  static Future<void> show(
    BuildContext context, {
    required String songTitle,
    required String artist,
    required List<String> lyrics,
    int currentLineIndex = 0,
    Color accentColor = AppColors.cosmicRed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => LyricsSheet(
        songTitle: songTitle,
        artist: artist,
        lyrics: lyrics,
        currentLineIndex: currentLineIndex,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 25,
              sigmaY: 25,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NOW SINGING',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 9,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                songTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.warmCream,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                artist,
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.warmCream,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: AppColors.divider.withValues(alpha: 0.7),
                    height: 1,
                  ),
                  Expanded(
                    child: lyrics.isEmpty
                        ? _buildEmptyLyrics()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(
                              25,
                              35,
                              25,
                              50,
                            ),
                            itemCount: lyrics.length,
                            itemBuilder: (context, index) {
                              final isCurrent =
                                  index == currentLineIndex;

                              return AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 350,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 8,
                                ),
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(
                                    milliseconds: 350,
                                  ),
                                  style: TextStyle(
                                    color: isCurrent
                                        ? accentColor
                                        : AppColors.secondaryText
                                            .withValues(alpha: 0.55),
                                    fontSize: isCurrent ? 23 : 19,
                                    height: 1.45,
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                  child: Text(lyrics[index]),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyLyrics() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 45,
              color: AppColors.secondaryText,
            ),
            SizedBox(height: 16),
            Text(
              'Lyrics are not available',
              style: TextStyle(
                color: AppColors.warmCream,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Lyrics for this track will appear here when available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
