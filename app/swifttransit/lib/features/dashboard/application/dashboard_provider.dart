// Dashboard state management provider
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:swifttransit/core/constants.dart';
import 'package:swifttransit/features/ticket/presentation/screens/payment_webview_screen.dart';
import 'package:swifttransit/models/transaction_model.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({this.initialBalance = 0.0, this.initialPoints = 0}) {
    balance = initialBalance;
    swiftPoints = initialPoints;
  }

  // initializers for testing / default
  final double initialBalance;
  final int initialPoints;

  // UI state
  int selectedIndex = 0;

  String? selectedDeparture;
  String? selectedDestination;
  String? confirmedDeparture;
  String? confirmedDestination;

  // Dynamic data
  String userName = "User";
  double balance = 0.0;
  int swiftPoints = 0;

  // Map & routing
  List<LatLng> routePoints = [];
  List<Marker> markers = [];
  int? currentRouteId;
  String? currentBusName;
  List<Map<String, dynamic>> availableBuses = [];
  int? selectedBusIndex;

  // Route search (by bus/route name)
  List<Map<String, dynamic>> searchedRoutes = [];
  Map<String, dynamic>? selectedRoute;
  List<LatLng> selectedRoutePoints = [];
  List<Marker> selectedRouteMarkers = [];
  bool isSearchingRoutes = false;

  List<dynamic> tickets = [];
  bool isLoadingTickets = false;
  bool isLoadingMoreTickets = false;
  int ticketPage = 1;
  int ticketLimit = 10;
  int totalTickets = 0;
  bool hasMoreTickets = true;

  // Transactions
  List<TransactionModel> transactions = [];
  bool isLoadingTransactions = false;

  Future<void> fetchTransactions() async {
    isLoadingTransactions = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) {
      isLoadingTransactions = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        transactions = data
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      } else {
        debugPrint("Failed to fetch transactions: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    } finally {
      isLoadingTransactions = false;
      notifyListeners();
    }
  }

  // flags
  bool _isRefreshing = false;
  bool _isRecharging = false;

  bool get isRefreshing => _isRefreshing;
  bool get isRecharging => _isRecharging;

  Map<String, dynamic>? get activeTicket {
    for (final ticket in tickets) {
      if (ticket is Map<String, dynamic>) {
        final paid = ticket['paid_status'] == true;
        final checked = ticket['checked'] == true;
        final cancelled = ticket['cancelled_at'] != null;
        if (paid && !checked && !cancelled) {
          return ticket;
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get dashboardTickets {
    final sorted = tickets.whereType<Map<String, dynamic>>().toList()
      ..sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at'] ?? '')?.millisecondsSinceEpoch ??
            0;
        final dateB =
            DateTime.tryParse(b['created_at'] ?? '')?.millisecondsSinceEpoch ??
            0;
        return dateB.compareTo(dateA);
      });

    final result = <Map<String, dynamic>>[];
    final seenIds = <int>{};

    final active = sorted.firstWhere(
      (t) => t['paid_status'] == true && t['checked'] != true,
      orElse: () => {},
    );

    if (active.isNotEmpty) {
      result.add(active);
      final id = (active['id'] as num?)?.toInt();
      if (id != null) seenIds.add(id);
    }

    for (final ticket in sorted) {
      final id = (ticket['id'] as num?)?.toInt();
      if (id != null && seenIds.contains(id)) continue;
      result.add(ticket);
      if (result.length >= (active.isNotEmpty ? 3 : 2)) break;
    }

    return result;
  }

  List<Map<String, dynamic>> get upcomingTickets {
    return tickets
        .whereType<Map<String, dynamic>>()
        .where(
          (ticket) =>
              ticket['paid_status'] == true &&
              ticket['checked'] != true &&
              ticket['cancelled_at'] == null,
        )
        .toList()
      ..sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at'] ?? '')?.millisecondsSinceEpoch ??
            0;
        final dateB =
            DateTime.tryParse(b['created_at'] ?? '')?.millisecondsSinceEpoch ??
            0;
        return dateB.compareTo(dateA);
      });
  }

  final quotes = [
    "Safe journeys begin with patience and careful planning.",
    "Your safety is our priority—enjoy a secure ride with SwiftTransit!",
    "Travel with confidence. Arrive safe, every time.",
  ];

  final trips = [
    {"route": "Gulistan - Savar", "time": "Every 20 min", "fare": "৳60"},
    {"route": "Nilkhet - Azimpur", "time": "Every 15 min", "fare": "৳30"},
    {"route": "Uttara - Banani", "time": "Every 10 min", "fare": "৳45"},
    {"route": "Motijheel - Farmgate", "time": "Every 12 min", "fare": "৳40"},
  ];

  final ads = [
    "assets/ads/ad1.png",
    "assets/ads/ad2.png",
    "assets/ads/ad3.png",
  ];

  // Navigation tab change
  void updateTab(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  // Dropdown Update
  void setDeparture(String? value) {
    selectedDeparture = value;
    clearSearchResults();
  }

  void setDestination(String? value) {
    selectedDestination = value;
    clearSearchResults();
  }

  /// Fetch user info (name, balance, maybe points) from server and update local fields.
  /// Keeps the original behavior but also updates swiftPoints if present.
  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _updateLocalUserData(data);
      } else {
        // non-200: do not overwrite fields, but log optionally
        debugPrint(
          'fetchUserInfo failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint("Error fetching user info: $e");
    }
  }

  void setUserData(Map<String, dynamic> data) {
    _updateLocalUserData(data);
  }

  void _updateLocalUserData(dynamic data) {
    if (data['name'] != null) userName = data['name'];
    if (data['balance'] != null) {
      balance = (data['balance'] as num).toDouble();
    }
    // If API returns points, use it
    if (data['balance'] != null) {
      try {
        swiftPoints = (data['balance'] as num).toInt();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Refresh balance helper - UI calls this to refresh balance.
  /// Returns true on success, false on failure.
  Future<bool> refreshBalance() async {
    if (_isRefreshing) return true;
    _isRefreshing = true;
    notifyListeners();

    try {
      await fetchUserInfo(); // reuse existing method
      _isRefreshing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isRefreshing = false;
      notifyListeners();
      debugPrint('refreshBalance error: $e');
      return false;
    }
  }

  Future<bool> startRecharge(BuildContext context, int amount) async {
    if (_isRecharging) return false;
    _isRecharging = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt');
      if (jwt == null) {
        _isRecharging = false;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to recharge.')),
        );
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/wallet/recharge'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Some environments return `gateway_url` (recharge) while others
        // mirror the ticket flow and return `payment_url`. Handle both so the
        // webview always opens.
        final paymentUrl = (data['gateway_url'] ?? data['payment_url'])
            ?.toString();
        if (paymentUrl == null || paymentUrl.isEmpty) {
          throw Exception('Invalid payment URL');
        }

        if (!context.mounted) {
          _isRecharging = false;
          notifyListeners();
          return false;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              paymentUrl: paymentUrl,
              onSuccess: () async {
                await fetchUserInfo();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Balance updated successfully.'),
                    ),
                  );
                }
              },
              onFailure: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recharge was cancelled or failed.'),
                    ),
                  );
                }
              },
            ),
          ),
        );

        _isRecharging = false;
        notifyListeners();
        return true;
      }

      throw Exception('Failed to start recharge: ${response.body}');
    } catch (e) {
      debugPrint('recharge error: $e');
      _isRecharging = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recharge failed. Please try again.')),
        );
      }
      return false;
    }
  }

  /// Simulate using swift points — returns true on success.
  Future<bool> useSwiftPoints({int pointsToUse = 10}) async {
    if (swiftPoints < pointsToUse) return false;

    try {
      // Simulate server redemption call
      await Future.delayed(const Duration(milliseconds: 600));
      swiftPoints -= pointsToUse;

      // Optionally convert points to balance
      // balance += pointsToUse.toDouble();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('useSwiftPoints error: $e');
      return false;
    }
  }

  /// Search routes - unchanged from your original implementation
  Future<void> searchBus() async {
    if (selectedDeparture == null || selectedDestination == null) return;

    // Clear previous state so users don't see stale routes while searching
    currentRouteId = null;
    currentBusName = null;
    selectedBusIndex = null;
    availableBuses = [];
    routePoints = [];
    markers = [];
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/bus/find'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start_destination': selectedDeparture,
          'end_destination': selectedDestination,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          debugPrint("No bus found");
          notifyListeners();
          return;
        }

        availableBuses = data.whereType<Map<String, dynamic>>().toList();
        if (availableBuses.isEmpty) {
          debugPrint("No valid bus data returned");
          notifyListeners();
          return;
        }

        _setSelectedBus(0);
        confirmedDeparture = selectedDeparture;
        confirmedDestination = selectedDestination;
      } else {
        debugPrint("Bus not found: ${response.body}");
        // Clear map if route not found
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error searching bus: $e");
    }
  }

  void selectBus(int index) {
    _setSelectedBus(index);
  }

  void _setSelectedBus(int index) {
    if (index < 0 || index >= availableBuses.length) return;

    final bus = availableBuses[index];
    selectedBusIndex = index;
    currentRouteId = (bus['id'] as num?)?.toInt();
    currentBusName = bus['name']?.toString() ?? "Swift Bus";

    routePoints = _extractRoutePoints(bus['linestring_geojson']);

    final stops = (bus['stops'] as List?) ?? [];
    markers = _buildMarkersFromStops(stops);

    notifyListeners();
  }

  void clearSearch() {
    selectedDeparture = null;
    selectedDestination = null;
    confirmedDeparture = null;
    confirmedDestination = null;
    clearSearchResults();
  }

  void clearSearchResults() {
    currentRouteId = null;
    currentBusName = null;
    selectedBusIndex = null;
    availableBuses = [];
    routePoints = [];
    markers = [];
    notifyListeners();
  }

  double? get currentFare {
    if (selectedBusIndex == null ||
        selectedBusIndex! >= availableBuses.length) {
      return null;
    }
    final fare = availableBuses[selectedBusIndex!]['fare'];
    double? parsedFare;
    if (fare is num) {
      parsedFare = fare.toDouble();
    } else {
      parsedFare = double.tryParse(fare?.toString() ?? '');
    }

    if (parsedFare != null) {
      return parsedFare;
    }
    return null;
  }

  List<LatLng> _extractRoutePoints(dynamic geometry) {
    List<dynamic> coordinates = [];
    try {
      if (geometry is String && geometry.isNotEmpty) {
        final geoJson = jsonDecode(geometry);
        coordinates = geoJson['coordinates'] ?? [];
      } else if (geometry is Map<String, dynamic>) {
        coordinates = geometry['coordinates'] ?? [];
      }
    } catch (e) {
      debugPrint('Failed to parse route geometry: $e');
    }

    return coordinates
        .whereType<List>()
        .map<LatLng?>((coord) {
          if (coord.length < 2) return null;
          final lon = coord[0];
          final lat = coord[1];
          if (lon is num && lat is num) {
            return LatLng(lat.toDouble(), lon.toDouble());
          }
          return null;
        })
        .whereType<LatLng>()
        .toList();
  }

  List<Marker> _buildMarkersFromStops(List<dynamic> stops) {
    return stops
        .map<Marker?>((stop) {
          final lat = stop['lat'];
          final lon = stop['lon'];
          final name = stop['name']?.toString() ?? '';
          if (lat is num && lon is num) {
            return Marker(
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
            );
          }
          return null;
        })
        .whereType<Marker>()
        .toList();
  }

  void _applySelectedRoute(int index, {bool shouldNotify = true}) {
    if (index < 0 || index >= searchedRoutes.length) return;

    selectedRoute = searchedRoutes[index];
    selectedRoutePoints = _extractRoutePoints(
      selectedRoute?['linestring_geojson'],
    );
    final stops = (selectedRoute?['stops'] as List?) ?? [];
    selectedRouteMarkers = _buildMarkersFromStops(stops);

    if (shouldNotify) notifyListeners();
  }

  /// Buy ticket - returns true when a payment flow finishes successfully
  Future<bool> buyTicket(
    BuildContext context, {
    String paymentMethod = "gateway",
    int quantity = 1,
  }) async {
    if (confirmedDeparture == null || confirmedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please search for a route first")),
      );
      return false;
    }

    if (currentRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please search for a route first")),
      );
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    final userStr = prefs.getString('user');
    if (jwt == null || userStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in again to buy a ticket.")),
      );
      return false;
    }

    final user = jsonDecode(userStr);
    final userId = user['id'];

    try {
      final normalizedMethod = paymentMethod.toLowerCase() == 'wallet'
          ? 'wallet'
          : 'gateway';
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ticket/buy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'user_id': userId,
          'route_id': currentRouteId,
          'bus_name': currentBusName ?? "Swift Bus",
          'start_destination': confirmedDeparture,
          'end_destination': confirmedDestination,
          'payment_method': normalizedMethod,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Processing ticket request... Please wait for confirmation.",
            ),
          ),
        );

        return await _pollTicketStatus(
          context,
          data['tracking_id'],
          normalizedMethod,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to buy ticket: ${response.body}")),
        );
        return false;
      }
    } catch (e) {
      debugPrint("Error buying ticket: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      return false;
    }
  }

  Future<bool> _pollTicketStatus(
    BuildContext context,
    String trackingId,
    String paymentMethod,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');

    int attempts = 0;
    while (attempts < 10) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final response = await http.get(
          Uri.parse(
            '${AppConstants.baseUrl}/ticket/status?tracking_id=$trackingId',
          ),
          headers: {'Authorization': 'Bearer $jwt'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final paymentUrl = (data['payment_url'] ?? '') as String;
          final downloadUrl = (data['download_url'] ?? '') as String;
          final ticketId = (data['ticket']?['id'] as num?)?.toInt();

          if (paymentUrl.isEmpty && downloadUrl.isEmpty) {
            attempts++;
            continue;
          }

          if (paymentUrl == 'failed') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ticket request failed.')),
            );
            return false;
          }

          if (paymentMethod == 'wallet') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ticket purchased with wallet.')),
            );

            // If download URL is present, open it
            if (downloadUrl.isNotEmpty) {
              downloadTicket(downloadUrl);
            }

            await fetchUserInfo();
            await fetchTickets();
            clearSearch();
            return true;
          }

          await _openGatewayCheckout(context, paymentUrl, ticketId);
          await fetchTickets();
          await fetchUserInfo();
          clearSearch();
          return true;
        }
      } catch (e) {
        debugPrint("Polling error: $e");
      }
      attempts++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Timeout waiting for payment URL. Please check 'My Tickets'.",
        ),
      ),
    );
    return false;
  }

  Future<void> _openGatewayCheckout(
    BuildContext context,
    String url,
    int? ticketId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(
          paymentUrl: url,
          ticketId: ticketId,
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment completed successfully.')),
            );
            // We can try to fetch the ticket status again to get download URL or just rely on user going to ticket list
            fetchTickets();
            fetchUserInfo();
            clearSearch();
          },
          onFailure: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment cancelled or failed.')),
            );
          },
        ),
      ),
    );
  }

  // Testing utilities
  void setBalance(double newBalance) {
    balance = newBalance;
    notifyListeners();
  }

  void setSwiftPoints(int pts) {
    swiftPoints = pts;
    notifyListeners();
  }

  Future<void> fetchTickets({
    int page = 1,
    int? limit,
    bool append = false,
  }) async {
    if (append) {
      isLoadingMoreTickets = true;
    } else {
      isLoadingTickets = true;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) {
      isLoadingTickets = false;
      isLoadingMoreTickets = false;
      hasMoreTickets = false;
      notifyListeners();
      return;
    }

    final effectiveLimit = limit ?? ticketLimit;

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/ticket').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': effectiveLimit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data is Map<String, dynamic>
            ? List.from(data['data'] ?? [])
            : (data != null ? List.from(data) : <dynamic>[]);

        if (append) {
          tickets.addAll(items);
        } else {
          tickets = items;
        }

        totalTickets = (data is Map<String, dynamic>)
            ? (data['total'] as int? ?? tickets.length)
            : tickets.length;
        ticketPage = page;
        ticketLimit = effectiveLimit;
        hasMoreTickets = tickets.length < totalTickets;
      } else {
        debugPrint("Failed to fetch tickets: ${response.statusCode}");
        hasMoreTickets = false;
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
    } finally {
      isLoadingTickets = false;
      isLoadingMoreTickets = false;
      notifyListeners();
    }
  }

  Future<List<String>> searchStops(String query) async {
    if (query.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt'); // Optional if search is public

    try {
      final uri = Uri.parse(
        '${AppConstants.baseUrl}/route/stops',
      ).replace(queryParameters: {'q': query});
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null) 'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint("Error searching stops: $e");
    }
    return [];
  }

  Future<void> searchRoutesByName(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      searchedRoutes = [];
      selectedRoute = null;
      selectedRoutePoints = [];
      selectedRouteMarkers = [];
      notifyListeners();
      return;
    }

    isSearchingRoutes = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${AppConstants.baseUrl}/route/search',
      ).replace(queryParameters: {'name': trimmed});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> routes = [];
        if (data is List) {
          routes = data.whereType<Map<String, dynamic>>().toList();
        } else if (data is Map<String, dynamic>) {
          final items = data['data'];
          if (items is List) {
            routes = items.whereType<Map<String, dynamic>>().toList();
          }
        }

        searchedRoutes = routes;
        if (routes.isNotEmpty) {
          _applySelectedRoute(0, shouldNotify: false);
        } else {
          selectedRoute = null;
          selectedRoutePoints = [];
          selectedRouteMarkers = [];
        }
      } else {
        debugPrint(
          'Failed to search routes by name: ${response.statusCode} ${response.body}',
        );
        searchedRoutes = [];
        selectedRoute = null;
        selectedRoutePoints = [];
        selectedRouteMarkers = [];
      }
    } catch (e) {
      debugPrint('Error searching routes by name: $e');
      searchedRoutes = [];
      selectedRoute = null;
      selectedRoutePoints = [];
      selectedRouteMarkers = [];
    } finally {
      isSearchingRoutes = false;
      notifyListeners();
    }
  }

  void selectSearchedRoute(int index) {
    _applySelectedRoute(index);
  }

  Future<bool> downloadTicket(String url) async {
    if (url.isEmpty) {
      debugPrint("Download URL is empty");
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      debugPrint("Invalid download URL: $url");
      return false;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint("Could not launch $url");
        return false;
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      return false;
    }
  }

  Future<bool> cancelTicket(int ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ticket/cancel/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        await fetchTickets(page: 1, append: false);
        await fetchUserInfo();
        return true;
      }
    } catch (e) {
      debugPrint('Error cancelling ticket: $e');
    }
    return false;
  }
}
