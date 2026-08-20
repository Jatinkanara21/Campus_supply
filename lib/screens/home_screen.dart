import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const forest = Color(0xFF0B2E20);
  static const emerald = Color(0xFF1F7A5A);
  static const darkEmerald = Color(0xFF124D36);
  static const sage = Color(0xFF5F8F7A);
  static const mint = Color(0xFFA7D7C5);
  static const gold = Color(0xFFD8B76A);
  static const taupe = Color(0xFF8A7B68);
  static const espresso = Color(0xFF2A211B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _categories()),
            SliverToBoxAdapter(child: _featured()),
            SliverToBoxAdapter(child: _studentCard(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: espresso,
        elevation: 0,
        selectedIndex: 0,
        indicatorColor: darkEmerald,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: mint, fontSize: 10, fontWeight: FontWeight.w700),
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: sage), selectedIcon: Icon(Icons.home_rounded, color: mint), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined, color: sage), selectedIcon: Icon(Icons.explore_rounded, color: mint), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.favorite_border_rounded, color: sage), selectedIcon: Icon(Icons.favorite_rounded, color: gold), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded, color: sage), selectedIcon: Icon(Icons.person_rounded, color: mint), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          const CampusLogo(size: 48),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Campus Supply', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: mint)),
                Text('Everything you need. One campus store.', style: TextStyle(fontSize: 10.5, color: sage)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/login'),
            child: _roundIcon(Icons.person_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF124D36), Color(0xFF1F7A5A), Color(0xFF5F8F7A)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFD8B76A), width: 0.6),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 18, offset: Offset(0, 9))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart supplies.\nBetter campus life.', style: TextStyle(color: mint, fontSize: 29, height: 1.02, fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      Text('Books, stationery, gadgets, lab supplies and everyday essentials — all in one place.', style: TextStyle(color: Color(0xFFD8C9A7), fontSize: 12.5, height: 1.45)),
                    ],
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: forest.withValues(alpha: 0.45), shape: BoxShape.circle, border: Border.all(color: gold, width: 1)),
                  child: const Icon(Icons.school_rounded, color: gold, size: 38),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: espresso, borderRadius: BorderRadius.circular(17), border: Border.all(color: sage, width: 0.7)),
              child: const TextField(
                style: TextStyle(color: mint),
                decoration: InputDecoration(
                  hintText: 'Search books, stationery, laptops...',
                  hintStyle: TextStyle(color: taupe, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: gold),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categories() {
    final data = [
      (Icons.menu_book_rounded, 'Books', const Color(0xFFD6B26E)),
      (Icons.edit_rounded, 'Stationery', const Color(0xFFB7D88B)),
      (Icons.devices_rounded, 'Tech', const Color(0xFF83B8D8)),
      (Icons.science_rounded, 'Lab', const Color(0xFFC894C6)),
      (Icons.backpack_rounded, 'Bags', const Color(0xFFD38F62)),
    ];

    return Column(
      children: [
        _title('Explore categories', 'See all'),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return Container(
                width: 94,
                decoration: BoxDecoration(color: darkEmerald, borderRadius: BorderRadius.circular(20), border: Border.all(color: sage, width: 0.5)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: data[i].$3.withValues(alpha: 0.19), borderRadius: BorderRadius.circular(14)),
                      child: Icon(data[i].$1, color: data[i].$3, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(data[i].$2, style: const TextStyle(color: mint, fontWeight: FontWeight.w700, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 27),
      ],
    );
  }

  Widget _featured() {
    return Column(
      children: [
        _title('Featured products', 'View all'),
        SizedBox(
          height: 252,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _card(Icons.menu_book_rounded, 'Study Essentials', 'Books & study guides', 'BESTSELLER', const Color(0xFFD6B26E)),
              const SizedBox(width: 14),
              _card(Icons.draw_rounded, 'Creative Kit', 'Pens, markers & art', 'STUDENT PICK', const Color(0xFFD38F62)),
              const SizedBox(width: 14),
              _card(Icons.headphones_rounded, 'Campus Tech', 'Audio & accessories', 'TRENDING', const Color(0xFF83B8D8)),
              const SizedBox(width: 14),
              _card(Icons.water_drop_rounded, 'Daily Essentials', 'Bottles & organizers', 'NEW', const Color(0xFFB7D88B)),
            ],
          ),
        ),
        const SizedBox(height: 27),
      ],
    );
  }

  Widget _card(IconData icon, String title, String subtitle, String tag, Color accent) {
    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: espresso, borderRadius: BorderRadius.circular(22), border: Border.all(color: sage, width: 0.6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [darkEmerald, Color.lerp(espresso, accent, 0.35)!]),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(icon, size: 58, color: accent)),
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent, width: 0.7)),
                        child: Text(tag, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: accent)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(title, style: const TextStyle(color: mint, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: taupe, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  Widget _studentCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(color: darkEmerald, borderRadius: BorderRadius.circular(24), border: Border.all(color: gold, width: 0.6)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.auto_awesome_rounded, color: gold),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New to Campus Supply?', style: TextStyle(color: mint, fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Sign in to save favourites and personalize your campus essentials.', style: TextStyle(color: taupe, fontSize: 11, height: 1.35)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.arrow_forward_rounded, color: gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: mint, fontSize: 19, fontWeight: FontWeight.w800))),
          Text(action, style: const TextStyle(color: gold, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: darkEmerald, borderRadius: BorderRadius.circular(14), border: Border.all(color: gold, width: 0.7)),
      child: Icon(icon, color: mint, size: 20),
    );
  }
}
