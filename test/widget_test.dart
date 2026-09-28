import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tracker_line/delivery/route_path.dart';

void main() {
  final route = RoutePath(const [
    LatLng(-6.2000, 106.8000),
    LatLng(-6.2000, 106.8100),
    LatLng(-6.2100, 106.8100),
  ]);

  test('pointAt starts and ends at route endpoints', () {
    expect(route.pointAt(0), route.start);
    expect(route.pointAt(route.totalDistance), route.end);
    expect(route.pointAt(-50), route.start);
    expect(route.pointAt(route.totalDistance + 50), route.end);
  });

  test('traveled and remaining split at the driver position', () {
    final half = route.totalDistance / 2;
    final driver = route.pointAt(half);
    expect(route.traveled(half).first, route.start);
    expect(route.traveled(half).last, driver);
    expect(route.remaining(half).first, driver);
    expect(route.remaining(half).last, route.end);
  });

  test('headingAt follows the road direction', () {
    expect(route.headingAt(100), closeTo(90, 1));
    expect(route.headingAt(route.totalDistance - 100).abs(), closeTo(180, 1));
  });
}
