import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RadarLayer extends StatefulWidget {
  const RadarLayer({
    super.key,
    required this.center,
    required this.radiusMeters,
    required this.color,
  });

  final LatLng center;
  final double radiusMeters;
  final Color color;

  @override
  State<RadarLayer> createState() => _RadarLayerState();
}

class _RadarLayerState extends State<RadarLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  static const _waves = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CircleLayer(
        circles: [
          CircleMarker(
            point: widget.center,
            radius: widget.radiusMeters,
            useRadiusInMeter: true,
            color: widget.color.withValues(alpha: 0.08),
            borderColor: widget.color.withValues(alpha: 0.5),
            borderStrokeWidth: 1.5,
          ),
          for (var i = 0; i < _waves; i++) _wave(i),
        ],
      ),
    );
  }

  CircleMarker _wave(int index) {
    final t = (_controller.value + index / _waves) % 1;
    final opacity = 1 - t;
    return CircleMarker(
      point: widget.center,
      radius: widget.radiusMeters * Curves.easeOut.transform(t),
      useRadiusInMeter: true,
      color: widget.color.withValues(alpha: 0.14 * opacity),
      borderColor: widget.color.withValues(alpha: 0.6 * opacity),
      borderStrokeWidth: 2,
    );
  }
}
