import 'package:swifttransit_bus/models/route_models.dart';

class RouteResolver {
  RouteResolver({required this.route});

  final BusRoute route;
  RouteStop? _manualStop;
  int? _lastStopOrder;

  RouteStop? resolveCurrentStop(LatLng position) {
    // 1. Check if we are inside any stop polygon
    for (final stop in route.stops) {
      if (stop.contains(position)) {
        _manualStop = null;
        _lastStopOrder = stop.order;
        return stop;
      }
    }

    // 2. Respect a manually selected stop if one is set
    if (_manualStop != null) {
      _lastStopOrder = _manualStop!.order;
      return _manualStop;
    }

    // 3. If we have a last known stop, return the next one
    if (_lastStopOrder != null) {
      return _nextStopAfter(_lastStopOrder!) ??
          _currentByOrder(_lastStopOrder!);
    }

    // 4. Initial state: we haven't hit any stop yet.
    // Return the first stop in the route.
    if (route.stops.isNotEmpty) {
      final sortedStops = [...route.stops]
        ..sort((a, b) => a.order.compareTo(b.order));
      return sortedStops.first;
    }

    return null;
  }

  void setCurrentStop(RouteStop stop, {bool lockToStop = false}) {
    _lastStopOrder = stop.order;
    _manualStop = lockToStop ? stop : null;
  }

  RouteStop? _currentByOrder(int order) {
    try {
      return route.stops.firstWhere((stop) => stop.order == order);
    } catch (_) {
      return route.stops.isNotEmpty ? route.stops.first : null;
    }
  }

  RouteStop? _nextStopAfter(int order) {
    final sorted = [...route.stops]..sort((a, b) => a.order.compareTo(b.order));
    for (final stop in sorted) {
      if (stop.order > order) {
        return stop;
      }
    }
    // If no next stop (we are at the end), return the last stop
    return sorted.isNotEmpty ? sorted.last : null;
  }
}
