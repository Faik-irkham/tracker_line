import 'package:flutter/material.dart';

import 'person_marker.dart';

class StoreMarker extends StatelessWidget {
  const StoreMarker({super.key, this.color = const Color(0xFF0284C7)});

  static const double width = 48;
  static const double height = 96;
  static const double _pinWidth = 36;
  static const double _pinHeight = height / 2;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
              size: const Size(_pinWidth, _pinHeight),
              painter: _StorePinPainter(color: color),
              child: const SizedBox(
                width: _pinWidth,
                height: _pinHeight,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox.square(
                    dimension: _pinWidth,
                    child: Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorePinPainter extends CustomPainter {
  const _StorePinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pin = teardropPath(size);
    canvas.drawShadow(pin, Colors.black, 3, false);
    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawPath(pin, pinOutline);
  }

  @override
  bool shouldRepaint(_StorePinPainter oldDelegate) =>
      oldDelegate.color != color;
}
