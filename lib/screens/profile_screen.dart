import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_bottom_nav.dart';

import '../database/firestore_database.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4ED8);
  static const yellow = Color(0xFFFFC66D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const paleBlue = Color(0xFFEAF2FF);
  static const paleCoral = Color(0xFFFFE9E6);

  String name = 'Student';
  bool admin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await AuthService.userName();
    final a = await AuthService.isAdmin();
    if (!mounted) return;
    setState(() {
      name = n;
      admin = a;
    });
  }

  void _go(String route) => Navigator.pushNamed(context, route);

  Future<void> _signOut() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim() ?? '';
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final maxWidth = wide ? 980.0 : 620.0;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth >= 850 ? 26.0 : 16.0;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(side, 12, side, 0),
                        child: _brandHeader(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -20),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(side, 0, side, 0),
                          child: Column(
                            children: [
                              _profileSummary(user, email, wide),
                              const SizedBox(height: 18),
                              _sectionCard(children: [
                                _menuRow(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'My Orders',
                                  subtitle: 'Track and view your orders',
                                  tint: paleBlue,
                                  onTap: () => _go('/orders'),
                                ),
                                _menuRow(
                                  icon: Icons.favorite_rounded,
                                  title: 'My Wishlist',
                                  subtitle: 'View your saved products',
                                  tint: paleCoral,
                                  onTap: () => _go('/wishlist'),
                                ),
                                _menuRow(
                                  icon: Icons.shopping_cart_outlined,
                                  title: 'Cart',
                                  subtitle: 'Review items in your bag',
                                  tint: paleBlue,
                                  showDivider: false,
                                  onTap: () => _go('/cart'),
                                ),
                              ]),
                              const SizedBox(height: 18),
                              _sectionCard(children: [
                                if (admin)
                                  _menuRow(
                                    icon: Icons.admin_panel_settings_outlined,
                                    title: 'Admin Dashboard',
                                    subtitle: 'Manage the Campus Supply catalog',
                                    tint: const Color(0xFFFFF7CC),
                                    onTap: () => _go('/admin'),
                                  ),
                                _menuRow(
                                  icon: Icons.help_outline_rounded,
                                  title: 'Help & Support',
                                  subtitle: 'FAQs and answers to common questions',
                                  tint: paleBlue,
                                  onTap: () => _go('/faq'),
                                ),
                                _menuRow(
                                  icon: Icons.mail_outline_rounded,
                                  title: 'Contact Us',
                                  subtitle: 'Talk to the Campus Supply team',
                                  tint: paleBlue,
                                  onTap: () => _go('/contact'),
                                ),
                                _menuRow(
                                  icon: Icons.info_outline_rounded,
                                  title: 'About Campus Supply',
                                  subtitle: 'Create More. Spend Less.',
                                  tint: paleBlue,
                                  showDivider: false,
                                  onTap: () => _go('/about'),
                                ),
                              ]),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _signOut,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Log out'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    backgroundColor: const Color(0xFFFFE3E3),
                                    side: BorderSide.none,
                                    minimumSize: const Size.fromHeight(56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _brandHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [blue, blueDark],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
          bottom: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: yellow,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: ink, size: 32),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Campus ', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'Supply', style: TextStyle(color: yellow)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                ),
                SizedBox(height: 4),
                Text('Create More. Spend Less.', style: TextStyle(color: Color(0xFFEAF2FF), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _profileSummary(User? user, String email, bool wide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 26 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: ink.withValues(alpha: 0.055), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(user),
              const SizedBox(width: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ink, fontSize: wide ? 25 : 20, fontWeight: FontWeight.w900, height: 1.15)),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(email, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 12.5)),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(color: paleBlue, borderRadius: BorderRadius.circular(30)),
                        child: Text(admin ? 'Administrator' : 'Student',
                          style: const TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _liveStats(),
        ],
      ),
    );
  }

  Widget _avatar(User? user) {
    final photoUrl = user?.photoURL;
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: paleBlue, shape: BoxShape.circle),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(photoUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: blue, size: 42))
            : const Icon(Icons.person_rounded, color: blue, size: 42),
      ),
    );
  }

  Widget _liveStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Row(children: [
        Expanded(child: _stat('—', 'Orders', Icons.shopping_cart_outlined, paleBlue)),
        const SizedBox(width: 8),
        Expanded(child: _stat('—', 'Wishlist', Icons.favorite_rounded, paleCoral)),
      ]);
    }
    return Row(children: [
      Expanded(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreDatabase.instance.watchOrders(uid),
          builder: (context, snapshot) => _stat(
            snapshot.hasError ? '—' : snapshot.hasData ? '${snapshot.data!.length}' : '…',
            'Orders', Icons.shopping_cart_outlined, paleBlue,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreDatabase.instance.watchWishlist(uid),
          builder: (context, snapshot) => _stat(
            snapshot.hasError ? '—' : snapshot.hasData ? '${snapshot.data!.length}' : '…',
            'Wishlist', Icons.favorite_rounded, paleCoral,
          ),
        ),
      ),
    ]);
  }

  Widget _stat(String value, String label, IconData icon, Color tint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          child: Icon(icon, color: label == 'Wishlist' ? const Color(0xFFF06464) : blue, size: 20),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: ink.withValues(alpha: 0.035), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, color: title == 'My Wishlist' ? const Color(0xFFF06464) : ink, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: ink, fontSize: 15.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 12.5)),
                ]),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: muted, size: 25),
            ]),
          ),
        ),
      ),
      if (showDivider) const Divider(height: 1, indent: 62, color: border),
    ]);
  }

  ,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Shop'),
        NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart_rounded), label: 'Cart'),
        NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Wishlist'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
