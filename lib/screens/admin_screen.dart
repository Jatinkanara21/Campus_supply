import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';
import '../database/firestore_seed.dart';
import '../services/auth_service.dart';
import 'admin_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFACC15);
  static const muted = Color(0xFF707681);

  bool loading = true;
  bool admin = false;
  String name = 'Admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await AuthService.isAdmin();
    final userName = await AuthService.userName();
    if (!mounted) return;
    setState(() {
      admin = result;
      name = userName;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!admin) {
      return Scaffold(
        backgroundColor: cream,
        appBar: AppBar(title: const Text('Admin Access')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64, color: blue),
                const SizedBox(height: 16),
                const Text(
                  'Admin access required',
                  style: TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set your Firebase users document role to admin before opening this page.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, products) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, orders) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, users) {
                  return ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [blue, Color(0xFF1747B8)]),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: yellow,
                              child: Icon(Icons.admin_panel_settings_rounded, color: ink),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ' + name,
                                    style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Campus Supply administration', style: TextStyle(color: Color(0xFFDDE8FF))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _metric(products.data?.docs.length.toString() ?? '0', 'Products', Icons.inventory_2_outlined),
                          _metric(orders.data?.docs.length.toString() ?? '0', 'Orders', Icons.receipt_long_outlined),
                          _metric(users.data?.docs.length.toString() ?? '0', 'Users', Icons.people_outline_rounded),
                          _metric('5', 'Modules', Icons.dashboard_customize_outlined),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE7E2D9)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFFFF4C7),
                              child: Icon(Icons.auto_awesome_rounded, color: ink),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Starter catalog', style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                                  SizedBox(height: 3),
                                  Text(
                                    'Add ready-to-use products, categories and bundles. Existing records are never overwritten.',
                                    style: TextStyle(color: muted, fontSize: 11.5, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _seedCatalog,
                              child: const Text('Seed'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _heroSettingsCard(),
                      const SizedBox(height: 22),
                      const Text('Management', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      _menu(context, Icons.inventory_2_outlined, 'Products', 'Add, edit and remove products', AdminSection.products),
                      _menu(context, Icons.category_outlined, 'Categories', 'Manage product categories', AdminSection.categories),
                      _menu(context, Icons.auto_awesome_outlined, 'Bundles', 'Manage student bundles', AdminSection.bundles),
                      _menu(context, Icons.receipt_long_outlined, 'Orders', 'Review and update order status', AdminSection.orders),
                      _menu(context, Icons.people_outline_rounded, 'Users', 'View users and manage roles', AdminSection.users),
                      _menu(context, Icons.rate_review_outlined, 'Reviews', 'Moderate customer reviews', AdminSection.reviews),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await AuthService.logout();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _heroSettingsCard() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: FirestoreDatabase.instance.watchHomeSettings(),
      builder: (context, snapshot) {
        final imageUrl = (snapshot.data?['heroImageUrl'] ?? '').toString().trim();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E2D9)),
          ),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 68,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.image_outlined, color: blue, size: 30)
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined, color: blue),
                      ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Homepage hero image', style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text(
                      'Remove the static artwork. Set the hero image with a URL or upload an image file.',
                      style: TextStyle(color: muted, fontSize: 11.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _editHeroSettings(imageUrl),
                icon: const Icon(Icons.image_rounded),
                label: const Text('Manage'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editHeroSettings(String currentAsset) async {
    final controller = TextEditingController(text: currentAsset);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Homepage hero image'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Local asset path',
                    hintText: 'assets/image/campus_supply.jpg',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use an image already committed under assets/image/. The file is bundled with the Flutter app and is never uploaded to Firebase Storage.',
                  style: TextStyle(color: muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remove image'),
            ),
            FilledButton(
              onPressed: () async {
                await FirestoreDatabase.instance.saveHomeSettings(
                  heroImageUrl: controller.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Future<void> _seedCatalog() async {
    try {
      final added = await seedStarterCatalog();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Starter catalog is already set up. No existing data was changed.'
                : 'Starter catalog added: $added new records.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not seed catalog: $e')),
      );
    }
  }

  Widget _metric(String value, String label, IconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7E2D9))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: blue),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: muted, fontSize: 11)),
    ]),
  );

  Widget _menu(BuildContext context, IconData icon, String title, String subtitle, AdminSection section) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7E2D9))),
    child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section))),
      leading: CircleAvatar(backgroundColor: const Color(0xFFEAF2FF), child: Icon(icon, color: blue)),
      title: Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: muted),
    ),
  );
}
