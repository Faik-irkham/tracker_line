import 'dart:math';

import 'package:flutter/material.dart';

class PersonMarker extends StatefulWidget {
  const PersonMarker({super.key, this.color = const Color(0xFF172554)});

  static const double width = 64;
  static const double height = 104;
  static const double _pinWidth = 40;
  static const double _pinHeight = height / 2;

  final Color color;

  @override
  State<PersonMarker> createState() => _PersonMarkerState();
}

class _PersonMarkerState extends State<PersonMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PersonMarker.width,
      height: PersonMarker.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              return Container(
                width: PersonMarker.width * t,
                height: PersonMarker.width * 0.45 * t,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PersonMarker.width),
                  color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(PersonMarker._pinWidth, PersonMarker._pinHeight),
              painter: PersonPinPainter(color: widget.color),
            ),
          ),
        ],
      ),
    );
  }
}

final pinOutline = Paint()
  ..color = Colors.white
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2;

Path teardropPath(Size size) {
  final r = size.width / 2;
  final center = Offset(r, r);
  final a = acos(r / (size.height - r));
  return Path()
    ..moveTo(r, size.height)
    ..lineTo(center.dx + r * sin(a), center.dy + r * cos(a))
    ..arcTo(
      Rect.fromCircle(center: center, radius: r),
      pi / 2 - a,
      -(2 * pi - 2 * a),
      false,
    )
    ..close();
}

class PersonPinPainter extends CustomPainter {
  const PersonPinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final pin = teardropPath(size);

    canvas.drawShadow(pin, Colors.black, 3, false);
    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawPath(pin, pinOutline);

    final innerRadius = r * 0.74;
    canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
    );
    final person = Paint()..color = color;
    canvas.drawCircle(center.translate(0, -r * 0.2), r * 0.22, person);
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, r * 0.55),
        width: r * 0.95,
        height: r * 0.8,
      ),
      pi,
      pi,
      true,
      person,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PersonPinPainter oldDelegate) =>
      oldDelegate.color != color;
}
