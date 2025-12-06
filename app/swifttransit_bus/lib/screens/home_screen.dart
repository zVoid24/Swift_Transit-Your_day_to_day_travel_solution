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
    widget.socketService.connect(widget.session.token);
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
      appBar: AppBar(
        title: Text('Route: ${widget.route.name}'),
        actions: [
          IconButton(
            onPressed: _refreshRoute,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh route',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Ticket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus: ${widget.session.busId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'JWT: ${widget.session.token.substring(0, widget.session.token.length > 10 ? 10 : widget.session.token.length)}...',
                    ),
                    const SizedBox(height: 8),
                    Text('Route ID: ${widget.session.routeId}'),
                    const SizedBox(height: 8),
                    Text('Tracking: ${_tracking ? 'Active' : 'Idle'}'),
                    if (_lastPosition != null)
                      Text(
                        'Last position: ${_lastPosition!.latitude.toStringAsFixed(5)}, ${_lastPosition!.longitude.toStringAsFixed(5)}',
                      ),
                    Text(
                      'Current stoppage: ${_currentStop?.name ?? 'Unknown'}',
                    ),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'All Stoppages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.route.stops.isEmpty
                  ? const Center(child: Text('No stops found for this route'))
                  : ListView.builder(
                      itemCount: widget.route.stops.length,
                      itemBuilder: (_, index) {
                        final stop = widget.route.stops[index];
                        final isCurrent = stop.name == _currentStop?.name;
                        final isSelected = stop.name == _selectedStop?.name;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(stop.order.toString()),
                          ),
                          title: Text(stop.name),
                          subtitle: Text('Order ${stop.order}'),
                          trailing: isCurrent
                              ? const Icon(Icons.directions_bus)
                              : (isSelected
                                    ? const Icon(Icons.check_circle_outline)
                                    : null),
                          onTap: () => _handleStopTap(stop),
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
