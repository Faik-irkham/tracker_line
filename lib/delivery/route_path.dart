import 'package:latlong2/latlong.dart';

class RoutePath {
  RoutePath(this.points)
    : assert(points.length >= 2),
      _cumulative = _buildCumulative(points);

  static const _distance = Distance(roundResult: false);

  final List<LatLng> points;
  final List<double> _cumulative;

  double get totalDistance => _cumulative.last;
  LatLng get start => points.first;
  LatLng get end => points.last;

  static List<double> _buildCumulative(List<LatLng> points) {
    final result = <double>[0];
    for (var i = 1; i < points.length; i++) {
      result.add(result.last + _distance(points[i - 1], points[i]));
    }
    return result;
  }

  int _segmentAt(double meters) {
    var low = 0;
    var high = _cumulative.length - 1;
    while (high - low > 1) {
      final mid = (low + high) >> 1;
      if (_cumulative[mid] <= meters) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }

  LatLng pointAt(double meters) {
    final d = meters.clamp(0.0, totalDistance);
    final i = _segmentAt(d);
    final segmentLength = _cumulative[i + 1] - _cumulative[i];
    if (segmentLength == 0) return points[i];
    final t = (d - _cumulative[i]) / segmentLength;
    final a = points[i];
    final b = points[i + 1];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  double headingAt(double meters, {double window = 12}) {
    final from = pointAt(meters - window);
    final to = pointAt(meters + window);
    if (from == to) return 0;
    return _distance.bearing(from, to);
  }

  List<LatLng> traveled(double meters) {
    final d = meters.clamp(0.0, totalDistance);
    final i = _segmentAt(d);
    return [...points.sublist(0, i + 1), pointAt(d)];
  }

  List<LatLng> remaining(double meters) {
    final d = meters.clamp(0.0, totalDistance);
    final i = _segmentAt(d);
    return [pointAt(d), ...points.sublist(i + 1)];
  }
}
