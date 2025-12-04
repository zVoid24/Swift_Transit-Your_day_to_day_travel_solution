import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/io.dart';

import '../core/constants.dart';

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
  LiveLocationUpdate? latestUpdate;
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
    connecting = true;
    errorMessage = null;
    notifyListeners();

    final uri = _buildSocketUri();
    try {
      _channel = IOWebSocketChannel.connect(uri.toString());
      _subscription = _channel!.stream.listen(
        (event) {
          try {
            final data = event is String ? jsonDecode(event) : event;
            if (data is Map<String, dynamic>) {
              latestUpdate = LiveLocationUpdate.fromJson(data);
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

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
