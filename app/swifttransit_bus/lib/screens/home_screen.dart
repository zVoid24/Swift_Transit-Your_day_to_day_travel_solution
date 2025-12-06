import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swifttransit_bus/main.dart';
import 'package:swifttransit_bus/models/route_models.dart';
import 'package:swifttransit_bus/screens/ticket_scan_screen.dart';
import 'package:swifttransit_bus/services/api_service.dart';
import 'package:swifttransit_bus/services/location_service.dart';
import 'package:swifttransit_bus/services/route_storage.dart';
import 'package:swifttransit_bus/services/socket_service.dart';
import 'package:swifttransit_bus/utils/route_resolver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiService,
    required this.session,
    required this.route,
    required this.storage,
    required this.locationService,
    required this.socketService,
  });

  final ApiService apiService;
  final SessionData session;
  final BusRoute route;
  final RouteStorage storage;
  final LocationService locationService;
  final SocketService socketService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RouteResolver _resolver;
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _lastPosition;
  RouteStop? _currentStop;
  RouteStop? _selectedStop;
  bool _tracking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolver = RouteResolver(route: widget.route);
    widget.socketService.connect(widget.session.token, widget.session.routeId);
    _startTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    widget.socketService.dispose();
    super.dispose();
  }

  void _startTracking() {
    _locationSubscription = widget.locationService.positionStream().listen(
      (position) {
        setState(() {
          _lastPosition = position;
          _currentStop = _resolver.resolveCurrentStop(position);
          if (_selectedStop != null &&
              _currentStop?.name == _selectedStop?.name) {
            _selectedStop = null;
          }
          _tracking = true;
          _error = null;
        });
        widget.socketService.sendPosition(
          position: position,
          routeId: widget.session.routeId,
          busId: widget.session.busId,
        );
      },
      onError: (err) {
        setState(() {
          _error = err.toString();
          _tracking = false;
        });
      },
    );
  }

  void _setManualStop(RouteStop stop) {
    _resolver.setCurrentStop(stop, lockToStop: true);
    setState(() {
      _currentStop = stop;
      _selectedStop = stop;
      _error = null;
    });
  }

  Future<void> _handleStopTap(RouteStop stop) async {
    try {
      final position =
          _lastPosition ?? await widget.locationService.currentPosition();
      _lastPosition = position;
      final isInside = stop.contains(position);
      if (isInside) {
        _setManualStop(stop);
        return;
      }

      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirm stoppage'),
              content: Text(
                'You do not appear to be inside ${stop.name}. Are you currently at this stoppage?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('No'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Yes, update'),
                ),
              ],
            ),
          ) ??
          false;

      if (confirmed) {
        _setManualStop(stop);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshRoute() async {
    try {
      final freshRoute = await widget.apiService.fetchRoute(
        routeId: widget.session.routeId,
        token: widget.session.token,
      );
      await widget.storage.saveRoute(freshRoute);
      setState(() {
        _resolver = RouteResolver(route: freshRoute);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketScanScreen(
          apiService: widget.apiService,
          session: widget.session,
          currentStop:
              _currentStop ??
              const RouteStop(name: 'Unknown', order: 0, polygon: []),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Swift Transit Bus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Route: ${widget.route.name}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refreshRoute,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh route',
          ),
          IconButton(
            onPressed: () {
              // Add logout logic here if needed
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Ticket'),
        backgroundColor: const Color(0xFF258BA1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus Status',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.session.busId,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF258BA1),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _tracking
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _tracking ? Colors.green : Colors.orange,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _tracking ? Icons.gps_fixed : Icons.gps_off,
                                size: 16,
                                color: _tracking ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _tracking ? 'Active' : 'Idle',
                                style: TextStyle(
                                  color: _tracking
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Stoppage',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _currentStop?.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_lastPosition != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Lat: ${_lastPosition!.latitude.toStringAsFixed(5)}, Lng: ${_lastPosition!.longitude.toStringAsFixed(5)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Route Stoppages',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.route.stops.isEmpty
                  ? const Center(child: Text('No stops found for this route'))
                  : ListView.builder(
                      itemCount: widget.route.stops.length,
                      itemBuilder: (_, index) {
                        final stop = widget.route.stops[index];
                        final isCurrent = stop.name == _currentStop?.name;
                        final isSelected = stop.name == _selectedStop?.name;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF258BA1)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrent
                                  ? const Color(0xFF258BA1)
                                  : Colors.grey[200],
                              foregroundColor: isCurrent
                                  ? Colors.white
                                  : Colors.grey[700],
                              child: Text(stop.order.toString()),
                            ),
                            title: Text(
                              stop.name,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text('Order ${stop.order}'),
                            trailing: isCurrent
                                ? const Icon(
                                    Icons.directions_bus,
                                    color: Color(0xFF258BA1),
                                  )
                                : (isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF258BA1),
                                        )
                                      : null),
                            onTap: () => _handleStopTap(stop),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
