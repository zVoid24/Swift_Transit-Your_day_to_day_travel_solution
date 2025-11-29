import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  int selectedIndex = 0;

  String? selectedDeparture;
  String? selectedDestination;

  // Example dynamic data (API-ready structure)
  String userName = "Toha Siddique";
  double balance = 1200;

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
}
