import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swifttransit_bus/models/route_models.dart';

class LoginResult {
  final String token;
  final int routeId;
  final String busId;

  LoginResult({
    required this.token,
    required this.routeId,
    required this.busId,
  });
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
    final uri = Uri.parse('$baseUrl/bus/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'registration_number': busIdentifier,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Login failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResult(
      token: data['token']?.toString() ?? '',
      routeId: data['bus']['route_id'] is int
          ? data['bus']['route_id'] as int
          : int.tryParse(data['bus']['route_id'].toString()) ?? 0,
      busId: data['bus']['registration_number']?.toString() ?? busIdentifier,
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
    print(response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    print("Dataaaaaaaaaaaaaaa: $data");
    return BusRoute.fromJson(data);
  }

  Future<TicketCheckResult> checkTicket({
    required String qrData,
    required String token,
    required int routeId,
    required String currentStop,
    required int currentStopOrder,
  }) async {
    final uri = Uri.parse('$baseUrl/bus/check-ticket');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'qr_code': qrData,
        'route_id': routeId,
        'current_stoppage': {"name": currentStop, "order": currentStopOrder},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ticket check failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TicketCheckResult(
      isValid: data['status'] == 'valid',
      message: data['message']?.toString() ?? 'Ticket is ${data['status']}',
      payload: data,
    );
  }
}
