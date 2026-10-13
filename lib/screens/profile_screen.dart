import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  static const yellow = Color(0xFFFFC66D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final maxWidth = wide ? 1120.0 : 680.0;
          final horizontalPadding = wide ? 28.0 : 18.0;
          final availableWidth = (constraints.maxWidth < maxWidth ? constraints.maxWidth : maxWidth) - horizontalPadding * 2;
          final itemWidth = wide ? (availableWidth - 16) / 2 : availableWidth;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 36),
                children: [
                  Container(
                    padding: EdgeInsets.all(wide ? 28 : 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [blue, Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: wide ? 76 : 62,
                          height: wide ? 76 : 62,
                          decoration: const BoxDecoration(color: yellow, shape: BoxShape.circle),
                          child: Icon(Icons.person_rounded, color: ink, size: wide ? 40 : 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: wide ? 25 : 21, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 5),
                              Text(admin ? 'Administrator account' : 'Student account', style: const TextStyle(color: Color(0xFFDDE8FF), fontSize: 13)),
                            ],
                          ),
                        ),
                        if (admin)
                          IconButton(
                            tooltip: 'Admin dashboard',
                            onPressed: () => Navigator.pushNamed(context, '/admin'),
                            icon: const Icon(Icons.admin_panel_settings_rounded, color: yellow, size: 28),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _liveStats(),
                  const SizedBox(height: 28),
                  Text('Your account', style: TextStyle(color: ink, fontSize: wide ? 20 : 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      if (admin)
                        SizedBox(width: itemWidth, child: _action(context, Icons.admin_panel_settings_rounded, 'Admin dashboard', 'Manage your Campus Supply catalog', () => Navigator.pushNamed(context, '/admin'), true)),
                      SizedBox(width: itemWidth, child: _action(context, Icons.receipt_long_outlined, 'My orders', 'Track purchases and delivery status', () => Navigator.pushNamed(context, '/orders'), false)),
                      SizedBox(width: itemWidth, child: _action(context, Icons.favorite_border_rounded, 'Wishlist', 'Your saved products', () => Navigator.pushNamed(context, '/wishlist'), false)),
                      SizedBox(width: itemWidth, child: _action(context, Icons.shopping_bag_outlined, 'Cart', 'Review your current bag', () => Navigator.pushNamed(context, '/cart'), false)),
                      SizedBox(width: itemWidth, child: _action(context, Icons.info_outline_rounded, 'About', 'Learn about Campus Supply', () => Navigator.pushNamed(context, '/about'), false)),
                      SizedBox(width: itemWidth, child: _action(context, Icons.help_outline_rounded, 'Help & FAQ', 'Find quick answers', () => Navigator.pushNamed(context, '/faq'), false)),
                      SizedBox(width: itemWidth, child: _action(context, Icons.mail_outline_rounded, 'Contact', 'Talk to the Campus Supply team', () => Navigator.pushNamed(context, '/contact'), false)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: ink,
                      side: const BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      await AuthService.logout();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, bool highlighted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: highlighted ? blue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlighted ? blue : border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: highlighted ? Colors.white.withValues(alpha: .14) : const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: highlighted ? yellow : blue),
        ),
        title: Text(title, style: TextStyle(color: highlighted ? Colors.white : ink, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: TextStyle(color: highlighted ? const Color(0xFFDDE8FF) : muted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: highlighted ? Colors.white : muted),
      ),
    );
  }

  Widget _liveStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Row(
        children: [
          Expanded(child: _stat('—', 'Orders')),
          Expanded(child: _stat('—', 'Wishlist')),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchOrders(uid),
            builder: (context, snapshot) => _stat(
              snapshot.hasError ? '—' : snapshot.hasData ? '${snapshot.data!.length}' : '…',
              'Orders',
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchWishlist(uid),
            builder: (context, snapshot) => _stat(
              snapshot.hasError ? '—' : snapshot.hasData ? '${snapshot.data!.length}' : '…',
              'Wishlist',
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          ],
        ),
      );
  }
}
