import 'dart:math';

import 'package:flutter/material.dart';

class MotorDriverMarker extends StatefulWidget {
  const MotorDriverMarker({
    super.key,
    required this.heading,
    this.color = const Color(0xFF3B82F6),
    this.size = 72,
    this.showPulse = true,
  });

  final double heading;
  final Color color;

  final bool showPulse;

  final double size;

  @override
  State<MotorDriverMarker> createState() => _MotorDriverMarkerState();
}

class _MotorDriverMarkerState extends State<MotorDriverMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showPulse)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Container(
                  width: size * (0.35 + 0.65 * t),
                  height: size * (0.35 + 0.65 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.30 * (1 - t)),
                  ),
                );
              },
            ),
          Transform.rotate(
            angle: widget.heading * pi / 180,
            child: CustomPaint(
              size: Size(size * 0.46, size * 0.80),
              painter: MotorPainter(color: widget.color),
            ),
          ),
        ],
      ),
    );
  }
}

class MotorPainter extends CustomPainter {
  const MotorPainter({required this.color});

  final Color color;

  static const _w = 44.0;
  static const _h = 76.0;
  static const _cx = _w / 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _w, size.height / _h);

    final dark = Color.lerp(color, Colors.black, 0.35)!;
    final light = Color.lerp(color, Colors.white, 0.45)!;
    const tireColor = Color(0xFF1E1E1E);
    const metal = Color(0xFF2B2B2B);

    canvas.drawRRect(
      RRect.fromLTRBR(11, 6, 35, 74, const Radius.circular(10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final tire = Paint()..color = tireColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(_cx, 9), width: 7, height: 15),
        const Radius.circular(3.5),
      ),
      tire,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(_cx, 67), width: 8, height: 16),
        const Radius.circular(4),
      ),
      tire,
    );

    canvas.drawRRect(
      RRect.fromLTRBR(15, 14, 29, 62, const Radius.circular(7)),
      Paint()..color = dark,
    );

    canvas.drawRRect(
      RRect.fromLTRBR(14, 10, 30, 24, const Radius.circular(7)),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(_cx, 11.5), width: 8, height: 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFFFFF3B0),
    );

    final bar = Paint()
      ..color = metal
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(8, 22), const Offset(36, 22), bar);
    final mirrorStem = Paint()
      ..color = metal
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(11.5, 21), const Offset(9, 16.5), mirrorStem);
    canvas.drawLine(const Offset(32.5, 21), const Offset(35, 16.5), mirrorStem);
    final mirror = Paint()..color = const Color(0xFF9E9E9E);
    canvas.drawCircle(const Offset(9, 15.5), 2.3, mirror);
    canvas.drawCircle(const Offset(35, 15.5), 2.3, mirror);

    final box = RRect.fromLTRBR(9, 46, 35, 70, const Radius.circular(3.5));
    canvas.drawRRect(box, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromLTRBR(11.5, 48.5, 32.5, 67.5, const Radius.circular(2)),
      Paint()..color = light,
    );
    canvas.drawRect(
      const Rect.fromLTRB(11.5, 56.5, 32.5, 59.5),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawRRect(
      RRect.fromLTRBR(17, 70, 27, 72.5, const Radius.circular(1.2)),
      Paint()..color = const Color(0xFFE53935),
    );

    final arm = Paint()
      ..color = dark
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(14.5, 36), const Offset(10.5, 22.5), arm);
    canvas.drawLine(const Offset(29.5, 36), const Offset(33.5, 22.5), arm);
    final glove = Paint()..color = const Color(0xFF3A3A3A);
    canvas.drawCircle(const Offset(10.5, 22.5), 2.4, glove);
    canvas.drawCircle(const Offset(33.5, 22.5), 2.4, glove);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(_cx, 39), width: 21, height: 13),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(_cx, 39), width: 21, height: 13),
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    const helmetCenter = Offset(_cx, 34);
    canvas.drawCircle(helmetCenter, 7.2, Paint()..color = color);
    canvas.drawCircle(
      helmetCenter,
      7.2,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      const Offset(_cx, 36),
      const Offset(_cx, 41),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: helmetCenter, radius: 5),
      -pi * 0.85,
      pi * 0.7,
      false,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(19.6, 31.2),
      1.6,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(MotorPainter oldDelegate) => oldDelegate.color != color;
}
