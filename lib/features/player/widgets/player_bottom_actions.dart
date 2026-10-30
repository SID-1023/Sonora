
import 'package:flutter/material.dart';

import '../state/player_controller.dart';

class PlayerBottomActions extends StatelessWidget {
  final bool isShuffling;
  final RepeatMode repeatMode;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final VoidCallback onLyrics;
  final VoidCallback onQueue;

  const PlayerBottomActions({
    super.key,
    required this.isShuffling,
    required this.repeatMode,
    required this.onShuffle,
    required this.onRepeat,
    required this.onLyrics,
    required this.onQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BottomActionPill(
            icon: Icons.lyrics_rounded,
            label: 'Lyrics',
            onTap: onLyrics,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BottomActionPill(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: onQueue,
          ),
        ),
      ],
    );
  }
}

class _BottomActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.075),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 19,
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
