import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const forest = Color(0xFF0B2E20), dark = Color(0xFF124D36), emerald = Color(0xFF1F7A5A), mint = Color(0xFFA7D7C5), gold = Color(0xFFD8B76A), taupe = Color(0xFF8A7B68), sage = Color(0xFF5F8F7A), espresso = Color(0xFF2A211B);

  @override
  Widget build(BuildContext context) {
    final products = [
      (Icons.backpack_rounded, 'Campus Pro Backpack', '₹1,499', const Color(0xFFD38F62)),
      (Icons.headphones_rounded, 'Wireless Headphones', '₹1,299', const Color(0xFF83B8D8)),
      (Icons.menu_book_rounded, 'Premium Notebook', '₹149', const Color(0xFFD6B26E)),
      (Icons.water_drop_rounded, 'Steel Bottle', '₹699', const Color(0xFFB7D88B)),
    ];

    return Scaffold(
      backgroundColor: forest,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            Row(
              children: [
                const CampusLogo(size: 46),
                const SizedBox(width: 10),
                const Expanded(child: Text('CAMPUS\nSUPPLY', style: TextStyle(color: mint, fontWeight: FontWeight.w900, fontSize: 18, height: .9, letterSpacing: 1))),
                IconButton(onPressed: () => Navigator.pushNamed(context, '/profile'), icon: const Icon(Icons.person_outline_rounded, color: gold)),
                IconButton(onPressed: () => Navigator.pushNamed(context, '/wishlist'), icon: const Icon(Icons.favorite_border_rounded, color: gold)),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [dark, emerald, sage]), borderRadius: BorderRadius.circular(30), border: Border.all(color: gold.withValues(alpha: .6))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gear Up\nFor Success', style: TextStyle(color: mint, fontSize: 30, height: 1.0, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Everything you need for a smarter campus life.', style: TextStyle(color: Color(0xFFD8C9A7), height: 1.4)),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/product'), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Shop Now')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _title('Shop by Category', 'View All'),
            SizedBox(
              height: 98,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _category(Icons.menu_book_rounded, 'Books', const Color(0xFFD6B26E)),
                  _category(Icons.edit_rounded, 'Stationery', const Color(0xFFB7D88B)),
                  _category(Icons.devices_rounded, 'Electronics', const Color(0xFF83B8D8)),
                  _category(Icons.backpack_rounded, 'Bags', const Color(0xFFD38F62)),
                  _category(Icons.science_rounded, 'Lab', const Color(0xFFC894C6)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _title('Featured Products', 'View All'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .78),
              itemBuilder: (_, i) {
                final p = products[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/product'),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(22), border: Border.all(color: sage.withValues(alpha: .4))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [forest, Color.lerp(espresso, p.$4, .45)!]),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Center(child: Icon(p.$1, color: p.$4, size: 62)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(p.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mint, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(p.$3, style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(22), border: Border.all(color: gold.withValues(alpha: .55))),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, color: gold),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Store management', style: TextStyle(color: mint, fontWeight: FontWeight.w800))),
                  TextButton(onPressed: () => Navigator.pushNamed(context, '/admin'), child: const Text('Admin')),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: espresso,
        selectedIndex: 0,
        indicatorColor: dark,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(color: mint, fontSize: 10)),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: sage), selectedIcon: Icon(Icons.home_rounded, color: mint), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded, color: sage), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.favorite_border_rounded, color: sage), label: 'Wishlist'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded, color: sage), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 2) Navigator.pushNamed(context, '/wishlist');
          if (i == 3) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _title(String a, String b) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: Text(a, style: const TextStyle(color: mint, fontSize: 18, fontWeight: FontWeight.w900))), Text(b, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w800))]));
  Widget _category(IconData icon, String label, Color color) => Container(width: 90, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 7), Text(label, style: const TextStyle(color: mint, fontSize: 10, fontWeight: FontWeight.w700))]));
}
