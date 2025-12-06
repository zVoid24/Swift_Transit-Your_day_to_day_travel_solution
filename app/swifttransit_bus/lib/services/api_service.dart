import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swifttransit_bus/models/route_models.dart';

class LoginResult {
  final String token;
  final int routeId;
  final String busId;

  LoginResult({required this.token, required this.routeId, required this.busId});
}

class TicketCheckResult {
  final bool isValid;
  final String message;
  final Map<String, dynamic> payload;

  TicketCheckResult({
    required this.isValid,
    required this.message,
    required this.payload,
  });
}

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<LoginResult> login({
    required String busIdentifier,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/bus/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'bus_id': busIdentifier, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult(
      token: data['token']?.toString() ?? '',
      routeId: data['route_id'] is int
          ? data['route_id'] as int
          : int.tryParse(data['route_id'].toString()) ?? 0,
      busId: data['bus_id']?.toString() ?? busIdentifier,
    );
  }

  Future<BusRoute> fetchRoute({
    required int routeId,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/route/$routeId');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Route fetch failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BusRoute.fromJson(data);
  }

  Future<TicketCheckResult> checkTicket({
    required String qrData,
    required String token,
    required int routeId,
    required String currentStop,
  }) async {
    final uri = Uri.parse('$baseUrl/tickets/check');
    final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qr': qrData,
          'route_id': routeId,
          'current_stop': currentStop,
        }));

    if (response.statusCode != 200) {
      throw Exception('Ticket check failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TicketCheckResult(
      isValid: data['valid'] == true,
      message: data['message']?.toString() ?? 'Unknown response',
      payload: data,
    );
  }
}
