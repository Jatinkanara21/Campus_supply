import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const navy = Color(0xFF0B1F3A);
  static const blue = Color(0xFF2563EB);
  static const bg = Color(0xFFF7F9FC);
  static const muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _categories()),
            SliverToBoxAdapter(child: _popular()),
            SliverToBoxAdapter(child: _campusBanner()),
            SliverToBoxAdapter(child: _loginCard(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Color(0x120B1F3A), blurRadius: 16)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/images/campus_supply.jpeg', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CampusSupply', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: navy)),
                SizedBox(height: 2),
                Text('Everything for student life', style: TextStyle(fontSize: 11.5, color: muted)),
              ],
            ),
          ),
          _iconButton(Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          _iconButton(Icons.person_outline_rounded),
        ],
      ),
    );
  }

  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1F3A), Color(0xFF174EA6)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x300B1F3A), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Campus made simple.', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, height: 1.05)),
            const SizedBox(height: 8),
            const Text('Find books, stationery, tech and everyday essentials — all in one place.', style: TextStyle(color: Color(0xFFD8E6FF), fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search books, stationery, electronics...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: blue),
                  suffixIcon: Icon(Icons.tune_rounded, color: muted, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _heroChip(Icons.local_shipping_outlined, 'Campus delivery'),
                const SizedBox(width: 8),
                _heroChip(Icons.verified_outlined, 'Student focused'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  Widget _categories() {
    final items = [
      (Icons.menu_book_rounded, 'Books'),
      (Icons.edit_note_rounded, 'Stationery'),
      (Icons.laptop_mac_rounded, 'Electronics'),
      (Icons.science_rounded, 'Lab Supplies'),
      (Icons.backpack_rounded, 'Bags'),
    ];
    return Column(
      children: [
        _sectionTitle('Shop by category', 'View all'),
        SizedBox(
          height: 105,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => Container(
              width: 92,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8EDF4))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(13)), child: Icon(items[i].$1, color: blue, size: 22)),
                  const SizedBox(height: 8),
                  Text(items[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: navy)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _popular() {
    return Column(
      children: [
        _sectionTitle('Popular right now', 'See all'),
        SizedBox(
          height: 235,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              _productCard(Icons.menu_book_rounded, 'Exam Notes', 'Study essentials', 'Popular'),
              const SizedBox(width: 14),
              _productCard(Icons.edit_rounded, 'Study Kit', 'Pens + highlighters', 'Student pick'),
              const SizedBox(width: 14),
              _productCard(Icons.headphones_rounded, 'Campus Audio', 'Everyday tech', 'Trending'),
            ],
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _productCard(IconData icon, String title, String subtitle, String tag) {
    return SizedBox(
      width: 185,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8EDF4))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(15)),
                child: Stack(
                  children: [
                    Center(child: Icon(icon, size: 58, color: blue)),
                    Positioned(top: 9, left: 9, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text(tag, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: blue)))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: navy)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _campusBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.school_rounded, color: blue)),
            const SizedBox(width: 13),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Built for campus life', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: navy)), SizedBox(height: 4), Text('Discover essentials made for your classes, projects and everyday college life.', style: TextStyle(fontSize: 11.5, color: muted, height: 1.35))])),
          ],
        ),
      ),
    );
  }

  Widget _loginCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(23)),
        child: Row(
          children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your campus, your account.', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Sign in to save favourites and personalise your experience.', style: TextStyle(color: Color(0xFFB9C9E2), fontSize: 11.5, height: 1.4))])),
            const SizedBox(width: 12),
            Column(
              children: [
                SizedBox(height: 36, child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/login'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: navy, padding: const EdgeInsets.symmetric(horizontal: 15)), child: const Text('Sign in', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))),
                const SizedBox(height: 7),
                GestureDetector(onTap: () => Navigator.pushNamed(context, '/register'), child: const Text('Create account', style: TextStyle(color: Color(0xFFBBD5FF), fontSize: 10.5, fontWeight: FontWeight.w700))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: navy))),
          Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: blue)),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8EDF4))),
      child: Icon(icon, color: navy, size: 21),
    );
  }

  Widget _bottomNav() {
    return NavigationBar(
      height: 68,
      backgroundColor: Colors.white,
      elevation: 8,
      selectedIndex: 0,
      indicatorColor: const Color(0xFFE7F0FF),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: blue), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded, color: blue), label: 'Explore'),
        NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded, color: blue), label: 'Saved'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: blue), label: 'Profile'),
      ],
    );
  }
}
