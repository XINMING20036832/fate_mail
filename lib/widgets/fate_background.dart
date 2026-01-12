import 'package:flutter/material.dart';

/// A subtle "fate" background: industrial clean + a little destiny aura.
class FateBackground extends StatelessWidget {
  final Widget child;
  const FateBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF0B0F19) : Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0B0F19), Color(0xFF0F1C3B)]
              : const [Color(0xFFF7F9FF), Color(0xFFEFF2FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: _Glow(isDark: isDark),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _Glow(isDark: isDark, scale: 1.2),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final bool isDark;
  final double scale;
  const _Glow({required this.isDark, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isDark
                ? const [Color(0x335B6CFF), Color(0x000B0F19)]
                : const [Color(0x335B6CFF), Color(0x00FFFFFF)],
          ),
        ),
      ),
    );
  }
}
