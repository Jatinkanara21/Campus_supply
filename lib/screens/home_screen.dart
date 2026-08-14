import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const ink = Color(0xFF17172B);
  static const purple = Color(0xFF6D4AFF);
  static const muted = Color(0xFF77778A);
  static const bg = Color(0xFFF8F8FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(child: _categories()),
        SliverToBoxAdapter(child: _featured()),
        SliverToBoxAdapter(child: _studentCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ])),
      bottomNavigationBar: NavigationBar(
        height: 70, backgroundColor: Colors.white, elevation: 5, selectedIndex: 0,
        indicatorColor: const Color(0xFFECE8FF),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: purple), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded, color: purple), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded, color: purple), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: purple), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
    child: Row(children: [
      const CampusLogo(size: 48), const SizedBox(width: 11),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CampusSupply', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink, letterSpacing: -.6)),
        Text('Student life, simplified.', style: TextStyle(fontSize: 11, color: muted)),
      ])),
      _roundIcon(Icons.notifications_none_rounded), const SizedBox(width: 8), _roundIcon(Icons.shopping_bag_outlined),
    ]),
  );

  Widget _hero() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B1738), Color(0xFF6D4AFF)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color(0x2D6D4AFF), blurRadius: 28, offset: Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ready for
campus life?', style: TextStyle(color: Colors.white, fontSize: 29, height: 1.02, fontWeight: FontWeight.w800, letterSpacing: -1)),
            SizedBox(height: 9), Text('Books, stationery, gadgets, lab supplies and more — curated for students.', style: TextStyle(color: Color(0xFFE4E0FF), fontSize: 12.5, height: 1.45)),
          ])),
          Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), shape: BoxShape.circle), child: const Icon(Icons.school_rounded, color: Colors.white, size: 38)),
        ]),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
          child: const TextField(decoration: InputDecoration(hintText: 'What are you looking for?', prefixIcon: Icon(Icons.search_rounded, color: purple), suffixIcon: Icon(Icons.tune_rounded, color: muted), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16))),
        ),
        const SizedBox(height: 13),
        Row(children: [_chip(Icons.bolt_rounded, 'Quick discovery'), const SizedBox(width: 8), _chip(Icons.verified_rounded, 'Student picks')]),
      ]),
    ),
  );

  Widget _chip(IconData icon, String text) => Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .11), borderRadius: BorderRadius.circular(13)), child: Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)))])));

  Widget _categories() {
    final data = [(Icons.menu_book_rounded, 'Books'), (Icons.edit_rounded, 'Stationery'), (Icons.devices_rounded, 'Tech'), (Icons.science_rounded, 'Lab'), (Icons.backpack_rounded, 'Bags')];
    return Column(children: [
      _title('Explore categories', 'See all'),
      SizedBox(height: 108, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal, itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) => Container(width: 94, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEAE8F2))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0EDFF), borderRadius: BorderRadius.circular(14)), child: Icon(data[i].$1, color: purple, size: 22)), const SizedBox(height: 8), Text(data[i].$2, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 11))])))),
      const SizedBox(height: 27),
    ]);
  }

  Widget _featured() => Column(children: [
    _title('Made for your semester', 'View all'),
    SizedBox(height: 242, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      _card(Icons.menu_book_rounded, 'Study essentials', 'Notes, books & guides', 'BESTSELLER'), const SizedBox(width: 14),
      _card(Icons.draw_rounded, 'Creative kit', 'Pens, markers & art', 'STUDENT PICK'), const SizedBox(width: 14),
      _card(Icons.headphones_rounded, 'Campus tech', 'Audio & accessories', 'TRENDING'),
    ])),
    const SizedBox(height: 27),
  ]);

  Widget _card(IconData icon, String title, String subtitle, String tag) => SizedBox(width: 190, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFEAE8F2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF2F0FF), Color(0xFFEAE5FF)]), borderRadius: BorderRadius.circular(17)), child: Stack(children: [Center(child: Icon(icon, size: 58, color: purple)), Positioned(top: 9, left: 9, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text(tag, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: purple))))]))),
    const SizedBox(height: 11), Text(title, style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: muted, fontSize: 10.5)),
  ])));

  Widget _studentCard() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(19), decoration: BoxDecoration(color: const Color(0xFF17172B), borderRadius: BorderRadius.circular(24)), child: Row(children: [
    Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF2A2844), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC9BDFF))), const SizedBox(width: 13),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Make it yours.', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Sign in to save favourites and get a more personal campus experience.', style: TextStyle(color: Color(0xFFB4B1C5), fontSize: 11, height: 1.35))])), const SizedBox(width: 8),
    IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
  ]));

  Widget _title(String title, String action) => Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.4))), Text(action, style: const TextStyle(color: purple, fontSize: 11.5, fontWeight: FontWeight.w800))]));

  Widget _roundIcon(IconData icon) => Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEAE8F2))), child: Icon(icon, color: ink, size: 20));
}
