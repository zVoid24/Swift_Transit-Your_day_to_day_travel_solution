import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:swifttransit/core/colors.dart';
import 'package:swifttransit/features/dashboard/application/dashboard_provider.dart';

class BuyTicketScreen extends StatefulWidget {
  const BuyTicketScreen({super.key});

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  int _ticketQuantity = 1;

  List<String> _departureSuggestions = [];
  List<String> _destinationSuggestions = [];
  bool _showDepartureSuggestions = false;
  bool _showDestinationSuggestions = false;

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Restore state from provider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      if (provider.selectedDeparture != null) {
        _departureController.text = provider.selectedDeparture!;
        _showDepartureSuggestions = false;
      }
      if (provider.selectedDestination != null) {
        _destinationController.text = provider.selectedDestination!;
        _showDestinationSuggestions = false;
      }
      if (provider.routePoints.isNotEmpty) {
        _zoomToRoute(provider.routePoints);
      }
    });
  }

  void _onSearchChanged(String query, bool isDeparture) async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    // Update provider state and clear results
    if (isDeparture) {
      provider.setDeparture(query);
    } else {
      provider.setDestination(query);
    }

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

  Future<bool> _confirmWalletPayment(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Pay with Swift Balance?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Are you sure you want to use your Swift balance for this ticket?',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 14),
              Text(
                'Processing payment...',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWalletSuccess(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment Successful',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Your ticket has been paid using Swift balance.',
          style: GoogleFonts.poppins(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Done',
              style: GoogleFonts.poppins(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (provider.selectedBusIndex != null) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                "Save Search?",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "Do you want to keep your current search and selection?",
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "No",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    "Yes",
                    style: GoogleFonts.poppins(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          );

          if (shouldSave == false) {
            provider.clearSearch();
          }
        } else {
          provider.clearSearch();
        }

        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.swifttransit',
                ),
                PolylineLayer(
                  polylines: [
                    if (provider.routePoints.isNotEmpty) ...[
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
                  onPressed: () => Navigator.maybePop(context),
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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

                      if (provider.currentRouteId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: () {
                                provider.clearSearch();
                                _departureController.clear();
                                _destinationController.clear();
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(color: AppColors.primary),
                              ),
                              child: Text(
                                "Search Again",
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
    final baseFare = provider.currentFare;
    final totalFare = baseFare != null ? baseFare * _ticketQuantity : null;
    final fareText = totalFare != null
        ? "৳${totalFare.toStringAsFixed(0)} (x$_ticketQuantity)"
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
              final stops =
                  (bus['stops'] as List?)
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
              String fareDisplay = "৳--";
              if (fare is num) {
                fareDisplay = "৳$fare";
              } else if (fare != null) {
                final parsed = double.tryParse(fare.toString());
                if (parsed != null) {
                  fareDisplay = "৳$parsed";
                } else {
                  fareDisplay = "৳$fare";
                }
              }
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
                                    color:
                                        (isSelected
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

        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Number of tickets",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: _ticketQuantity > 1
                          ? () => setState(() => _ticketQuantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_ticketQuantity',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _ticketQuantity < 4
                          ? () => setState(() => _ticketQuantity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    Text(
                      'Max 4 per route',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Card 2: Pay Online
        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
              final success = await provider.buyTicket(
                context,
                paymentMethod: "gateway",
                quantity: _ticketQuantity,
              );
              if (success && mounted) {
                _departureController.clear();
                _destinationController.clear();
                setState(() {
                  _showDepartureSuggestions = false;
                  _showDestinationSuggestions = false;
                  _ticketQuantity = 1;
                });
              }
            },
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
                  Expanded(
                    child: Text(
                      "Pay Online ($fareText)",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
            onTap: () async {
              final confirmed = await _confirmWalletPayment(context);
              if (!confirmed) return;

              _showLoadingDialog(context);
              final success = await provider.buyTicket(
                context,
                paymentMethod: "wallet",
                quantity: _ticketQuantity,
              );

              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop();

              if (success && context.mounted) {
                _departureController.clear();
                _destinationController.clear();
                setState(() {
                  _showDepartureSuggestions = false;
                  _showDestinationSuggestions = false;
                  _ticketQuantity = 1;
                });
                await _showWalletSuccess(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment could not be completed. Try again.'),
                  ),
                );
              }
            },
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
                  Expanded(
                    child: Text(
                      "Pay via Swift Balance ($fareText)",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
