import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/live_location_provider.dart';
import '../../core/colors.dart';

class LiveBusLocationScreen extends StatelessWidget {
  const LiveBusLocationScreen({
    super.key,
    required this.routeId,
    required this.title,
    this.busName,
  });

  final int routeId;
  final String title;
  final String? busName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LiveLocationProvider(routeId: routeId)..connect(),
      child: _LiveBusLocationView(
        title: title,
        busName: busName,
      ),
    );
  }
}

class _LiveBusLocationView extends StatelessWidget {
  const _LiveBusLocationView({required this.title, this.busName});

  final String title;
  final String? busName;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveLocationProvider>();
    final update = provider.latestUpdate;
    final markers = <Marker>[];

    if (update != null) {
      markers.add(
        Marker(
          width: 52,
          height: 52,
          point: update.latLng,
          child: const Icon(
            Icons.directions_bus,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Bus — $title'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: update?.latLng ?? const LatLng(23.8103, 90.4125),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.swifttransit',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_bus, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        busName ?? 'Route $routeId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (provider.connecting)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => provider.connect(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (update != null)
                  Row(
                    children: [
                      Chip(
                        label: Text('Bus #${update.busId}'),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      if (update.speed != null)
                        Chip(
                          label: Text('${update.speed!.toStringAsFixed(1)} km/h'),
                        ),
                      const Spacer(),
                      Text(
                        'Updated ${_timeAgo(update.receivedAt)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  )
                else if (provider.errorMessage != null)
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  )
                else
                  const Text('Waiting for live location updates...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ${diff.inMinutes % 60} min ago';
  }
}
