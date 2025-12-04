import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../profile/profile_screen.dart';
import '../ticket/ticket_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
        break;
      case 1:
        return;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TicketListScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DemoProfileScreen()),
        );
        break;
    }
  }

  Future<void> _performSearch(DashboardProvider provider) async {
    await provider.searchRoutesByName(_controller.text);
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Routes'),
        backgroundColor: Colors.white,
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final routes = provider.searchedRoutes;
          final selectedRoute = provider.selectedRoute;
          final markers = provider.selectedRouteMarkers;
          final points = provider.selectedRoutePoints;
          final stops = (selectedRoute?['stops'] as List?) ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Search by bus or route name',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  provider.searchRoutesByName('');
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _performSearch(provider),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _performSearch(provider),
                        icon: const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Show Route',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (provider.isSearchingRoutes == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: routes.isEmpty
                    ? Center(
                        child: Text(
                          provider.isSearchingRoutes
                              ? 'Searching routes...'
                              : 'Start typing a bus or route name to see its path.',
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (selectedRoute != null)
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.grey.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.12),
                                          child: const Icon(
                                            Icons.directions_bus,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedRoute['name'] ??
                                                    'Route',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '${stops.length} stoppage(s)',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildStatusChip(
                                          'Preview',
                                          AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: stops
                                          .map<Widget>(
                                            (stop) => Chip(
                                              backgroundColor: AppColors.primary
                                                  .withOpacity(0.08),
                                              label: Text(
                                                stop['name']?.toString() ?? '',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(
                            height: 280,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: points.isNotEmpty
                                      ? points.first
                                      : const LatLng(23.8103, 90.4125),
                                  initialZoom: points.isNotEmpty ? 13 : 11,
                                  interactionOptions: const InteractionOptions(
                                    flags:
                                        InteractiveFlag.pinchZoom |
                                        InteractiveFlag.drag |
                                        InteractiveFlag.doubleTapZoom,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',

                                    userAgentPackageName:
                                        'com.example.swifttransit',
                                  ),
                                  if (points.isNotEmpty)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: points,
                                          strokeWidth: 5,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  if (markers.isNotEmpty)
                                    MarkerLayer(markers: markers),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Matching Routes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ...routes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final route = entry.value;
                            final routeStops = (route['stops'] as List?) ?? [];
                            final isSelected =
                                provider.selectedRoute != null &&
                                provider.selectedRoute == route;
                            return GestureDetector(
                              onTap: () => provider.selectSearchedRoute(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.route,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            route['name']?.toString() ??
                                                'Unnamed Route',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${routeStops.length} stoppage(s)',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNav == true
          ? AppBottomNav(currentIndex: 1, onItemSelected: _onNavTap)
          : null,
    );
  }
}
