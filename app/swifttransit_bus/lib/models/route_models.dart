import 'dart:convert';
import 'dart:math';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({required this.latitude, required this.longitude});
}

class RouteStop {
  final String name;
  final int order;
  final List<LatLng> polygon;

  const RouteStop({
    required this.name,
    required this.order,
    required this.polygon,
  });

  factory RouteStop.fromFeature(
    Map<String, dynamic> feature, {
    int? fallbackOrder,
  }) {
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final coordinates = feature['geometry']['coordinates'] as List<dynamic>;
    final ring = coordinates.first as List<dynamic>;
    return RouteStop(
      name: properties['Name']?.toString() ?? 'Unknown stop',
      order: (properties['order'] ?? fallbackOrder ?? 0) is int
          ? (properties['order'] ?? fallbackOrder ?? 0) as int
          : int.tryParse((properties['order'] ?? fallbackOrder ?? 0).toString()) ??
              0,
      polygon: ring
          .map((pair) => LatLng(
                longitude: (pair[0] as num).toDouble(),
                latitude: (pair[1] as num).toDouble(),
              ))
          .toList(),
    );
  }

  bool contains(LatLng location) {
    // Ray casting algorithm for point-in-polygon
    final int count = polygon.length;
    bool inside = false;
    for (int i = 0, j = count - 1; i < count; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;
      final intersect = ((yi > location.latitude) != (yj > location.latitude)) &&
          (location.longitude <
              (xj - xi) * (location.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  LatLng get centroid {
    // Simple centroid approximation for polygons that approximate circles
    double area = 0;
    double cx = 0;
    double cy = 0;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final double f =
          (polygon[j].longitude * polygon[i].latitude -
              polygon[i].longitude * polygon[j].latitude);
      area += f;
      cx += (polygon[j].longitude + polygon[i].longitude) * f;
      cy += (polygon[j].latitude + polygon[i].latitude) * f;
    }
    area *= 0.5;
    final double factor = area == 0 ? 0 : 1 / (6 * area);
    return LatLng(latitude: cy * factor, longitude: cx * factor);
  }

  double distanceTo(LatLng point) {
    double toRadians(double deg) => deg * pi / 180.0;
    const double earthRadius = 6371000; // meters
    final dLat = toRadians(point.latitude - centroid.latitude);
    final dLon = toRadians(point.longitude - centroid.longitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(toRadians(centroid.latitude)) *
                cos(toRadians(point.latitude)) *
                sin(dLon / 2) *
                sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}

class BusRoute {
  final String name;
  final List<RouteStop> stops;
  final Map<String, dynamic> raw;

  const BusRoute({
    required this.name,
    required this.stops,
    required this.raw,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as List<dynamic>? ?? [];

    int? parseOrder(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final pointOrders = <String, int>{};
    for (final feature in features) {
      final map = feature as Map<String, dynamic>;
      final geometry = map['geometry'] as Map<String, dynamic>?;
      if (geometry == null || geometry['type'] != 'Point') continue;

      final properties = map['properties'] as Map<String, dynamic>? ?? {};
      final name = properties['Name']?.toString();
      final order = parseOrder(properties['order']);
      if (name != null && order != null) {
        pointOrders[name] = order;
      }
    }

    final stopFeatures = features.where((feature) {
      final map = feature as Map<String, dynamic>;
      final geometry = map['geometry'] as Map<String, dynamic>?;
      return geometry != null && geometry['type'] == 'Polygon';
    }).cast<Map<String, dynamic>>();

    final stops = stopFeatures
        .map((feature) {
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final name = properties['Name']?.toString();
      final fallbackOrder = name != null ? pointOrders[name] : null;
      return RouteStop.fromFeature(feature, fallbackOrder: fallbackOrder);
    })
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return BusRoute(
      name: json['name']?.toString() ?? 'Unnamed Route',
      stops: stops,
      raw: json,
    );
  }

  String toCache() => jsonEncode(raw);
}
