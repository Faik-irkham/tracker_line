import 'dart:math';

import 'package:flutter/material.dart';

class RainOverlay extends StatefulWidget {
  const RainOverlay({super.key, this.dropCount = 140});

  final int dropCount;

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay>
    with SingleTickerProviderStateMixin {
  static const _loopSeconds = 60;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _loopSeconds),
  )..repeat();

  late final List<_Drop> _drops = _Drop.generate(widget.dropCount);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _RainPainter(
              drops: _drops,
              seconds: _controller.value * _loopSeconds,
            ),
          ),
        ),
      ),
    );
  }
}

class _Drop {
  const _Drop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.opacity,
  });

  final double x;
  final double y;

  final double speed;
  final double length;
  final double opacity;

  static List<_Drop> generate(int count) {
    final random = Random(3);
    return [
      for (var i = 0; i < count; i++)
        _Drop(
          x: random.nextDouble() * 1.2,
          y: random.nextDouble(),
          speed: 0.9 + random.nextDouble() * 0.6,
          length: 12 + random.nextDouble() * 14,
          opacity: 0.18 + random.nextDouble() * 0.3,
        ),
    ];
  }
}

class _RainPainter extends CustomPainter {
  const _RainPainter({required this.drops, required this.seconds});

  final List<_Drop> drops;
  final double seconds;

  static const _slant = 0.22;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      final fall = (drop.y + seconds * drop.speed) % 1.1 - 0.05;
      final y = fall * size.height;
      final x = drop.x * size.width - fall * size.height * _slant;
      paint.color = const Color(0xFFDBEAFE).withValues(alpha: drop.opacity);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - drop.length * _slant, y - drop.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) =>
      oldDelegate.seconds != seconds;
}
