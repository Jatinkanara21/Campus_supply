import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/app_image.dart';
import '../database/firestore_database.dart';
import '../widgets/campus_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFACC15);
  static const coral = Color(0xFFF97368);
  static const white = Colors.white;
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE8E4DB);
  static const softBlue = Color(0xFFEAF2FF);
  static const softYellow = Color(0xFFFFF7CC);
  static const softCoral = Color(0xFFFFE9E6);
  static const softMint = Color(0xFFE8F7F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 760 ? 28.0 : 16.0;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 18),
                  sliver: SliverToBoxAdapter(
                    child: _Header(context),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverToBoxAdapter(
                    child: _Hero(context, wide: constraints.maxWidth >= 760),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 30, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      title: 'Shop by category',
                      action: 'View all',
                      onTap: () => Navigator.pushNamed(context, '/shop'),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirestoreDatabase.instance.watchCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _CategoryMessage(message: 'Could not load categories.');
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 118,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final categories = snapshot.data!;
                        if (categories.isEmpty) {
                          return _CategoryMessage(
                            message: 'No categories yet. Add categories from Admin Dashboard.',
                          );
                        }

                        return SizedBox(
                          height: 118,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) {
                              final category = categories[i];
                              final name = (category['name'] ?? category['slug'] ?? 'Category').toString();
                              return _CategoryCard(
                                imageUrl: (category['imageUrl'] ?? '').toString().trim(),
                                icon: _categoryIcon(name),
                                title: name,
                                background: _categoryBackground(i),
                                accent: _categoryAccent(i),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/shop',
                                  arguments: {'category': name, 'query': ''},
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 30, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      title: 'Popular this week',
                      subtitle: 'Made for campus life',
                      action: 'See all',
                      onTap: () => Navigator.pushNamed(context, '/shop'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreDatabase.instance.watchProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final products = snapshot.data!.take(4).toList();
                      if (products.isEmpty) {
                        return Container(
                          margin: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 0),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border),
                          ),
                          child: const Text(
                            'Products will appear here after an admin adds them in Firestore.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.maxWidth >= 900 ? 4 : 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: constraints.maxWidth >= 900 ? .78 : .68,
                          ),
                          itemBuilder: (_, i) {
                            final p = products[i];
                            return _FirebaseProductCard(
                              product: p,
                              onTap: () => Navigator.pushNamed(context, '/product', arguments: p),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _StudentDeal(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 30, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      title: 'Student bundles',
                      subtitle: 'Less searching. More creating.',
                      action: 'Explore',
                      onTap: () => Navigator.pushNamed(context, '/bundles'),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 170,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _BundleCard(
                            title: 'Architecture Starter Kit',
                            subtitle: 'Drafting tools + sketchbook + studio essentials.',
                            price: '₹2,499',
                            badge: 'Save 15%',
                            icon: Icons.architecture_rounded,
                            background: softBlue,
                            accent: blue,
                            onTap: () => Navigator.pushNamed(context, '/bundles'),
                          ),
                          const SizedBox(width: 14),
                          _BundleCard(
                            title: 'First-Year Essentials',
                            subtitle: 'A practical starter pack for your semester.',
                            price: '₹999',
                            badge: 'Save 15%',
                            icon: Icons.auto_stories_rounded,
                            background: softCoral,
                            accent: coral,
                            onTap: () => Navigator.pushNamed(context, '/bundles'),
                          ),
                          const SizedBox(width: 14),
                          _BundleCard(
                            title: 'Exam Survival Kit',
                            subtitle: 'Notebooks, pens and everything for finals.',
                            price: '₹799',
                            badge: 'Student fave',
                            icon: Icons.school_rounded,
                            background: softYellow,
                            accent: const Color(0xFF9A7600),
                            onTap: () => Navigator.pushNamed(context, '/bundles'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 30, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      title: 'What students say',
                      subtitle: 'Real campus energy',
                      action: '',
                      onTap: () {},
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 34),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Testimonial(
                        quote: '“Finally, a store that gets student life.”',
                        byline: 'Aarav • Architecture student',
                      ),
                      const SizedBox(height: 10),
                      _Testimonial(
                        quote: '“My stationery addiction has found a home.”',
                        byline: 'Maya • Design student',
                      ),
                      const SizedBox(height: 10),
                      _Testimonial(
                        quote: '“Less searching. More creating.”',
                        byline: 'Riya • Fine arts student',
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomNav(context),
    );
  }

  Widget _Header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CampusLogo(size: 46),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Supply',
                    style: TextStyle(
                      color: ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Create more. Spend less.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _CircleButton(
              icon: Icons.favorite_border_rounded,
              onTap: () => Navigator.pushNamed(context, '/wishlist'),
            ),
            const SizedBox(width: 8),
            _CircleButton(
              icon: Icons.shopping_bag_outlined,
              onTap: () => Navigator.pushNamed(context, '/cart'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C172033),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(onSubmitted: (value) { final query = value.trim(); if (query.isNotEmpty) Navigator.pushNamed(context, '/shop', arguments: {'query': query, 'category': 'All'}); },
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded, color: blue, size: 23),
              hintText: 'Search stationery, art supplies, tech...',
              hintStyle: TextStyle(
                color: Color(0xFF969BA4),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _Hero(BuildContext context, {required bool wide}) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: FirestoreDatabase.instance.watchHomeSettings(),
      builder: (context, snapshot) {
        final imageUrl = (snapshot.data?['heroImageUrl'] ?? '').toString().trim();

        return Container(
          constraints: const BoxConstraints(minHeight: 235),
          padding: EdgeInsets.fromLTRB(
            wide ? 30 : 22,
            25,
            wide ? 24 : 16,
            22,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [blue, Color(0xFF4A80EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x252563EB),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'BACK TO CAMPUS',
                        style: TextStyle(
                          color: white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Big ideas start\nwith small supplies.',
                      style: TextStyle(
                        color: white,
                        fontSize: 30,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Student-friendly prices. Creative-friendly supplies.',
                      style: TextStyle(
                        color: Color(0xFFEAF2FF),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 17),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/shop'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: yellow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop campus essentials',
                              style: TextStyle(
                                color: ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 7),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: ink,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    minHeight: 165,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .14),
                    ),
                  ),
                  child: imageUrl.isNotEmpty
                      ? _homeAssetImage(imageUrl)
                      : const _HeroFallbackVisual(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('pen') || value.contains('pencil')) return Icons.edit_rounded;
    if (value.contains('book') || value.contains('notebook')) return Icons.menu_book_rounded;
    if (value.contains('art') || value.contains('paint') || value.contains('marker')) return Icons.palette_rounded;
    if (value.contains('draft') || value.contains('geometry')) return Icons.straighten_rounded;
    if (value.contains('tech') || value.contains('electronic')) return Icons.devices_rounded;
    if (value.contains('bag')) return Icons.backpack_rounded;
    return Icons.category_rounded;
  }

  Color _categoryBackground(int index) {
    const values = [
      softBlue,
      softYellow,
      softCoral,
      softMint,
      Color(0xFFF0EAFF),
      Color(0xFFE7F7F8),
    ];
    return values[index % values.length];
  }

  Color _categoryAccent(int index) {
    const values = [
      blue,
      Color(0xFF9A7600),
      coral,
      Color(0xFF16805B),
      Color(0xFF7450E8),
      Color(0xFF087F8C),
    ];
    return values[index % values.length];
  }

  Widget _StudentDeal() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: yellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, color: ink, size: 23),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Budget. Sorted.',
                  style: TextStyle(
                    color: white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Show your student ID and unlock special savings on eligible essentials.',
                  style: TextStyle(
                    color: Color(0xFFB9C0CC),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: yellow, size: 20),
        ],
      ),
    );
  }

  Widget _BottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: NavigationBar(
        height: 72,
        backgroundColor: white,
        surfaceTintColor: white,
        indicatorColor: softBlue,
        selectedIndex: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: ink),
            selectedIcon: Icon(Icons.home_rounded, color: blue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded, color: ink),
            selectedIcon: Icon(Icons.grid_view_rounded, color: blue),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined, color: ink),
            selectedIcon: Icon(Icons.shopping_cart_rounded, color: blue),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded, color: ink),
            selectedIcon: Icon(Icons.favorite_rounded, color: blue),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: ink),
            selectedIcon: Icon(Icons.person_rounded, color: blue),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (i) {
          if (i == 1) Navigator.pushNamed(context, '/shop');
          if (i == 2) Navigator.pushNamed(context, '/cart');
          if (i == 3) Navigator.pushNamed(context, '/wishlist');
          if (i == 4) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _SectionHeading({
    required String title,
    String? subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.45,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'See all',
              style: TextStyle(
                color: blue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }

  Widget _CategoryCard({
    required String imageUrl,
    required IconData icon,
    required String title,
    required Color background,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: imageUrl.isNotEmpty
                  ? ClipOval(child: _homeAssetImage(imageUrl))
                  : Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _CategoryMessage({required String message}) {
    return Container(
      height: 118,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _ProductCard({
    required IconData icon,
    required String title,
    required String price,
    required String rating,
    required Color accent,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F2ED),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(icon, color: accent, size: 58),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: const BoxDecoration(
                          color: white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: ink,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 15),
                const SizedBox(width: 3),
                Text(
                  rating,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  price,
                  style: const TextStyle(
                    color: blue,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _BundleCard({
    required String title,
    required String subtitle,
    required String price,
    required String badge,
    required IconData icon,
    required Color background,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 310,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 92,
              height: double.infinity,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, size: 43, color: accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    price,
                    style: const TextStyle(
                      color: blue,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Testimonial({
    required String quote,
    required String byline,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: softBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.format_quote_rounded, color: blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  byline,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


Widget _homeAssetImage(String path) {
  return AppImage(
    source: path,
    fit: BoxFit.cover,
    fallback: const _HeroFallbackVisual(),
  );
}

class _HeroFallbackVisual extends StatelessWidget {
  const _HeroFallbackVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 15,
          right: 18,
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: HomeScreen.yellow,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 17,
          left: 16,
          child: Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 62,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: HomeScreen.blue,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'IDEAS',
                    style: TextStyle(
                      color: HomeScreen.ink,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 28,
          left: 18,
          child: Transform.rotate(
            angle: 0.12,
            child: Container(
              width: 57,
              height: 73,
              decoration: BoxDecoration(
                color: HomeScreen.yellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: HomeScreen.ink,
                size: 29,
              ),
            ),
          ),
        ),
        Container(
          width: 76,
          height: 82,
          decoration: BoxDecoration(
            color: HomeScreen.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.backpack_rounded,
            color: HomeScreen.yellow,
            size: 48,
          ),
        ),
        const Positioned(
          bottom: 13,
          child: Text(
            'CREATE.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _FirebaseProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  const _FirebaseProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (product['imageUrl'] ?? '').toString().trim();
    // Firestore may contain either a bundled asset path or a Firebase Storage URL.
    final displayImageUrl = imageUrl.isNotEmpty ? imageUrl : _fallbackImageUrl(product);
    return GestureDetector(
      onTap:onTap,
      child: Container(
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(color:HomeScreen.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:HomeScreen.border)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:Container(width:double.infinity,decoration:BoxDecoration(color:const Color(0xFFF5F3EE),borderRadius:BorderRadius.circular(16)),clipBehavior:Clip.antiAlias,child:displayImageUrl.isNotEmpty
              ? AppImage(
                  source: displayImageUrl,
                  fit: BoxFit.cover,
                  fallback: const Icon(
                    Icons.inventory_2_rounded,
                    color: HomeScreen.blue,
                    size: 62,
                  ),
                )
              : const Icon(
                  Icons.inventory_2_rounded,
                  color: HomeScreen.blue,
                  size: 62,
                ))),
          const SizedBox(height:9),
          Text((product['name']??'Product').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:HomeScreen.ink,fontSize:13,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),
          Row(children:[const Icon(Icons.star_rounded,color:Color(0xFFF4B400),size:15),const SizedBox(width:3),Text((product['rating']??'New').toString(),style:const TextStyle(color:HomeScreen.muted,fontSize:10.5,fontWeight:FontWeight.w700)),const Spacer(),Text('₹${product['price']??0}',style:const TextStyle(color:HomeScreen.blue,fontSize:15,fontWeight:FontWeight.w900))]),
        ]),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });



  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: HomeScreen.border),
          ),
          child: Icon(icon, color: HomeScreen.ink, size: 20),
        ),
      ),
    );
  }
}


String _fallbackImageUrl(Map<String, dynamic> product) {
  final value = '${product['name'] ?? ''} ${product['category'] ?? ''}'.toLowerCase();
  if (value.contains('backpack') || value.contains('bag')) return 'assets/image/products/backpack.svg';
  if (value.contains('headphone')) return 'assets/image/products/headphones.svg';
  if (value.contains('bottle') || value.contains('tumbler')) return 'assets/image/products/bottle.svg';
  if (value.contains('calculator')) return 'assets/image/products/calculator.svg';
  if (value.contains('lamp')) return 'assets/image/products/lamp.svg';
  if (value.contains('sleeve')) return 'assets/image/products/sleeve.svg';
  if (value.contains('pen')) return 'assets/image/products/pen.svg';
  return 'assets/image/products/notebook.svg';
}
