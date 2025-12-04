import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../providers/dashboard_provider.dart';
import '../../core/colors.dart';

class BuyTicketScreen extends StatefulWidget {
  const BuyTicketScreen({super.key});

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<String> _departureSuggestions = [];
  List<String> _destinationSuggestions = [];
  bool _showDepartureSuggestions = false;
  bool _showDestinationSuggestions = false;

  @override
  void initState() {
    super.initState();
  }

  void _onSearchChanged(String query, bool isDeparture) async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final suggestions = await provider.searchStops(query);

    if (!mounted) return;

    setState(() {
      if (isDeparture) {
        _departureSuggestions = suggestions;
        _showDepartureSuggestions = suggestions.isNotEmpty;
        _showDestinationSuggestions = false;
      } else {
        _destinationSuggestions = suggestions;
        _showDestinationSuggestions = suggestions.isNotEmpty;
        _showDepartureSuggestions = false;
      }
    });
  }

  void _selectSuggestion(String suggestion, bool isDeparture) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    setState(() {
      if (isDeparture) {
        _departureController.text = suggestion;
        provider.setDeparture(suggestion);
        _showDepartureSuggestions = false;
      } else {
        _destinationController.text = suggestion;
        provider.setDestination(suggestion);
        _showDestinationSuggestions = false;
      }
    });
  }

  void _zoomToRoute(List<LatLng> points) {
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(23.8103, 90.4125), // Dhaka
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.swifttransit',
              ),
              PolylineLayer(
                polylines: [
                  if (provider.routePoints.isNotEmpty)
                    Polyline(
                      points: provider.routePoints,
                      strokeWidth: 4.0,
                      color: AppColors.primary,
                    ),
                ],
              ),
              MarkerLayer(markers: provider.markers),
            ],
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.2,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Where do you want to go?",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Departure Input
                    _buildInput(
                      controller: _departureController,
                      hint: "From (e.g. Gulistan)",
                      icon: Icons.location_on_outlined,
                      onChanged: (val) => _onSearchChanged(val, true),
                    ),
                    if (_showDepartureSuggestions)
                      _buildSuggestionsList(_departureSuggestions, true),

                    const SizedBox(height: 16),

                    // Destination Input
                    _buildInput(
                      controller: _destinationController,
                      hint: "To (e.g. Savar)",
                      icon: Icons.location_on,
                      onChanged: (val) => _onSearchChanged(val, false),
                    ),
                    if (_showDestinationSuggestions)
                      _buildSuggestionsList(_destinationSuggestions, false),

                    const SizedBox(height: 24),

                    // Search Button
                    if (provider.currentRouteId == null)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            await provider.searchBus();
                            if (provider.routePoints.isNotEmpty) {
                              _zoomToRoute(provider.routePoints);
                            }
                          },
                          child: Text(
                            "Search Route",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Bus Selection & Payment Cards
                    if (provider.currentRouteId != null ||
                        provider.availableBuses.isNotEmpty)
                      _buildSelectionCards(context, provider),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(List<String> suggestions, bool isDeparture) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(
              suggestions[index],
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            onTap: () => _selectSuggestion(suggestions[index], isDeparture),
          );
        },
      ),
    );
  }

  Widget _buildSelectionCards(
    BuildContext context,
    DashboardProvider provider,
  ) {
    final buses = provider.availableBuses;
    final fareText = provider.currentFare != null
        ? "৳${provider.currentFare!.toStringAsFixed(0)}"
        : "৳--";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (buses.isNotEmpty) ...[
          Text(
            "Available buses (${buses.length})",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: buses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bus = buses[index];
              final stops = (bus['stops'] as List?)
                      ?.whereType<Map<String, dynamic>>()
                      .toList() ??
                  [];
              final startName = stops.isNotEmpty
                  ? (stops.first['name']?.toString() ?? '')
                  : provider.selectedDeparture ?? '';
              final endName = stops.length > 1
                  ? (stops.last['name']?.toString() ?? '')
                  : provider.selectedDestination ?? '';
              final fare = bus['fare'];
              final fareDisplay = fare is num
                  ? "৳${fare.toStringAsFixed(0)}"
                  : (fare != null ? "৳$fare" : "৳--");
              final isSelected = provider.selectedBusIndex == index;

              return InkWell(
                onTap: () {
                  provider.selectBus(index);
                  if (provider.routePoints.isNotEmpty) {
                    _zoomToRoute(provider.routePoints);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedBus01,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    bus['name']?.toString() ?? 'Swift Bus',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isSelected
                                            ? AppColors.primary
                                            : Colors.green)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isSelected ? "Selected" : "Available",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "$startName → $endName",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to view this route on the map and continue",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fareDisplay,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ] else ...[
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No buses found for this route yet. Try adjusting the stops and search again.",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 12),

        // Card 2: Pay Online
        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => provider.buyTicket(context, paymentMethod: "gateway"),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Pay Online ($fareText)",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Card 3: Pay via Swift Balance
        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => provider.buyTicket(context, paymentMethod: "wallet"),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Pay via Swift Balance ($fareText)",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
