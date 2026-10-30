
import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaveformVisualizer extends StatefulWidget {
  final double progress;
  final Color accentColor;

  const WaveformVisualizer({
    super.key,
    required this.progress,
    required this.accentColor,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  static const List<double> _waveform = [
    0.16, 0.25, 0.38, 0.22, 0.48, 0.65, 0.42, 0.28, 0.55, 0.76,
    0.52, 0.34, 0.68, 0.88, 0.58, 0.40, 0.72, 0.95, 0.64, 0.45,
    0.80, 0.58, 0.36, 0.70, 0.90, 0.56, 0.32, 0.62, 0.82, 0.50,
    0.35, 0.68, 0.92, 0.60, 0.42, 0.74, 0.52, 0.30, 0.58, 0.78,
    0.48, 0.26, 0.54, 0.70, 0.40, 0.24, 0.44, 0.62, 0.34, 0.18,
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveformPainter(
              waveform: _waveform,
              progress: widget.progress.clamp(0.0, 1.0),
              animationValue: _animationController.value,
              accentColor: widget.accentColor,
            ),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;
  final double animationValue;
  final Color accentColor;

  const _WaveformPainter({
    required this.waveform,
    required this.progress,
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const barWidth = 3.0;
    const spacing = 3.0;
    final totalBarWidth = barWidth + spacing;

    final availableBars = math.max(
      1,
      math.min(
        waveform.length,
        ((size.width + spacing) / totalBarWidth).floor(),
      ),
    );

    final usedWidth = availableBars * totalBarWidth - spacing;
    final startX = (size.width - usedWidth) / 2;
    final centerY = size.height / 2;

    final playedBars = (availableBars * progress).round();

    for (var i = 0; i < availableBars; i++) {
      final sourceIndex = (i / availableBars * waveform.length).floor();
      final baseHeight = waveform[sourceIndex];

      final phase = (i * 0.22) + (animationValue * math.pi * 2);
      final movement = 0.82 + (math.sin(phase) * 0.18);

      final barHeight = (baseHeight * movement * size.height * 0.88)
          .clamp(3.0, size.height);

      final isPlayed = i <= playedBars;
      final opacity = isPlayed ? 1.0 : 0.28;

      final paint = Paint()
        ..color = accentColor.withValues(alpha: opacity)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      final x = startX + (i * totalBarWidth) + (barWidth / 2);

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.accentColor != accentColor;
  }
}
