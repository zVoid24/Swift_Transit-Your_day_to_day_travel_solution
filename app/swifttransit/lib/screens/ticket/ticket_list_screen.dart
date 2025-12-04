import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchTickets(page: 1, append: false);
    });
  }

  Future<void> _refresh() async {
    await context.read<DashboardProvider>().fetchTickets(
          page: 1,
          append: false,
        );
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;
      case 2:
        return;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DemoProfileScreen()),
        );
        break;
    }
  }

  List<List<Map<String, dynamic>>> _groupTickets(List<dynamic> tickets) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final ticket in tickets) {
      if (ticket is! Map<String, dynamic>) continue;
      final batchId = (ticket['batch_id'] ?? ticket['id']).toString();
      grouped.putIfAbsent(batchId, () => []).add(ticket);
    }

    final groups = grouped.values.toList();
    groups.sort((a, b) {
      final latestA = _createdAtMillis(a.first);
      final latestB = _createdAtMillis(b.first);
      return latestB.compareTo(latestA);
    });
    return groups;
  }

  int _createdAtMillis(Map<String, dynamic> ticket) {
    return DateTime.tryParse(ticket['created_at']?.toString() ?? '')
            ?.millisecondsSinceEpoch ??
        0;
  }

  _TicketStatus _deriveStatus(List<Map<String, dynamic>> group) {
    if (group.any((t) => t['cancelled_at'] != null)) {
      return _TicketStatus('Cancelled', Colors.red.shade600);
    }
    if (group.any((t) => t['checked'] == true)) {
      return _TicketStatus('Checked', Colors.green.shade600);
    }
    if (group.every((t) => t['paid_status'] == true)) {
      return _TicketStatus('Upcoming', Colors.amber.shade700);
    }
    return _TicketStatus('Unpaid', Colors.grey.shade600);
  }

  Widget _statusChip(_TicketStatus status, int count) {
    final label = count > 1 ? '${status.label} • $count' : status.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingTickets && provider.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupedTickets = _groupTickets(provider.tickets);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedTickets.length + 1,
              itemBuilder: (context, index) {
                if (index == groupedTickets.length) {
                  if (!provider.hasMoreTickets) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: provider.isLoadingMoreTickets
                            ? null
                            : () => provider.fetchTickets(
                                  page: provider.ticketPage + 1,
                                  append: true,
                                ),
                        child: provider.isLoadingMoreTickets
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Load more'),
                      ),
                    ),
                  );
                }

                final group = groupedTickets[index];
                if (group.isEmpty) return const SizedBox.shrink();
                final sortedGroup = [...group]
                  ..sort((a, b) => _createdAtMillis(b).compareTo(_createdAtMillis(a)));
                final primary = sortedGroup.first;

                final status = _deriveStatus(sortedGroup);
                final start = primary['start_destination'] ?? 'Start';
                final end = primary['end_destination'] ?? 'End';
                final busName = primary['bus_name'] ?? 'Swift Bus';
                final fare = (primary['fare'] as num?)?.toDouble();
                final totalFare = fare != null ? fare * sortedGroup.length : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(
                            tickets: sortedGroup,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.alt_route, color: Colors.black87),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$start → $end',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      primary['created_at']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _statusChip(status, sortedGroup.length),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.directions_bus,
                                  color: Colors.grey.shade700, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  busName.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoPill(
                                Icons.confirmation_number,
                                '${sortedGroup.length} ticket${sortedGroup.length > 1 ? 's' : ''}',
                              ),
                              if (totalFare != null)
                                _infoPill(
                                  Icons.payments,
                                  '৳${totalFare.toStringAsFixed(0)} total',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(
              currentIndex: 2,
              onItemSelected: _onNavTap,
            )
          : null,
    );
  }
}

class _TicketStatus {
  final String label;
  final Color color;

  const _TicketStatus(this.label, this.color);
}
