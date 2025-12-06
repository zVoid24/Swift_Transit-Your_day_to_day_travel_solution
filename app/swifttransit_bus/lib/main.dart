import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swifttransit_bus/models/route_models.dart';
import 'package:swifttransit_bus/screens/home_screen.dart';
import 'package:swifttransit_bus/screens/login_screen.dart';
import 'package:swifttransit_bus/services/api_service.dart';
import 'package:swifttransit_bus/services/location_service.dart';
import 'package:swifttransit_bus/services/route_storage.dart';
import 'package:swifttransit_bus/services/socket_service.dart';

const _apiBaseUrl = 'https://thermosetting-paralexic-paulene.ngrok-free.dev';
const _socketUrl =
    'https://thermosetting-paralexic-paulene.ngrok-free.dev/bus/location';

void main() {
  runApp(const MyApp());
}

class SessionData {
  final String token;
  final int routeId;
  final String busId;

  const SessionData({
    required this.token,
    required this.routeId,
    required this.busId,
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ApiService apiService = ApiService(baseUrl: _apiBaseUrl);
  final RouteStorage storage = RouteStorage();
  final LocationService locationService = LocationService();
  final SocketService socketService = SocketService(url: _socketUrl);

  Future<(SessionData?, BusRoute?)> _restoreSession() async {
    final token = await storage.token;
    final routeId = await storage.routeId;
    final busId = await storage.busId;
    final cachedRoute = await storage.cachedRoute;
    if (token == null ||
        routeId == null ||
        busId == null ||
        cachedRoute == null) {
      return (null, null);
    }
    return (
      SessionData(token: token, routeId: routeId, busId: busId),
      cachedRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftTransit Bus',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF258BA1),
      ),
      home: FutureBuilder<(SessionData?, BusRoute?)>(
        future: _restoreSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.$1;
          final route = snapshot.data?.$2;

          if (session != null && route != null) {
            return HomeScreen(
              apiService: apiService,
              session: session,
              route: route,
              storage: storage,
              locationService: locationService,
              socketService: socketService,
            );
          }

          return LoginScreen(
            apiService: apiService,
            storage: storage,
            locationService: locationService,
            socketService: socketService,
          );
        },
      ),
    );
  }
}
