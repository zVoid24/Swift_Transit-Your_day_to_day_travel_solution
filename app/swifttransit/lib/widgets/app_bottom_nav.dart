import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../core/colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: Colors.grey[300]!,
            hoverColor: Colors.grey[100]!,
            gap: 8,
            activeColor: AppColors.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: AppColors.primary.withOpacity(0.1),
            color: Colors.grey[600],
            tabs: const [
              GButton(icon: Icons.home_rounded, text: 'Home'),
              GButton(icon: Icons.search_rounded, text: 'Search'),
              GButton(
                icon: Icons.confirmation_number_rounded,
                text: 'My Ticket',
              ),
              GButton(icon: Icons.person_rounded, text: 'Account'),
            ],
            selectedIndex: currentIndex,
            onTabChange: onItemSelected,
          ),
        ),
      ),
    );
  }
}
