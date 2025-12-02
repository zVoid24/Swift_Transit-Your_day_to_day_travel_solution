import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/colors.dart';

import '../../providers/dashboard_provider.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

// Primary color per your design
const double _kCorner = 16.0;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable content
            _DashboardContent(),
            // Fixed ad bar + bottom nav are placed at bottom using Positioned
            Positioned(
              left: 0,
              right: 0,
              bottom: 72, // room for bottom nav
              child: _FixedAdBar(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _AppBottomNav(),
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
    // Provide bottom padding so last list item isn't hidden behind ad/nav
    return Padding(
      padding: const EdgeInsets.only(bottom: 144.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
              child: _PreviousTripsSection(hasPrevious: false), // static: no previous trips
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Placeholder logo circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'B',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hey, Good Morning!',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Welcome to Swift Transit!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
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
          child: const Icon(Icons.notifications_none, color: Colors.black54),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCorner),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Balance', style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 6),
                    Text('BDT 0', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text('Top Up', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.bolt, size: 20, color: Colors.amber),
              SizedBox(width: 8),
              Text('Swift points', style: TextStyle(color: Colors.black54)),
              SizedBox(width: 8),
              Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCorner),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
    );
  }
}

class _ServiceSelector extends StatelessWidget {
  const _ServiceSelector({Key? key}) : super(key: key);

  Widget _tile(String label, IconData icon) {
    return Expanded(
      child: Container(
        height: 88,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile('Find Bus', Icons.directions_bus),
        _tile('Scan QR', Icons.qr_code),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('My Ticket', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented control (custom)
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
                        border: selected ? Border.all(color: Colors.grey.shade200) : null,
                      ),
                      child: Center(
                        child: Text(
                          tabs[i],
                          style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Static content based on selected tab
          if (_selected == 0) ..._sampleTicketsAll(),
          if (_selected == 1) ..._sampleTicketsPrevious(),
          if (_selected == 2) ..._sampleTicketsCancelled(),
        ],
      ),
    );
  }

  List<Widget> _sampleTicketsAll() => [
        const SizedBox(height: 12),
        _TicketRow(title: 'Dhaka → Chittagong', subtitle: '25 Nov • 09:00 AM', status: 'Upcoming'),
        const SizedBox(height: 8),
        _TicketRow(title: 'Sylhet → Dhaka', subtitle: '10 Nov • 02:30 PM', status: 'Completed'),
      ];

  List<Widget> _sampleTicketsPrevious() => [
        const SizedBox(height: 12),
        _TicketRow(title: 'Sylhet → Dhaka', subtitle: '10 Nov • 02:30 PM', status: 'Completed'),
      ];

  List<Widget> _sampleTicketsCancelled() => [
        const SizedBox(height: 12),
        _TicketRow(title: 'Comilla → Dhaka', subtitle: '01 Oct • 08:00 AM', status: 'Cancelled'),
      ];
}

class _TicketRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;

  const _TicketRow({required this.title, required this.subtitle, required this.status, Key? key}) : super(key: key);

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
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.airport_shuttle, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: pillColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(color: pillColor, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _PreviousTripsSection extends StatelessWidget {
  final bool hasPrevious;
  const _PreviousTripsSection({Key? key, required this.hasPrevious}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Previous Trips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        if (hasPrevious)
          Column(children: [
            _TripCard(from: 'Dhaka', to: 'Sylhet', time: '08:00 AM • 12 Oct'),
            const SizedBox(height: 8),
            _TripCard(from: 'Dhaka', to: 'Comilla', time: '02:00 PM • 05 Sep'),
          ])
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

  const _TripCard({required this.from, required this.to, required this.time, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))]),
      child: Row(children: [
        Icon(Icons.place, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$from → $to', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text(time, style: TextStyle(color: Colors.black54, fontSize: 12))])),
        ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Rebook'))
      ]),
    );
  }
}

class _SuggestedTrip extends StatelessWidget {
  const _SuggestedTrip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))]),
      child: Row(children: [
        Icon(Icons.lightbulb, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Suggested Trip', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Dhaka → Chittagong • 09:00 AM — 12:30 PM', style: TextStyle(color: Colors.black54, fontSize: 12))])),
        ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Book'))
      ]),
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
          gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.95), AppColors.primary.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.local_offer, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Sponsored — 20% off intercity trips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            TextButton(onPressed: () {}, child: Text('Learn', style: TextStyle(color: Colors.white))),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // subtle divider
          Container(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(icon: Icons.home, label: 'Home', active: true),
                _NavItem(icon: Icons.search, label: 'Search', active: false),
                _NavItem(icon: Icons.confirmation_num, label: 'My Ticket', active: false),
                _NavItem(icon: Icons.person, label: 'Account', active: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavItem({required this.icon, required this.label, required this.active, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? AppColors.primary : Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? AppColors.primary : Colors.grey.shade400, fontSize: 12)),
      ],
    );
  }
}
