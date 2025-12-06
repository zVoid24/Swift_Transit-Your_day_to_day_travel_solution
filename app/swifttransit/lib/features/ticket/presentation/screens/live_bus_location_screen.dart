import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:swifttransit/core/colors.dart';
import 'package:swifttransit/features/ticket/application/live_location_provider.dart';

class LiveBusLocationScreen extends StatefulWidget {
  const LiveBusLocationScreen({
    super.key,
    required this.routeId,
    required this.title,
    this.busName,
    this.availableTickets,
  });

  final int routeId;
  final String title;
  final String? busName;
  final List<Map<String, dynamic>>? availableTickets;

  @override
  State<LiveBusLocationScreen> createState() => _LiveBusLocationScreenState();
}

class _LiveBusLocationScreenState extends State<LiveBusLocationScreen> {
  late Map<String, dynamic> _selectedTicket;

  @override
  void initState() {
    super.initState();
    _selectedTicket = _initialTicket();
  }

  Map<String, dynamic> _initialTicket() {
    final tickets = widget.availableTickets ?? [];
    if (tickets.isEmpty) {
      final parts = widget.title.split('→');
      final start = parts.isNotEmpty ? parts.first.trim() : widget.title;
      final end = parts.length > 1 ? parts.last.trim() : '';
      return {
        'route_id': widget.routeId,
        'start_destination': start,
        'end_destination': end,
        'bus_name': widget.busName,
      };
    }

    return tickets.firstWhere(
      (t) => (t['route_id'] as num?)?.toInt() == widget.routeId,
      orElse: () => tickets.first,
    );
  }

  void _changeTicket(Map<String, dynamic> ticket) {
    setState(() {
      _selectedTicket = ticket;
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeId =
        (_selectedTicket['route_id'] as num?)?.toInt() ?? widget.routeId;
    final title =
        _selectedTicket.containsKey('start_destination') &&
            _selectedTicket.containsKey('end_destination')
        ? '${_selectedTicket['start_destination']} → ${_selectedTicket['end_destination']}'
        : widget.title;
    final busName = (_selectedTicket['bus_name'] ?? widget.busName)?.toString();

    return ChangeNotifierProvider(
      key: ValueKey(routeId),
      create: (_) => LiveLocationProvider(routeId: routeId)..connect(),
      child: _LiveBusLocationView(
        title: title,
        busName: busName,
        tickets: widget.availableTickets,
        selectedTicket: _selectedTicket,
        onTicketChanged: widget.availableTickets != null ? _changeTicket : null,
      ),
    );
  }
}

class _LiveBusLocationView extends StatelessWidget {
  const _LiveBusLocationView({
    required this.title,
    this.busName,
    this.tickets,
    this.selectedTicket,
    this.onTicketChanged,
  });

  final String title;
  final String? busName;
  final List<Map<String, dynamic>>? tickets;
  final Map<String, dynamic>? selectedTicket;
  final ValueChanged<Map<String, dynamic>>? onTicketChanged;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveLocationProvider>();
    final busLocations = provider.busLocations;
    final markers = <Marker>[];
    final ticketOptions = tickets ?? [];
    final selectedId =
        (selectedTicket?['id'] as num?)?.toInt() ??
        (selectedTicket?['route_id'] as num?)?.toInt();
    final dropdownValue =
        selectedId ??
        (ticketOptions.isNotEmpty
            ? ((ticketOptions.first['id'] as num?)?.toInt() ??
                  (ticketOptions.first['route_id'] as num?)?.toInt())
            : null);

    // Build markers
    // 1. Stoppage markers
    for (final stop in provider.stops) {
      final lat = stop['lat'];
      final lon = stop['lon'];
      final name = stop['name']?.toString() ?? '';
      if (lat is num && lon is num) {
        markers.add(
          Marker(
            point: LatLng(lat.toDouble(), lon.toDouble()),
            width: 100,
            height: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // 2. User Location Marker
    if (provider.userLocation != null) {
      markers.add(
        Marker(
          point: provider.userLocation!,
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Bus markers
    for (final update in busLocations.values) {
      markers.add(
        Marker(
          width: 60,
          height: 60,
          point: update.latLng,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${update.speed?.toStringAsFixed(0) ?? 0} km/h',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Live Bus — $title')),
      body: Column(
        children: [
          if (ticketOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select ticket to track',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: dropdownValue,
                    items: ticketOptions.map((ticket) {
                      final id =
                          (ticket['id'] as num?)?.toInt() ??
                          (ticket['route_id'] as num?)?.toInt();
                      final label =
                          '${ticket['bus_name'] ?? 'Bus'} • ${ticket['start_destination']} → ${ticket['end_destination']}';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: onTicketChanged == null
                        ? null
                        : (value) {
                            if (value == null) return;
                            final ticket = ticketOptions.firstWhere(
                              (t) =>
                                  ((t['id'] as num?)?.toInt() ??
                                      (t['route_id'] as num?)?.toInt()) ==
                                  value,
                              orElse: () => <String, dynamic>{},
                            );
                            if (ticket.isNotEmpty) {
                              onTicketChanged!(ticket as Map<String, dynamic>);
                            }
                          },
                  ),
                ),
              ),
            ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: busLocations.isNotEmpty
                    ? busLocations.values.first.latLng
                    : const LatLng(23.8103, 90.4125),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.swifttransit',
                ),
                if (provider.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Border
                      Polyline(
                        points: provider.routePoints,
                        strokeWidth: 7.0,
                        color: Colors.white,
                      ),
                      // Main line
                      Polyline(
                        points: provider.routePoints,
                        strokeWidth: 4.0,
                        color: Colors.black,
                      ),
                    ],
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
                        busName ?? 'Route ${provider.routeId}',
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
                if (busLocations.isNotEmpty)
                  Column(
                    children: busLocations.values.map((update) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Chip(
                              label: Text('Bus #${update.busId}'),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              labelStyle: TextStyle(color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            if (update.speed != null)
                              Chip(
                                label: Text(
                                  '${update.speed!.toStringAsFixed(1)} km/h',
                                ),
                              ),
                            const Spacer(),
                            Text(
                              'Updated ${_timeAgo(update.receivedAt)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
