import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// -------------------------------------
/// Noise Painter (static grain texture)
/// -------------------------------------
class BlackGridNoisePainter extends CustomPainter {
  final double opacity;
  final int seed;

  BlackGridNoisePainter({this.opacity = 0.12, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);

    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final int count = (size.width * size.height * 0.25).toInt();
    final points = <Offset>[];

    for (int i = 0; i < count; i++) {
      points.add(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
      );
    }

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// -------------------------------------
/// Grid + Marker Painter
/// -------------------------------------
class BlackGridPainter extends CustomPainter {
  final double gridOpacity;
  final double markerOpacity;
  final double step;

  BlackGridPainter({
    this.gridOpacity = 0.25,
    this.markerOpacity = 0.6,
    this.step = 35,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(gridOpacity)
      ..strokeWidth = 1;

    final markerPaint = Paint()
      ..color = Colors.white.withOpacity(markerOpacity)
      ..strokeWidth = 1.5;

    final random = Random(42);

    // Vertical lines
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Random "+" markers
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        if (random.nextDouble() < 0.10) {
          const length = 10.0;

          canvas.drawLine(
            Offset(x - length, y),
            Offset(x + length, y),
            markerPaint,
          );
          canvas.drawLine(
            Offset(x, y - length),
            Offset(x, y + length),
            markerPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// -------------------------------------
/// Reusable Black Grid Background
/// -------------------------------------
class BlackGrid extends StatelessWidget {
  final Widget? child;
  final bool showNoise;
  final bool showGrid;
  final bool bottomFade;

  const BlackGrid({
    super.key,
    this.child,
    this.showNoise = true,
    this.showGrid = true,
    this.bottomFade = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base black gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2C2C2C), Color(0xFF000000)],
              stops: [0.0, 0.8],
            ),
          ),
        ),

        if (showNoise)
          CustomPaint(painter: BlackGridNoisePainter(), size: Size.infinite),

        if (showGrid)
          CustomPaint(painter: BlackGridPainter(), size: Size.infinite),

        if (bottomFade)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
          ),

        if (child != null) child!,
      ],
    );
  }
}
