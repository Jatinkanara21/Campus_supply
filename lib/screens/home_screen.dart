import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFACC15);
  static const coral = Color(0xFFF97368);
  static const white = Colors.white;
  static const softBlue = Color(0xFFEAF2FF);
  static const softYellow = Color(0xFFFFF7CC);
  static const softCoral = Color(0xFFFFE9E6);

  @override
  Widget build(BuildContext context) {
    final categories = [
      (Icons.edit_rounded, 'Pens & Pencils', softBlue, blue),
      (Icons.menu_book_rounded, 'Sketchbooks', softYellow, const Color(0xFFB88900)),
      (Icons.palette_rounded, 'Art Supplies', softCoral, coral),
      (Icons.straighten_rounded, 'Drafting Tools', const Color(0xFFE8F7F0), const Color(0xFF198754)),
      (Icons.book_rounded, 'Notebooks', const Color(0xFFF2ECFF), const Color(0xFF7C4DFF)),
      (Icons.devices_rounded, 'Tech Accessories', const Color(0xFFEAF7F8), const Color(0xFF087F8C)),
    ];

    final products = [
      (Icons.edit_rounded, 'Smooth Gel Pens', '₹149', '4.8', blue),
      (Icons.menu_book_rounded, 'A5 Premium Sketchbook', '₹349', '4.9', const Color(0xFF7C4DFF)),
      (Icons.straighten_rounded, 'Campus Drafting Set', '₹499', '4.7', coral),
      (Icons.palette_rounded, 'Studio Marker Pack', '₹599', '4.8', const Color(0xFF198754)),
    ];

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
          children: [
            Row(
              children: [
                const CampusLogo(size: 44),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Campus Supply',
                    style: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.7),
                  ),
                ),
                _iconButton(Icons.favorite_border_rounded, () => Navigator.pushNamed(context, '/wishlist')),
                const SizedBox(width: 8),
                _iconButton(Icons.shopping_bag_outlined, () => Navigator.pushNamed(context, '/product')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7E2D9)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6E7480)),
                  hintText: 'Search stationery, art supplies, tech...',
                  hintStyle: TextStyle(color: Color(0xFF8A8F99), fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [blue, Color(0xFF4B83F4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Back to', style: TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Campus Deals', style: TextStyle(color: white, fontSize: 30, height: .98, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        SizedBox(height: 10),
                        Text('Create more. Spend less.', style: TextStyle(color: Color(0xFFE9F1FF), fontSize: 13.5, height: 1.35)),
                        SizedBox(height: 16),
                        DecoratedBox(
                          decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.all(Radius.circular(14))),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            child: Text('Shop Now →', style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 92,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0x332563EB),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.backpack_rounded, color: yellow, size: 70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Shop by Category', 'See all'),
            const SizedBox(height: 12),
            SizedBox(
              height: 98,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return Container(
                    width: 102,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE7E2D9)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: c.$3, shape: BoxShape.circle),
                          child: Icon(c.$1, color: c.$4, size: 21),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          c.$2,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: ink, fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            _sectionTitle('Popular This Week', 'See all'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .72,
              ),
              itemBuilder: (_, i) {
                final p = products[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/product'),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7E2D9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3EE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                Center(child: Icon(p.$1, color: p.$5, size: 64)),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(color: white, shape: BoxShape.circle),
                                    child: Icon(Icons.favorite_border_rounded, color: ink.withValues(alpha: .8), size: 17),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(p.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800, height: 1.18)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 16),
                            const SizedBox(width: 3),
                            Text(p.$4, style: const TextStyle(color: Color(0xFF707681), fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(p.$3, style: const TextStyle(color: blue, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: softYellow,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1DD81)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: yellow, shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, color: ink),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student Budget. Sorted.', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('Show your student ID and unlock special savings on eligible essentials.', style: TextStyle(color: Color(0xFF5E5846), fontSize: 12.5, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Student Bundles', 'Explore'),
            const SizedBox(height: 12),
            _bundleCard(
              title: 'Architecture Starter Kit',
              subtitle: 'Drafting tools + sketchbook + core studio essentials.',
              price: '₹2,499',
              badge: 'Save 15%',
              icon: Icons.architecture_rounded,
              color: softBlue,
              accent: blue,
            ),
            const SizedBox(height: 12),
            _bundleCard(
              title: 'First-Year Essentials',
              subtitle: 'The practical starter pack for a busy semester.',
              price: '₹999',
              badge: 'Save 15%',
              icon: Icons.auto_stories_rounded,
              color: softCoral,
              accent: coral,
            ),
            const SizedBox(height: 24),
            _sectionTitle('What Students Say', ''),
            const SizedBox(height: 12),
            _testimonial('“Finally, a store that gets student life.”', 'Aarav • Architecture student'),
            const SizedBox(height: 10),
            _testimonial('“My stationery addiction has found a home.”', 'Maya • Design student'),
            const SizedBox(height: 10),
            _testimonial('“Less searching. More creating.”', 'Riya • Fine arts student'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: white,
        surfaceTintColor: white,
        indicatorColor: softBlue,
        selectedIndex: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: blue), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.favorite_border_rounded), label: 'Wishlist'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 3) Navigator.pushNamed(context, '/wishlist');
          if (i == 4) Navigator.pushNamed(context, '/profile');
          if (i == 2) Navigator.pushNamed(context, '/product');
        },
      ),
    );
  }

  static Widget _iconButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE7E2D9))),
          child: Icon(icon, color: ink, size: 20),
        ),
      );

  static Widget _sectionTitle(String title, String action) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4))),
          if (action.isNotEmpty) Text(action, style: const TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      );

  static Widget _bundleCard({
    required String title,
    required String subtitle,
    required String price,
    required String badge,
    required IconData icon,
    required Color color,
    required Color accent,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE7E2D9))),
        child: Row(
          children: [
            Container(width: 82, height: 92, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 45, color: accent)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: coral, borderRadius: BorderRadius.circular(10)),
                    child: Text(badge, style: const TextStyle(color: white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 7),
                  Text(title, style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF707681), fontSize: 11.5, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(price, style: const TextStyle(color: blue, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );

  static Widget _testimonial(String quote, String byline) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7E2D9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quote, style: const TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 7),
            Text(byline, style: const TextStyle(color: Color(0xFF7C828D), fontSize: 11)),
          ],
        ),
      );
}
