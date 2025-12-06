import 'package:swifttransit_bus/models/route_models.dart';

class RouteResolver {
  RouteResolver({required this.route});

  final BusRoute route;
  int? _lastStopOrder;

  RouteStop? resolveCurrentStop(LatLng position) {
    for (final stop in route.stops) {
      if (stop.contains(position)) {
        _lastStopOrder = stop.order;
        return stop;
      }
    }

    if (_lastStopOrder != null) {
      return _nextStopAfter(_lastStopOrder!) ?? _currentByOrder(_lastStopOrder!);
    }

    if (route.stops.isEmpty) return null;

    // No last known stop; fallback to the closest stop along the ordered list.
    route.stops.sort((a, b) => a.order.compareTo(b.order));
    _lastStopOrder = route.stops.first.order;
    return route.stops.first;
  }

  RouteStop? _currentByOrder(int order) {
    return route.stops.firstWhere(
      (stop) => stop.order == order,
      orElse: () => route.stops.first,
    );
  }

  RouteStop? _nextStopAfter(int order) {
    final sorted = [...route.stops]..sort((a, b) => a.order.compareTo(b.order));
    for (final stop in sorted) {
      if (stop.order > order) {
        _lastStopOrder = stop.order;
        return stop;
      }
    }
    // Already past final stop; stay on the last one.
    return sorted.isNotEmpty ? sorted.last : null;
  }
}
