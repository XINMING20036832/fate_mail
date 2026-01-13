\
import 'dart:math';
import 'package:flutter/material.dart';

class FateBackground extends StatelessWidget {
  final Widget child;
  const FateBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _GradientLayer(),
        const _StarsLayer(),
        // subtle vignette
        IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GradientLayer extends StatelessWidget {
  const _GradientLayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0F1A),
            Color(0xFF101A2C),
            Color(0xFF0B0F1A),
          ],
        ),
      ),
    );
  }
}

class _StarsLayer extends StatelessWidget {
  const _StarsLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StarsPainter(seed: 42),
        size: Size.infinite,
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final int seed;
  _StarsPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final paint = Paint()..color = Colors.white.withOpacity(0.35);

    final count = (min(size.width, size.height) / 5).clamp(80, 260).toInt();
    for (int i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.2 + 0.3;
      paint.color = Colors.white.withOpacity(0.10 + rnd.nextDouble() * 0.35);
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // a few brighter stars
    final glowPaint = Paint()..color = Colors.white.withOpacity(0.22);
    for (int i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 2.2, glowPaint);
      canvas.drawCircle(Offset(x, y), 0.9, Paint()..color = Colors.white.withOpacity(0.55));
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}
