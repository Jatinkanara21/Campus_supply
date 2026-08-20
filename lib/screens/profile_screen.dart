import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const forest = Color(0xFF0B2E20), dark = Color(0xFF124D36), mint = Color(0xFFA7D7C5), gold = Color(0xFFD8B76A), taupe = Color(0xFF8A7B68), sage = Color(0xFF5F8F7A), espresso = Color(0xFF2A211B);
  String name = 'Student';
  String email = 'student@example.com';

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final n = await AuthService.userName(); if (mounted) setState(() { name = n; }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forest,
      appBar: AppBar(title: const Text('My Profile'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [dark, Color(0xFF1A6046)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: gold.withValues(alpha: .55))), child: Row(children: [
          Container(width: 68, height: 68, decoration: const BoxDecoration(color: Color(0xFF5F8F7A), shape: BoxShape.circle), child: const Icon(Icons.person_rounded, size: 38, color: mint)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: mint, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(email, style: const TextStyle(color: taupe, fontSize: 12)), const SizedBox(height: 7), const Text('Student', style: TextStyle(color: gold, fontWeight: FontWeight.w700))])),
        ])),
        const SizedBox(height: 14),
        Row(children: [_stat('12', 'Orders'), _stat('5', 'Wishlist'), _stat('320', 'Rewards')]),
        const SizedBox(height: 18),
        ...[
          (Icons.receipt_long_outlined, 'My Orders', 'Track and review your orders'),
          (Icons.favorite_border_rounded, 'Wishlist', 'Your saved items'),
          (Icons.location_on_outlined, 'Addresses', 'Manage delivery addresses'),
          (Icons.credit_card_outlined, 'Payment Methods', 'Manage payment options'),
          (Icons.star_border_rounded, 'My Reviews', 'Your product reviews'),
          (Icons.help_outline_rounded, 'Help & Support', 'Get help or contact us'),
          (Icons.settings_outlined, 'Settings', 'App preferences'),
        ].map((x) => Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(17)), child: ListTile(leading: Icon(x.$1, color: gold), title: Text(x.$2, style: const TextStyle(color: mint, fontWeight: FontWeight.w700)), subtitle: Text(x.$3, style: const TextStyle(color: taupe, fontSize: 11)), trailing: const Icon(Icons.chevron_right_rounded, color: sage)))),
        Container(decoration: BoxDecoration(color: espresso, borderRadius: BorderRadius.circular(17)), child: ListTile(leading: const Icon(Icons.logout_rounded, color: Color(0xFFE7A18A)), title: const Text('Logout', style: TextStyle(color: Color(0xFFE7A18A), fontWeight: FontWeight.w800)), onTap: () async { await AuthService.logout(); if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false); })),
      ]),
    );
  }

  Widget _stat(String value, String label) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(16)), child: Column(children: [Text(value, style: const TextStyle(color: mint, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: sage, fontSize: 10))])));
}
