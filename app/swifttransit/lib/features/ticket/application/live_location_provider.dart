import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

import 'package:swifttransit/core/constants.dart';

class LiveLocationUpdate {
  final int busId;
  final int routeId;
  final double latitude;
  final double longitude;
  final double? speed;
  final DateTime receivedAt;

  LatLng get latLng => LatLng(latitude, longitude);

  LiveLocationUpdate({
    required this.busId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.speed,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory LiveLocationUpdate.fromJson(Map<String, dynamic> json) {
    return LiveLocationUpdate(
      busId: (json['bus_id'] as num).toInt(),
      routeId: (json['route_id'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
    );
  }
}

class LiveLocationProvider extends ChangeNotifier {
  LiveLocationProvider({required this.routeId});

  final int routeId;
  final Map<int, LiveLocationUpdate> busLocations = {};
  List<LatLng> routePoints = [];
  List<dynamic> stops = [];
  LatLng? userLocation;
  bool connecting = false;
  String? errorMessage;

  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;

  Uri _buildSocketUri() {
    final base = Uri.parse(AppConstants.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : (base.scheme == 'https' ? 443 : 80),
      path: '/ws/location',
      queryParameters: {'route_id': routeId.toString()},
    );
  }

  Future<void> connect() async {
    await disconnect();
    // Fetch static route data (polyline, stops)
    fetchRouteDetails();
    // Fetch user location
    fetchUserLocation();

    connecting = true;
    errorMessage = null;
    notifyListeners();

    final uri = _buildSocketUri();
    try {
      _channel = IOWebSocketChannel.connect(
        uri.toString(),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      _subscription = _channel!.stream.listen(
        (event) {
          try {
            final data = event is String ? jsonDecode(event) : event;
            if (data is Map<String, dynamic>) {
              final update = LiveLocationUpdate.fromJson(data);
              busLocations[update.busId] = update;
              errorMessage = null;
              notifyListeners();
            }
          } catch (e) {
            errorMessage = 'Failed to parse update';
            notifyListeners();
          }
        },
        onError: (err) {
          errorMessage = err.toString();
          notifyListeners();
        },
        onDone: () {
          notifyListeners();
        },
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    connecting = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> fetchRouteDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt');
      // Even if public, sending JWT if available is good practice, or required by some endpoints
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (jwt != null) headers['Authorization'] = 'Bearer $jwt';

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/route/$routeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse stops
        if (data['stops'] != null) {
          stops = List.from(data['stops']);
        }

        // Parse polyline
        if (data['linestring_geojson'] != null) {
          routePoints = _extractRoutePoints(data['linestring_geojson']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching route details: $e');
    }
  }

  List<LatLng> _extractRoutePoints(dynamic geometry) {
    List<dynamic> coordinates = [];
    try {
      if (geometry is String && geometry.isNotEmpty) {
        final geoJson = jsonDecode(geometry);
        coordinates = geoJson['coordinates'] ?? [];
      } else if (geometry is Map<String, dynamic>) {
        coordinates = geometry['coordinates'] ?? [];
      }
    } catch (e) {
      debugPrint('Failed to parse route geometry: $e');
    }

    return coordinates
        .whereType<List>()
        .map<LatLng?>((coord) {
          if (coord.length < 2) return null;
          final lon = coord[0];
          final lat = coord[1];
          if (lon is num && lat is num) {
            return LatLng(lat.toDouble(), lon.toDouble());
          }
          return null;
        })
        .whereType<LatLng>()
        .toList();
  }

  Future<void> fetchUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      userLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user location: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
