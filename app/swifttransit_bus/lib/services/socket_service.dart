import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:swifttransit_bus/models/route_models.dart';

class SocketService {
  SocketService({required this.url});

  final String url;

  // No connection needed for HTTP, but keeping method to satisfy interface if needed
  void connect(String token, int routeId) {
    // No-op for HTTP
  }

  Future<void> sendPosition({
    required LatLng position,
    required int routeId,
    required String busId,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'route_id': routeId,
          'bus_id': int.tryParse(busId) ?? 0, // Backend expects int
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': 0.0, // Optional, can add if available
        }),
      );

      if (response.statusCode != 200) {
        print(
          'Failed to send location: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  void dispose() {}
}
