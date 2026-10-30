
import 'package:flutter/material.dart';

class PlayerTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMore;

  const PlayerTopBar({
    super.key,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          _TopBarButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: onBack,
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SONORA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'YOUR SOUNDSPACE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          _TopBarButton(
            icon: Icons.more_vert_rounded,
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.075),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 23,
          ),
        ),
      ),
    );
  }
}
