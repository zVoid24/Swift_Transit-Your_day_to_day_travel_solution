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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingTickets && provider.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.tickets.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.tickets.length) {
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

                final ticket = provider.tickets[index];
                if (ticket is! Map<String, dynamic>)
                  return const SizedBox.shrink();

                final status = ticket['paid_status'] == true
                    ? (ticket['checked'] == true ? 'Completed' : 'Upcoming')
                    : 'Unpaid';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticket: ticket),
                        ),
                      );
                    },
                    title: Text(
                      '${ticket['start_destination']} → ${ticket['end_destination']}',
                    ),
                    subtitle: Text(
                      '${ticket['created_at']} • ৳${ticket['fare']}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status),
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
