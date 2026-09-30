import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFACC15);
  static const muted = Color(0xFF707681);
  static const border = Color(0xFFE7E2D9);

  String name = 'Student';
  String email = '';
  bool admin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await AuthService.userName();
    final a = await AuthService.isAdmin();
    if (mounted) {
      setState(() {
        name = n;
        admin = a;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          final content = [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [blue, Color(0xFF1747B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: ink, size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Student account',
                          style: TextStyle(color: Color(0xFFDDE8FF)),
                        ),
                      ],
                    ),
                  ),
                  if (admin)
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/admin'),
                      icon: const Icon(Icons.admin_panel_settings_rounded, color: yellow),
                      tooltip: 'Admin dashboard',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('12', 'Orders'),
                _stat('5', 'Wishlist'),
                _stat('320', 'Points'),
              ],
            ),
            const SizedBox(height: 18),
            if (admin)
              _action(
                context,
                Icons.admin_panel_settings_rounded,
                'Admin Dashboard',
                'Manage products, users, orders and reviews',
                () => Navigator.pushNamed(context, '/admin'),
                highlighted: true,
              ),
            _action(
              context,
              Icons.receipt_long_outlined,
              'My Orders',
              'Track your purchases and delivery status',
              () => Navigator.pushNamed(context, '/orders'),
            ),
            _action(
              context,
              Icons.favorite_border_rounded,
              'Wishlist',
              'Your saved campus essentials',
              () => Navigator.pushNamed(context, '/wishlist'),
            ),
            _action(
              context,
              Icons.shopping_bag_outlined,
              'Cart',
              'Review items and continue to checkout',
              () => Navigator.pushNamed(context, '/cart'),
            ),
            _action(
              context,
              Icons.info_outline_rounded,
              'About Campus Supply',
              'Learn about the student-first experience',
              () => Navigator.pushNamed(context, '/about'),
            ),
            _action(
              context,
              Icons.help_outline_rounded,
              'Help & FAQ',
              'Quick answers and support information',
              () => Navigator.pushNamed(context, '/faq'),
            ),
            _action(
              context,
              Icons.mail_outline_rounded,
              'Contact',
              'Send an enquiry to the Campus Supply team',
              () => Navigator.pushNamed(context, '/contact'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ];

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 980 : 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
                children: content,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool highlighted = false,
  }) {
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
        title: Text(
          title,
          style: TextStyle(
            color: highlighted ? Colors.white : ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: highlighted ? const Color(0xFFDDE8FF) : muted,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: highlighted ? Colors.white : const Color(0xFF9AA0AA),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      );
}
