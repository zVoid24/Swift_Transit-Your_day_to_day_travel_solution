import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';

class DashboardProvider extends ChangeNotifier {
  int selectedIndex = 0;

  String? selectedDeparture;
  String? selectedDestination;

  // Dynamic data
  String userName = "User";
  double balance = 0.0;
  List<LatLng> routePoints = [];
  List<Marker> markers = [];
  int? currentRouteId;

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
        userName = data['name'];
        balance = (data['balance'] as num).toDouble();
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching user info: $e");
    }
  }

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
          print("No bus found");
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
        print("Bus not found: ${response.body}");
        // Clear map if route not found
        routePoints = [];
        markers = [];
        currentRouteId = null;
        notifyListeners();
      }
    } catch (e) {
      print("Error searching bus: $e");
    }
  }

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
      print("Error buying ticket: $e");
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
        print("Polling error: $e");
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
}
