import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = Provider.of<DashboardProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(dash),
      body: _buildBody(context, dash),
      bottomNavigationBar: _buildBottomNav(context, dash),
    );
  }

  AppBar _buildAppBar(DashboardProvider dash) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      backgroundColor: const Color(0xFF014751),
      elevation: 0,
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.orange,
            radius: 20,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBus01,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "SwiftTransit",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet01,
                  color: Colors.orange,
                  size: 25,
                ),
                const SizedBox(width: 8),
                Text(
                  "৳${dash.balance.toInt()}",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF014751),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardProvider dash) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${dash.userName} 👋",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedShieldBlockchain,
                  color: Colors.orange,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    dash.quotes[1],
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildQuickCards(),

            const SizedBox(height: 24),

            _buildSearchBox(dash),

            const SizedBox(height: 24),

            _buildSuggestedTrips(dash),

            const SizedBox(height: 16),

            _buildAdsSection(dash),
          ],
        ),
      ),
    );
  }

  // ---------------- QUICK CARDS ------------------

  Widget _buildQuickCards() {
    return Row(
      children: [
        Expanded(child: _quickCard(HugeIcons.strokeRoundedCloud, "Weather")),
        const SizedBox(width: 12),
        Expanded(child: _quickCard(HugeIcons.strokeRoundedQrCode, "Scan QR")),
      ],
    );
  }

  Widget _quickCard(dynamic icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: Colors.orange, size: 30),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Color(0xFF014751),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SEARCH BOX ------------------

  Widget _buildSearchBox(DashboardProvider dash) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _dropdownTile(
                "Departure",
                dash.selectedDeparture,
                dash.setDeparture,
              ),
              const Divider(height: 1, color: Colors.grey),
              _dropdownTile(
                "Destination",
                dash.selectedDestination,
                dash.setDestination,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: Text(
              "Search Ticket",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownTile(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: HugeIcon(
        icon: label == "Departure"
            ? HugeIcons.strokeRoundedLocation01
            : HugeIcons.strokeRoundedLocation09,
        color: Colors.orange,
        size: 24,
      ),
      title: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text("Select $label"),
          value: value,
          isExpanded: true,
          items: ["Uttara", "Gulistan", "Farmgate", "Mirpur"]
              .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------------- SUGGESTED TRIPS ------------------

  Widget _buildSuggestedTrips(DashboardProvider dash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Suggested Trips",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dash.trips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final t = dash.trips[i];
              return Container(
                width: 195,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF014751),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['route']!,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      t['time']!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t['fare']!,
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- ADS SECTION ------------------

  Widget _buildAdsSection(DashboardProvider dash) {
    return SizedBox(
      height: 45,
      child: PageView.builder(
        controller: PageController(viewportFraction: .84),
        itemCount: dash.ads.length,
        itemBuilder: (_, i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: AssetImage(dash.ads[i]),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- BOTTOM NAV ------------------

  Widget _buildBottomNav(BuildContext context, DashboardProvider dash) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: dash.selectedIndex,
      selectedItemColor: const Color(0xFF014751),
      unselectedItemColor: Colors.black38,
      onTap: (i) {
        dash.updateTab(i);

        if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        }
        //if (i == 3) {
        // Navigator.push(
        //  context,
        //  MaterialPageRoute(builder: (_) => const ProfileScreen()),
        // );
        //}
      },
      items: [
        _navItem(
          HugeIcons.strokeRoundedHome01,
          "Home",
          dash.selectedIndex == 0,
        ),
        _navItem(
          HugeIcons.strokeRoundedSearch01,
          "Search",
          dash.selectedIndex == 1,
        ),
        _navItem(
          HugeIcons.strokeRoundedCreditCard,
          "Recharge",
          dash.selectedIndex == 2,
        ),
        _navItem(
          HugeIcons.strokeRoundedUserCircle,
          "Profile",
          dash.selectedIndex == 3,
        ),
      ],
    );
  }

  BottomNavigationBarItem _navItem(dynamic icon, String label, bool active) {
    return BottomNavigationBarItem(
      icon: HugeIcon(
        icon: icon,
        color: active ? const Color(0xFF014751) : Colors.black38,
        size: 24,
      ),
      label: label,
    );
  }
}
