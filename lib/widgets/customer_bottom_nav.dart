import 'package:flutter/material.dart';

/// Shared navigation for customer-facing Campus Supply screens.
class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({super.key});

  static const _ink = Color(0xFF172554);
  static const _blue = Color(0xFF2563EB);
  static const _border = Color(0xFFE2E8F0);
  static const _softBlue = Color(0xFFEAF2FF);

  static const _routes = <String>[
    '/home',
    '/shop',
    '/cart',
    '/wishlist',
    '/profile',
  ];

  int _selectedIndex(String? routeName) {
    switch (routeName) {
      case '/home':
        return 0;
      case '/shop':
      case '/bundles':
      case '/product':
      case '/product-detail':
        return 1;
      case '/cart':
      case '/checkout':
        return 2;
      case '/wishlist':
        return 3;
      case '/profile':
      case '/orders':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name;
    final selectedIndex = _selectedIndex(routeName);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A172554),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: _softBlue,
          elevation: 0,
          selectedIndex: selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (routeName == _routes[index]) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              _routes[index],
              (route) => false,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: _ink),
              selectedIcon: Icon(Icons.home_rounded, color: _blue),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, color: _ink),
              selectedIcon: Icon(Icons.grid_view_rounded, color: _blue),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined, color: _ink),
              selectedIcon: Icon(Icons.shopping_cart_rounded, color: _blue),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded, color: _ink),
              selectedIcon: Icon(Icons.favorite_rounded, color: _blue),
              label: 'Wishlist',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: _ink),
              selectedIcon: Icon(Icons.person_rounded, color: _blue),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
