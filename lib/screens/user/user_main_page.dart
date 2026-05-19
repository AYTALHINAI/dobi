import 'package:flutter/material.dart';
import '../../theme/user_theme.dart';
import 'user_home_page.dart';
import 'user_orders_page.dart';
import 'user_account_page.dart';

class UserMainPage extends StatefulWidget {
  final int initialIndex;
  const UserMainPage({super.key, this.initialIndex = 0});

  @override
  State<UserMainPage> createState() => _UserMainPageState();
}

class _UserMainPageState extends State<UserMainPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Incremented every time the user taps the Home tab so that
  // _NearbyShopsSection is forced to re-fetch with the latest wilayat.
  int _homeRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    // Listen to the UserTheme notifier so BottomNavigationBar reacts
    // immediately when dark mode is toggled on the Account tab.
    final themeNotifier = UserTheme.of(context);
    final isDark = themeNotifier.isDark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          UserHomePage(key: ValueKey(_homeRefreshKey)),
          const UserOrdersPage(),
          const UserAccountPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            if (i == 0 && _currentIndex != 0) {
              // User is navigating back to Home — refresh nearby shops.
              _homeRefreshKey++;
            }
            _currentIndex = i;
          });
        },
        selectedItemColor: context.uiPrimary,
        unselectedItemColor: context.uiTextSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        backgroundColor: context.uiSurface,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            activeIcon: Icon(Icons.checkroom),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
