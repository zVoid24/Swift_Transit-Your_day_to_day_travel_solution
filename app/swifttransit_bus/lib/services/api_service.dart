import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swifttransit_bus/models/route_models.dart';

class LoginResult {
  final String token;
  final int routeId;
  final String busId;
  final int busCredentialId;
  final String variant;
  final List<RouteVariant> variants;

  LoginResult({
    required this.token,
    required this.routeId,
    required this.busId,
    required this.busCredentialId,
    required this.variant,
    required this.variants,
  });
}

class RouteVariant {
  final String variant;
  final int routeId;

  const RouteVariant({required this.variant, required this.routeId});

  factory RouteVariant.fromJson(Map<String, dynamic> json) {
    return RouteVariant(
      variant: json['variant']?.toString() ?? '',
      routeId: json['route_id'] is int
          ? json['route_id'] as int
          : int.tryParse(json['route_id'].toString()) ?? 0,
    );
  }
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
    required String variant,
  }) async {
    final uri = Uri.parse('$baseUrl/bus/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'registration_number': busIdentifier,
        'password': password,
        'variant': variant,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Login failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final variants = (data['bus']['variants'] as List<dynamic>? ?? [])
        .map((v) => RouteVariant.fromJson(v as Map<String, dynamic>))
        .where((v) => v.routeId != 0 && v.variant.isNotEmpty)
        .toList();
    return LoginResult(
      token: data['token']?.toString() ?? '',
      routeId: data['bus']['route_id'] is int
          ? data['bus']['route_id'] as int
          : int.tryParse(data['bus']['route_id'].toString()) ?? 0,
      busId: data['bus']['registration_number']?.toString() ?? busIdentifier,
      busCredentialId: data['bus']['id'] is int
          ? data['bus']['id'] as int
          : int.tryParse(data['bus']['id'].toString()) ?? 0,
      variant: data['bus']['variant']?.toString() ?? variant,
      variants: variants,
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
