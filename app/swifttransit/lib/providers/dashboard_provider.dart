// lib/providers/dashboard_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    this.initialBalance = 0.0,
    this.initialPoints = 0,
  }) {
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

  // Dynamic data
  String userName = "User";
  double balance = 0.0;
  int swiftPoints = 0;

  // Map & routing
  List<LatLng> routePoints = [];
  List<Marker> markers = [];
  int? currentRouteId;

  // flags
  bool _isRefreshing = false;
  bool _isRecharging = false;

  bool get isRefreshing => _isRefreshing;
  bool get isRecharging => _isRecharging;

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
    notifyListeners();
  }

  void setDestination(String? value) {
    selectedDestination = value;
    notifyListeners();
  }

  /// Fetch user info (name, balance, maybe points) from server and update local fields.
  /// Keeps the original behavior but also updates swiftPoints if present.
  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/user/info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Keep previous behavior: update name & balance
        if (data['name'] != null) userName = data['name'];
        if (data['balance'] != null) {
          balance = (data['balance'] as num).toDouble();
        }
        // If API returns points, use it
        if (data['swift_points'] != null) {
          try {
            swiftPoints = (data['swift_points'] as num).toInt();
          } catch (_) {}
        }

        notifyListeners();
      } else {
        // non-200: do not overwrite fields, but log optionally
        debugPrint('fetchUserInfo failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint("Error fetching user info: $e");
    }
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

  /// Simulate a recharge operation that adds [amount] to balance.
  /// In a real app you'd integrate payment gateway and then call fetchUserInfo on success.
  Future<bool> recharge(int amount) async {
    if (_isRecharging) return false;
    _isRecharging = true;
    notifyListeners();

    try {
      // Simulate processing time or call recharge API here
      await Future.delayed(const Duration(seconds: 1));

      // For demo: increment balance locally (replace with API response)
      balance += amount.toDouble();

      // Optionally update swift points
      // swiftPoints += (amount ~/ 100);

      _isRecharging = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isRecharging = false;
      notifyListeners();
      debugPrint('recharge error: $e');
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

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/bus/get'),
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
          routePoints = [];
          markers = [];
          currentRouteId = null;
          notifyListeners();
          return;
        }

        final bus = data[0]; // Take the first bus for now
        currentRouteId = bus['id'];
        final geometry = bus['linestring_geojson']; // GeoJSON string
        final stops = bus['stops'] as List;

        // Parse GeoJSON LineString
        List<dynamic> coordinates = [];
        if (geometry is String) {
          final geoJson = jsonDecode(geometry);
          coordinates = geoJson['coordinates'];
        } else {
          coordinates = geometry['coordinates'];
        }

        routePoints = coordinates.map<LatLng>((coord) {
          return LatLng(
            coord[1],
            coord[0],
          ); // GeoJSON is [lon, lat], LatLng is [lat, lon]
        }).toList();

        // Parse Stops
        markers = stops.map<Marker>((stop) {
          return Marker(
            point: LatLng(stop['lat'], stop['lon']),
            width: 40,
            height: 40,
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          );
        }).toList();

        notifyListeners();
      } else {
        debugPrint("Bus not found: ${response.body}");
        // Clear map if route not found
        routePoints = [];
        markers = [];
        currentRouteId = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error searching bus: $e");
    }
  }

  /// Buy ticket - unchanged but kept here for completeness
  Future<void> buyTicket(BuildContext context) async {
    if (selectedDeparture == null || selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select departure and destination"),
        ),
      );
      return;
    }

    if (currentRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please search for a route first")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    final userStr = prefs.getString('user');
    if (jwt == null || userStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in again to buy a ticket."),
        ),
      );
      return;
    }

    final user = jsonDecode(userStr);
    final userId = user['id'];

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ticket/buy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'user_id': userId,
          'route_id': currentRouteId,
          'bus_name': "Swift Bus", // Default for now
          'start_destination': selectedDeparture,
          'end_destination': selectedDestination,
          'payment_method': "gateway",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['payment_url'];

        // Wait for payment URL if it's processing
        if (paymentUrl == "" || paymentUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Processing ticket request... Please wait or check status later.",
              ),
            ),
          );
          _pollTicketStatus(context, data['tracking_id']);
        } else {
          _launchPaymentUrl(paymentUrl);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to buy ticket: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("Error buying ticket: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _pollTicketStatus(
    BuildContext context,
    String trackingId,
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
          if (data['payment_url'] != null && data['payment_url'] != "") {
            _launchPaymentUrl(data['payment_url']);
            return;
          }
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
  }

  Future<void> _launchPaymentUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
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
}
