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
  static const blueDark = Color(0xFF1D4ED8);
  static const yellow = Color(0xFFFFD66B);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE7ECF3);
  static const paleBlue = Color(0xFFEAF4FF);
  static const coral = Color(0xFFFF6B63);
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
      name = n.trim().isEmpty ? 'Student' : n.trim();
      admin = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          final maxWidth = constraints.maxWidth >= 1000 ? 1120.0 : 760.0;
          final horizontal = wide ? 24.0 : 16.0;
          return Stack(children: [
            Positioned(
              top: 0, left: 0, right: 0, height: 220,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 48),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [blue, blueDark],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
                ),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.shopping_bag_rounded, color: blueDark, size: 29),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Campus ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'Supply', style: TextStyle(color: yellow)),
                      ]), style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, height: 1.1)),
                      SizedBox(height: 5),
                      Text('Create More. Spend Less.', style: TextStyle(color: Color(0xFFEAF2FF), fontSize: 12.5)),
                    ],
                  )),
                ]),
              ),
            ),
            Center(child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 128, horizontal, 36),
                children: [
                  _profileCard(email, wide),
                  const SizedBox(height: 20),
                  _section([
                    if (admin) _item(Icons.admin_panel_settings_rounded, 'Admin dashboard', 'Manage the Campus Supply catalog',
                      () => Navigator.pushNamed(context, '/admin'), tint: const Color(0xFFE8EEFF)),
                    _item(Icons.inventory_2_outlined, 'My Orders', 'Track and view your orders',
                      () => Navigator.pushNamed(context, '/orders')),
                    _item(Icons.favorite_rounded, 'My Wishlist', 'View your saved products',
                      () => Navigator.pushNamed(context, '/wishlist'), tint: const Color(0xFFFFEEEE), iconColor: coral),
                    _item(Icons.shopping_cart_outlined, 'Cart', 'Review items in your bag',
                      () => Navigator.pushNamed(context, '/cart'), last: true),
                  ]),
                  const SizedBox(height: 18),
                  _section([
                    _item(Icons.help_outline_rounded, 'Help & Support', 'FAQ and contact information',
                      () => Navigator.pushNamed(context, '/faq')),
                    _item(Icons.info_outline_rounded, 'About Campus Supply', 'Create More. Spend Less.',
                      () => Navigator.pushNamed(context, '/about')),
                    _item(Icons.mail_outline_rounded, 'Contact', 'Talk to the Campus Supply team',
                      () => Navigator.pushNamed(context, '/contact'), last: true),
                  ]),
                  const SizedBox(height: 18),
                  SizedBox(height: 58, child: FilledButton.icon(
                    onPressed: _signOut,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE3E3),
                      foregroundColor: const Color(0xFFCF2727),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  )),
                ],
              ),
            )),
          ]);
        }),
      ),
    );
  }

  Widget _profileCard(String email, bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 26 : 20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x0D172554), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: wide ? 104 : 82, height: wide ? 104 : 82,
            decoration: const BoxDecoration(color: paleBlue, shape: BoxShape.circle),
            child: Icon(Icons.person_rounded, color: blue, size: wide ? 58 : 46),
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ink, fontSize: wide ? 26 : 21, fontWeight: FontWeight.w900, height: 1.15)),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(email, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontSize: wide ? 15 : 12)),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: paleBlue, borderRadius: BorderRadius.circular(30)),
              child: Text(admin ? 'Administrator' : 'Student',
                style: const TextStyle(color: blueDark, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ])),
        ]),
        const SizedBox(height: 24),
        _stats(),
      ]),
    );
  }

  Widget _stats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Row(children: [
      Expanded(child: _stat('—', 'Orders', Icons.shopping_cart_outlined, paleBlue, blue)),
      const _StatDivider(),
      Expanded(child: _stat('—', 'Wishlist', Icons.favorite_rounded, const Color(0xFFFFEEEE), coral)),
    ]);
    return Row(children: [
      Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchOrders(uid),
        builder: (context, s) => _stat(s.hasError ? '—' : s.hasData ? '${s.data!.length}' : '…',
          'Orders', Icons.shopping_cart_outlined, paleBlue, blue),
      )),
      const _StatDivider(),
      Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchWishlist(uid),
        builder: (context, s) => _stat(s.hasError ? '—' : s.hasData ? '${s.data!.length}' : '…',
          'Wishlist', Icons.favorite_rounded, const Color(0xFFFFEEEE), coral),
      )),
    ]);
  }

  Widget _stat(String value, String label, IconData icon, Color tint, Color iconColor) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 27)),
      const SizedBox(height: 9),
      Text(value, style: const TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _section(List<Widget> children) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(26),
      boxShadow: const [BoxShadow(color: Color(0x0D172554), blurRadius: 24, offset: Offset(0, 8))],
    ),
    child: Column(children: children),
  );

  Widget _item(IconData icon, String title, String subtitle, VoidCallback onTap, {
    Color tint = paleBlue, Color iconColor = blue, bool last = false,
  }) => Column(children: [
    Material(color: Colors.transparent, child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 27)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 12.5)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: muted, size: 26),
        ]),
      ),
    )),
    if (!last) const Divider(height: 1, thickness: 1, color: border, indent: 68),
  ]);

  Future<void> _signOut() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(height: 58, width: 1, color: const Color(0xFFE8ECF2));
}
