import 'dart:math';
import 'package:flutter/material.dart';

class NebulaBackground extends StatelessWidget {
  final Widget child;
  final bool padding;
  const NebulaBackground({super.key, required this.child, this.padding = false});

  @override
  Widget build(BuildContext context) {
    final content = padding
        ? SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: child))
        : child;

    return Stack(
      children: [
        const _NebulaPaint(),
        // subtle vignette
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  radius: 1.2,
                  center: Alignment.center,
                ),
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _NebulaPaint extends StatelessWidget {
  const _NebulaPaint();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _NebulaPainter(),
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final Random _r = Random(20260201);

  @override
  void paint(Canvas canvas, Size size) {
    // base gradient
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B0F1A),
          Color(0xFF0A1426),
          Color(0xFF100B1F),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // nebula blobs
    for (int i = 0; i < 6; i++) {
      final cx = _r.nextDouble() * size.width;
      final cy = _r.nextDouble() * size.height;
      final radius = (min(size.width, size.height) * (0.35 + _r.nextDouble() * 0.35));
      final blob = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(const Color(0xFF6EE7FF), const Color(0xFF7C3AED), _r.nextDouble())!.withOpacity(0.16),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, blob);
    }

    // stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.85);
    final tinyPaint = Paint()..color = Colors.white.withOpacity(0.35);

    final count = (size.width * size.height / 3500).clamp(160, 420).toInt();
    for (int i = 0; i < count; i++) {
      final x = _r.nextDouble() * size.width;
      final y = _r.nextDouble() * size.height;
      final big = _r.nextDouble() < 0.12;
      final r = big ? 1.1 + _r.nextDouble() * 1.6 : 0.6 + _r.nextDouble() * 0.9;
      canvas.drawCircle(Offset(x, y), r, big ? starPaint : tinyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
