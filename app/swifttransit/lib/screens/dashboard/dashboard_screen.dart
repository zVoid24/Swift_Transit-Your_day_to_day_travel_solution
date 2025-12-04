import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/colors.dart';

import '../../providers/dashboard_provider.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../ticket/buy_ticket_screen.dart';
import '../ticket/live_bus_location_screen.dart';
import '../ticket/ticket_list_screen.dart';
import '../../widgets/app_bottom_nav.dart';

const double _kCorner = 16.0;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.fetchUserInfo();
      provider.fetchTickets();
    });
  }

  void _handleBottomNav(BuildContext context, int index) {
    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TicketListScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DemoProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            _DashboardContent(),
            Positioned(left: 0, right: 0, bottom: 72, child: _FixedAdBar()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(
                currentIndex: 0,
                onItemSelected: (index) => _handleBottomNav(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 144.0),
      child: RefreshIndicator(
        onRefresh: () async {
          final dashboardProvider =
              Provider.of<DashboardProvider>(context, listen: false);
          await dashboardProvider.fetchUserInfo();
          await dashboardProvider.fetchTickets();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _TopHeader(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _BalanceCard(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _ProfileUpdateCard(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _ServiceSelector(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _MyTicketCard(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _PreviousTripsSection(
                  hasPrevious: false,
                ), // static: no previous trips
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Logo + Title row, then greeting underneath
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Bus logo box (using default Icons.bus_alert as placeholder)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  Icons.directions_bus,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swift Transit',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your everyday travel companion',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Greeting line below
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({Key? key}) : super(key: key);

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    try {
      final result = await dashboardProvider.refreshBalance();
      if (result == null || result == true) {
        _showSnack(context, 'Balance refreshed');
      } else {
        _showSnack(context, 'Failed to refresh balance');
      }
    } catch (e) {
      _showSnack(context, 'Error refreshing balance');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modern minimal card: balance left, recharge & refresh right, points below with arrow
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCorner),
        boxShadow: [
          // minimal subtle shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: balance + actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // balance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'BDT',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Consumer<DashboardProvider>(
                          builder: (context, provider, _) => Text(
                            '${provider.balance}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Recharge button (primary)
              ElevatedButton.icon(
                onPressed: () {
                  // simulate recharge flow
                  _showSnack(context, 'Recharge tapped (static)');
                },
                icon: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Recharge',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(width: 8),

              // Refresh button (round) - wired to provider
              InkWell(
                onTap: () async {
                  await _handleRefresh(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // separator line (subtle)
          Divider(height: 1, color: Colors.grey.shade100),

          const SizedBox(height: 12),

          // swift points row with tappable arrow
          InkWell(
            onTap: () {
              _showSnack(context, 'Use Swift points (static)');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  // icon + label
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Swift Points',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '0',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),

                  // arrow indicator
                  Row(
                    children: [
                      Text(
                        'Use Swift Points',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileUpdateCard extends StatelessWidget {
  const _ProfileUpdateCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _ServiceSelector extends StatelessWidget {
  const _ServiceSelector({Key? key}) : super(key: key);

  Widget _tile(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 88,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile(context, 'Buy Ticket', Icons.confirmation_number, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BuyTicketScreen()),
          );
        }),
        _tile(context, 'Track Bus', Icons.track_changes, () {
          final provider =
              Provider.of<DashboardProvider>(context, listen: false);
          final active = provider.activeTicket;

          if (active == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No active tickets to track right now.'),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveBusLocationScreen(
                routeId: (active['route_id'] as num).toInt(),
                title:
                    '${active['start_destination']} → ${active['end_destination']}',
                busName: active['bus_name'],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MyTicketCard extends StatefulWidget {
  const _MyTicketCard({Key? key}) : super(key: key);

  @override
  State<_MyTicketCard> createState() => _MyTicketCardState();
}

class _MyTicketCardState extends State<_MyTicketCard> {
  int _selected = 0; // 0: All, 1: Previous, 2: Cancel

  @override
  Widget build(BuildContext context) {
    final tabs = ['All ticket', 'Previous ticket', 'Cancel ticket'];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCorner),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
                const Expanded(
                  child: Text(
                  'My Ticket',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TicketListScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = i == _selected;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: Colors.grey.shade200)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<DashboardProvider>(
            builder: (context, provider, _) {
              if (_selected == 0)
                return Column(children: _sampleTicketsAll(provider));
              if (_selected == 1)
                return Column(children: _sampleTicketsPrevious());
              if (_selected == 2)
                return Column(children: _sampleTicketsCancelled());
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _sampleTicketsAll(DashboardProvider provider) {
    if (provider.isLoadingTickets) {
      return [const Center(child: CircularProgressIndicator())];
    }
    final dashboardTickets = provider.dashboardTickets;
    if (dashboardTickets.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text("No tickets found"),
        ),
      ];
    }
    return dashboardTickets.map((t) {
      final paid = t['paid_status'] == true;
      final checked = t['checked'] == true;
      final canTrack = paid && !checked;
      final statusLabel = canTrack ? 'Upcoming' : (paid ? 'Paid' : 'Unpaid');

      return Column(
        children: [
          const SizedBox(height: 8),
          _TicketRow(
            title: '${t['start_destination']} → ${t['end_destination']}',
            subtitle: '${t['created_at']} • ৳${t['fare']}',
            status: statusLabel,
            canTrack: canTrack,
            onTrack: canTrack
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveBusLocationScreen(
                          routeId: (t['route_id'] as num).toInt(),
                          title:
                              '${t['start_destination']} → ${t['end_destination']}',
                          busName: t['bus_name'],
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _sampleTicketsPrevious() => [
    const SizedBox(height: 12),
    _TicketRow(
      title: 'Sylhet → Dhaka',
      subtitle: '10 Nov • 02:30 PM',
      status: 'Completed',
    ),
  ];

  List<Widget> _sampleTicketsCancelled() => [
    const SizedBox(height: 12),
    _TicketRow(
      title: 'Comilla → Dhaka',
      subtitle: '01 Oct • 08:00 AM',
      status: 'Cancelled',
    ),
  ];
}

class _TicketRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTrack;
  final bool canTrack;

  const _TicketRow({
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTrack,
    this.canTrack = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color pillColor;
    switch (status.toLowerCase()) {
      case 'upcoming':
        pillColor = Colors.green.shade600;
        break;
      case 'completed':
        pillColor = Colors.blueGrey;
        break;
      case 'cancelled':
        pillColor = Colors.red.shade600;
        break;
      default:
        pillColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.airport_shuttle, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pillColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: pillColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (canTrack) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onTrack,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Track'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviousTripsSection extends StatelessWidget {
  final bool hasPrevious;
  const _PreviousTripsSection({Key? key, required this.hasPrevious})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previous Trips',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (hasPrevious)
          Column(
            children: [
              _TripCard(from: 'Dhaka', to: 'Sylhet', time: '08:00 AM • 12 Oct'),
              const SizedBox(height: 8),
              _TripCard(
                from: 'Dhaka',
                to: 'Comilla',
                time: '02:00 PM • 05 Sep',
              ),
            ],
          )
        else
          _SuggestedTrip(),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final String from;
  final String to;
  final String time;

  const _TripCard({
    required this.from,
    required this.to,
    required this.time,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.place, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Rebook'),
          ),
        ],
      ),
    );
  }
}

class _SuggestedTrip extends StatelessWidget {
  const _SuggestedTrip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Trip',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Dhaka → Chittagong • 09:00 AM — 12:30 PM',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Book', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FixedAdBar extends StatelessWidget {
  const _FixedAdBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.95),
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.local_offer, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sponsored — 20% off intercity trips',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Learn', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

