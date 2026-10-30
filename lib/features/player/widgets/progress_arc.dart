
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProgressArc extends StatelessWidget {
  const ProgressArc({
    super.key,
    required this.progress,
    required this.position,
    required this.duration,
    required this.accentColor,
    required this.onSeek,
  });

  final double progress;
  final String position;
  final String duration;
  final Color accentColor;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 94,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                94,
              );

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  _handleSeek(
                    details.localPosition,
                    size,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  _handleSeek(
                    details.localPosition,
                    size,
                  );
                },
                child: CustomPaint(
                  size: size,
                  painter: _ProgressArcPainter(
                    progress: normalizedProgress,
                    accentColor: accentColor,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 2),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              position,
              style: const TextStyle(
                color: AppColors.warmCream,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              duration,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSeek(Offset position, Size size) {
    if (size.width <= 0) return;

    final value = (position.dx / size.width).clamp(0.0, 1.0);

    onSeek(value);
  }
}

class _ProgressArcPainter extends CustomPainter {
  const _ProgressArcPainter({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  // ------------------------------------------------------------
  // ARC GEOMETRY
  // ------------------------------------------------------------

  Offset _pointOnArc(Size size, double t) {
    final start = Offset(
      size.width * 0.08,
      size.height * 0.78,
    );

    final control1 = Offset(
      size.width * 0.30,
      -size.height * 0.10,
    );

    final control2 = Offset(
      size.width * 0.70,
      -size.height * 0.10,
    );

    final end = Offset(
      size.width * 0.92,
      size.height * 0.78,
    );

    final inverse = 1.0 - t;

    // Cubic Bézier interpolation.
    final x =
        math.pow(inverse, 3) * start.dx +
        3 * math.pow(inverse, 2) * t * control1.dx +
        3 * inverse * math.pow(t, 2) * control2.dx +
        math.pow(t, 3) * end.dx;

    final y =
        math.pow(inverse, 3) * start.dy +
        3 * math.pow(inverse, 2) * t * control1.dy +
        3 * inverse * math.pow(t, 2) * control2.dy +
        math.pow(t, 3) * end.dy;

    return Offset(x.toDouble(), y.toDouble());
  }

  Path _createArcPath(Size size, double endProgress) {
    final path = Path();

    path.moveTo(
      size.width * 0.08,
      size.height * 0.78,
    );

    path.cubicTo(
      size.width * 0.30,
      -size.height * 0.10,
      size.width * 0.70,
      -size.height * 0.10,
      size.width * (0.08 + 0.84 * endProgress),
      _pointOnArc(size, endProgress).dy,
    );

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ----------------------------------------------------------
    // TRACK
    // ----------------------------------------------------------

    final trackPath = _createArcPath(size, 1.0);

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(
      trackPath,
      trackPaint,
    );

    // ----------------------------------------------------------
    // PROGRESS
    // ----------------------------------------------------------

    if (progress > 0) {
      final progressPath = _createArcPath(
        size,
        progress,
      );

      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.fieryOrange,
            accentColor,
            const Color(0xFFFFB347),
          ],
          stops: const [
            0.0,
            0.65,
            1.0,
          ],
        ).createShader(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawPath(
        progressPath,
        progressPaint,
      );
    }

    // ----------------------------------------------------------
    // PROGRESS KNOB
    // ----------------------------------------------------------

    final knobPosition = _pointOnArc(
      size,
      progress,
    );

    // Outer glow.
    canvas.drawCircle(
      knobPosition,
      13,
      Paint()
        ..color = accentColor.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          9,
        ),
    );

    // Colored halo.
    canvas.drawCircle(
      knobPosition,
      8,
      Paint()
        ..color = accentColor.withValues(alpha: 0.65),
    );

    // White knob.
    canvas.drawCircle(
      knobPosition,
      5.5,
      Paint()
        ..color = Colors.white,
    );

    // Small highlight.
    canvas.drawCircle(
      knobPosition.translate(-1.5, -1.5),
      1.6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(
    covariant _ProgressArcPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
