import 'package:flutter/material.dart';
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
    final items = const [
      _NavItemData(Icons.home, 'Home'),
      _NavItemData(Icons.search, 'Search'),
      _NavItemData(Icons.confirmation_num, 'My Ticket'),
      _NavItemData(Icons.person, 'Account'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final active = index == currentIndex;
                final item = items[index];
                return GestureDetector(
                  onTap: () => onItemSelected(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon,
                          color: active ? AppColors.primary : Colors.grey.shade400),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color:
                              active ? AppColors.primary : Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData(this.icon, this.label);
}
