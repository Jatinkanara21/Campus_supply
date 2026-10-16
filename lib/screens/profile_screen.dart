import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/firestore_database.dart';
import '../services/auth_service.dart';
import '../widgets/customer_bottom_nav.dart';

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
  static const paleGreen = Color(0xFFE6F8EE);
  static const palePurple = Color(0xFFF0EAFE);
  static const paleYellow = Color(0xFFFFF5D7);

  String name = 'Student';
  bool admin = false;
  bool signingOut = false;

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
    if (signingOut) return;
    setState(() => signingOut = true);
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => signingOut = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not sign out right now. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim() ?? '';
    final wide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 850
                ? 26.0
                : constraints.maxWidth >= 560
                    ? 22.0
                    : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 0),
                        child: _brandHeader(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                        child: _profileSummary(user, email, wide),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionTitle(
                              'Your Account',
                              'Manage your orders, preferences and more',
                            ),
                            const SizedBox(height: 12),
                            _sectionCard(
                              children: [
                                _menuRow(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'My Orders',
                                  subtitle: 'View and track your orders',
                                  tint: paleBlue,
                                  iconColor: blue,
                                  onTap: () => _go('/orders'),
                                ),
                                _menuRow(
                                  icon: Icons.favorite_rounded,
                                  title: 'My Wishlist',
                                  subtitle: 'View your saved products',
                                  tint: paleCoral,
                                  iconColor: const Color(0xFFF06464),
                                  onTap: () => _go('/wishlist'),
                                ),
                                _menuRow(
                                  icon: Icons.shopping_cart_outlined,
                                  title: 'Cart',
                                  subtitle: 'Review items in your bag',
                                  tint: paleGreen,
                                  iconColor: const Color(0xFF17824C),
                                  onTap: () => _go('/cart'),
                                ),
                                _menuRow(
                                  icon: Icons.info_outline_rounded,
                                  title: 'About Campus Supply',
                                  subtitle: 'Learn more about Campus Supply',
                                  tint: palePurple,
                                  iconColor: const Color(0xFF6941C6),
                                  onTap: () => _go('/about'),
                                ),
                                _menuRow(
                                  icon: Icons.help_outline_rounded,
                                  title: 'Help & FAQ',
                                  subtitle: 'Find answers to common questions',
                                  tint: paleYellow,
                                  iconColor: const Color(0xFFAF7A00),
                                  onTap: () => _go('/faq'),
                                ),
                                _menuRow(
                                  icon: Icons.mail_outline_rounded,
                                  title: 'Contact',
                                  subtitle: 'Talk to the Campus Supply team',
                                  tint: paleBlue,
                                  iconColor: blue,
                                  showDivider: false,
                                  onTap: () => _go('/contact'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _signOutCard(),
                            const SizedBox(height: 24),
                          ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final showArtwork = constraints.maxWidth >= 650;

        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 22,
            compact ? 17 : 20,
            compact ? 16 : 22,
            compact ? 17 : 20,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [blue, blueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -48,
                top: -62,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: const BoxDecoration(
                    color: Color(0x14FFFFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: compact ? 48 : 54,
                    height: compact ? 48 : 54,
                    decoration: BoxDecoration(
                      color: yellow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: ink,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Campus ',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Supply',
                                style: TextStyle(color: yellow),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 20 : 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          compact
                              ? 'Your campus essentials'
                              : 'Create More. Spend Less.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFEAF2FF),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showArtwork) ...[
                    const SizedBox(width: 18),
                    const SizedBox(
                      width: 205,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Better essentials\nfor a brighter campus life',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.school_outlined,
                            color: Color(0xE6FFFFFF),
                            size: 43,
                          ),
                        ],
                      ),
                    ),
                  ] else if (!compact) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0x44FFFFFF)),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileSummary(User? user, String email, bool wide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 22 : 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(user),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: wide ? 25 : 21,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 12.5),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: paleBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        admin ? 'Administrator' : 'Student',
                        style: const TextStyle(
                          color: blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (admin && wide) ...[
                const SizedBox(width: 16),
                _adminShortcut(compact: false),
              ],
            ],
          ),
          if (admin && !wide) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _adminShortcut(compact: true),
            ),
          ],
          const SizedBox(height: 18),
          _liveStats(),
        ],
      ),
    );
  }

  Widget _adminShortcut({required bool compact}) {
    return Material(
      color: const Color(0xFFFFF8E4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _go('/admin'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 13,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF2E3B4)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDB4),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFF946200),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              if (compact)
                Expanded(child: _adminShortcutText(compact: true))
              else
                _adminShortcutText(compact: false),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminShortcutText({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Manage your catalog',
          style: TextStyle(
            color: muted,
            fontSize: compact ? 11 : 10,
          ),
        ),
      ],
    );
  }

  Widget _avatar(User? user) {
    final photoUrl = user?.photoURL;

    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: paleBlue,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: blue,
                  size: 42,
                ),
              )
            : const Icon(
                Icons.person_rounded,
                color: blue,
                size: 42,
              ),
      ),
    );
  }

  Widget _liveStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Row(
        children: [
          Expanded(
            child: _stat(
              value: '—',
              label: 'Orders',
              icon: Icons.inventory_2_outlined,
              tint: paleBlue,
              iconColor: blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _stat(
              value: '—',
              label: 'Wishlist',
              icon: Icons.favorite_rounded,
              tint: paleCoral,
              iconColor: const Color(0xFFF06464),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;
        final orderStat = StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreDatabase.instance.watchOrders(uid),
          builder: (context, snapshot) => _stat(
            value: snapshot.hasError
                ? '—'
                : snapshot.hasData
                    ? '${snapshot.data!.length}'
                    : '…',
            label: 'Orders',
            icon: Icons.inventory_2_outlined,
            tint: paleBlue,
            iconColor: blue,
          ),
        );
        final wishlistStat = StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreDatabase.instance.watchWishlist(uid),
          builder: (context, snapshot) => _stat(
            value: snapshot.hasError
                ? '—'
                : snapshot.hasData
                    ? '${snapshot.data!.length}'
                    : '…',
            label: 'Wishlist',
            icon: Icons.favorite_rounded,
            tint: paleCoral,
            iconColor: const Color(0xFFF06464),
          ),
        );

        if (stacked) {
          return Column(
            children: [
              orderStat,
              const SizedBox(height: 10),
              wishlistStat,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: orderStat),
            const SizedBox(width: 12),
            Expanded(child: wishlistStat),
          ],
        );
      },
    );
  }

  Widget _stat({
    required String value,
    required String label,
    required IconData icon,
    required Color tint,
    required Color iconColor,
  }) {
    final title = label == 'Orders' ? 'My Orders' : 'My Wishlist';
    final subtitle = label == 'Orders' ? 'Track your orders' : 'View saved items';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right_rounded, color: muted, size: 19),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(children: children),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required Color iconColor,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: iconColor, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: muted,
                    size: 25,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 58, color: border),
      ],
    );
  }

  Widget _signOutCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          onPressed: signingOut ? null : _signOut,
          icon: signingOut
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFDC2626),
                  ),
                )
              : const Icon(Icons.logout_rounded, size: 18),
          label: Text(signingOut ? 'Signing out…' : 'Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            backgroundColor: const Color(0xFFFFE8E8),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
