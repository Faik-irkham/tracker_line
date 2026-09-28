import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'route_path.dart';

class RouteService {
  const RouteService();

  Future<RoutePath> fetchRoute(LatLng from, LatLng to) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return _fallback(from, to);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return _fallback(from, to);

      final coordinates =
          (routes.first['geometry']['coordinates'] as List<dynamic>)
              .cast<List<dynamic>>();
      final points = [
        for (final c in coordinates)
          LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length < 2) return _fallback(from, to);
      return RoutePath(points);
    } catch (_) {
      return _fallback(from, to);
    }
  }

  RoutePath _fallback(LatLng from, LatLng to) {
    return RoutePath([from, LatLng(from.latitude, to.longitude), to]);
  }
}
