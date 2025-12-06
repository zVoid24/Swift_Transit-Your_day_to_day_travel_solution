import 'dart:async';
import 'dart:convert';

import 'package:swifttransit_bus/models/route_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  SocketService({required this.url});

  final String url;
  WebSocketChannel? _channel;

  void connect(String token) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel?.sink.add(jsonEncode({'type': 'auth', 'token': token}));
  }

  void sendPosition({
    required LatLng position,
    required int routeId,
    required String busId,
  }) {
    _channel?.sink.add(jsonEncode({
      'type': 'location',
      'route_id': routeId,
      'bus_id': busId,
      'latitude': position.latitude,
      'longitude': position.longitude,
    }));
  }

  void dispose() {
    _channel?.sink.close();
  }
}
