import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../database/firestore_database.dart';
import '../database/firestore_seed.dart';
import '../widgets/app_image.dart';
import '../services/auth_service.dart';
import '../services/image_storage_service.dart';
import 'admin_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFFC66D);
  static const muted = Color(0xFF64748B);

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
      return const Scaffold(
        backgroundColor: cream,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: blue),
              SizedBox(height: 16),
              Text(
                'Loading admin dashboard...',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
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
      drawer: MediaQuery.sizeOf(context).width < 900
          ? Drawer(backgroundColor: Colors.white, child: SafeArea(child: _buildSidebar(context, compact: true)))
          : null,
      body: LayoutBuilder(
        builder: (context, pageConstraints) {
          final wide = pageConstraints.maxWidth >= 1100;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) SizedBox(width: 238, child: _buildSidebar(context)),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: const BoxDecoration(
                        color: cream,
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(children: [
                        if (!wide) Builder(builder: (ctx) => IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu_rounded, color: ink),
                          tooltip: 'Open navigation',
                        )),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Admin dashboard', style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900)),
                            const Text('A quick look at your campus store.', style: TextStyle(color: muted, fontSize: 12)),
                          ],
                        )),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: blue,
                            side: const BorderSide(color: Color(0xFFB9D0FF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 440;
                          final greeting = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, $name',
                                maxLines: compact ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 19 : 23,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Campus Supply administration',
                                style: TextStyle(color: Color(0xFFDDE8FF), fontSize: 13, height: 1.35),
                              ),
                            ],
                          );
                          return Container(
                            padding: EdgeInsets.all(compact ? 18 : 24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [blue, Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: compact
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const CircleAvatar(
                                        radius: 24,
                                        backgroundColor: yellow,
                                        child: Icon(Icons.admin_panel_settings_rounded, color: ink, size: 26),
                                      ),
                                      const SizedBox(height: 14),
                                      greeting,
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 29,
                                        backgroundColor: yellow,
                                        child: Icon(Icons.admin_panel_settings_rounded, color: ink, size: 30),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(child: greeting),
                                    ],
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'DASHBOARD OVERVIEW',
                        style: TextStyle(
                          color: blue,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Your store at a glance',
                        style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final columns = width >= 1000 ? 4 : 2;
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: width < 390 ? 1.55 : (width < 600 ? 1.8 : (columns == 4 ? 1.28 : 1.7)),
                            children: [
                              _metric(products.data?.docs.length.toString() ?? '0', 'Products', Icons.inventory_2_outlined),
                              _metric(orders.data?.docs.length.toString() ?? '0', 'Orders', Icons.receipt_long_outlined),
                              _metric(users.data?.docs.length.toString() ?? '0', 'Users', Icons.people_outline_rounded),
                              _metric('5', 'Modules', Icons.dashboard_customize_outlined),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 520;
                            final information = const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Starter catalog', style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                                SizedBox(height: 4),
                                Text(
                                  'Add ready-to-use products, categories and bundles. Existing records are never overwritten.',
                                  style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                                ),
                              ],
                            );
                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    const CircleAvatar(backgroundColor: Color(0xFFFFF4C7), child: Icon(Icons.auto_awesome_rounded, color: ink)),
                                    const SizedBox(width: 12),
                                    const Expanded(child: Text('Starter catalog', style: TextStyle(color: ink, fontWeight: FontWeight.w900))),
                                  ]),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Add ready-to-use products, categories and bundles. Existing records are never overwritten.',
                                    style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _seedCatalog, child: const Text('Seed catalog'))),
                                ],
                              );
                            }
                            return Row(children: [
                              const CircleAvatar(backgroundColor: Color(0xFFFFF4C7), child: Icon(Icons.auto_awesome_rounded, color: ink)),
                              const SizedBox(width: 12),
                              Expanded(child: information),
                              const SizedBox(width: 12),
                              FilledButton(onPressed: _seedCatalog, child: const Text('Seed')),
                            ]);
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      _heroSettingsCard(),
                      const SizedBox(height: 28),
                      const Text(
                        'MANAGE YOUR STORE',
                        style: TextStyle(
                          color: blue,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Quick access',
                        style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 760 ? 2 : 1;
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 10,
                            childAspectRatio: columns == 2 ? 2.5 : 4.6,
                            children: [
                              _menu(context, Icons.inventory_2_outlined, 'Products', 'Add, edit and remove products', AdminSection.products),
                              _menu(context, Icons.category_outlined, 'Categories', 'Manage product categories', AdminSection.categories),
                              _menu(context, Icons.auto_awesome_outlined, 'Bundles', 'Manage student bundles', AdminSection.bundles),
                              _menu(context, Icons.receipt_long_outlined, 'Orders', 'Review and update order status', AdminSection.orders),
                              _menu(context, Icons.people_outline_rounded, 'Users', 'View users and manage roles', AdminSection.users),
                              _menu(context, Icons.rate_review_outlined, 'Reviews', 'Moderate customer reviews', AdminSection.reviews),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
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
          ),
                    )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool compact = false}) {
    Widget item(IconData icon, String title, {AdminSection? section, bool selected = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Material(
          color: selected ? const Color(0xFFE2EDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: section == null ? null : () {
              if (compact) Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section)));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Row(children: [
                Icon(icon, size: 21, color: selected ? blue : ink),
                const SizedBox(width: 13),
                Expanded(child: Text(title, style: TextStyle(color: selected ? blue : ink, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, fontSize: 13))),
              ]),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Color(0xFFE2E8F0)))),
      padding: const EdgeInsets.fromLTRB(17, 24, 17, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 27)),
          const SizedBox(width: 11),
          const Expanded(child: Text('Campus\\nSupply', style: TextStyle(color: ink, fontSize: 19, height: 1.05, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 32),
        item(Icons.dashboard_rounded, 'Overview', selected: true),
        item(Icons.inventory_2_outlined, 'Products', section: AdminSection.products),
        item(Icons.category_outlined, 'Categories', section: AdminSection.categories),
        item(Icons.sell_outlined, 'Bundles', section: AdminSection.bundles),
        item(Icons.shopping_cart_outlined, 'Orders', section: AdminSection.orders),
        item(Icons.people_outline_rounded, 'Users', section: AdminSection.users),
        item(Icons.star_border_rounded, 'Reviews', section: AdminSection.reviews),
        const Spacer(),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        Row(children: [
          CircleAvatar(backgroundColor: blue, child: Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 12)),
            const Text('Administrator', style: TextStyle(color: muted, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthService.logout();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB42318), backgroundColor: const Color(0xFFFFF0F2), side: BorderSide.none, minimumSize: const Size.fromHeight(45), alignment: Alignment.centerLeft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
        ),
      ]),
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
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final preview = Container(
                width: compact ? 76.0 : 92.0,
                height: compact ? 64.0 : 72.0,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.image_outlined, color: blue, size: 30)
                    : _adminAssetImage(imageUrl),
              );
              final details = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Homepage hero image', style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15)),
                  SizedBox(height: 5),
                  Text(
                    'Remove the static artwork. Set the hero image with a URL or upload an image file.',
                    style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                  ),
                ],
              );
              final manageButton = FilledButton.icon(
                onPressed: () => _editHeroSettings(imageUrl),
                icon: const Icon(Icons.image_rounded, size: 18),
                label: const Text('Manage'),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        preview,
                        const SizedBox(width: 12),
                        const Expanded(child: Text(
                          'Homepage hero image',
                          style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15),
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Remove the static artwork. Set the hero image with a URL or upload an image file.',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: manageButton),
                  ],
                );
              }
              return Row(
                children: [
                  preview,
                  const SizedBox(width: 14),
                  Expanded(child: details),
                  const SizedBox(width: 12),
                  manageButton,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _adminAssetImage(String path) {
    return AppImage(
      source: path,
      fit: BoxFit.cover,
      fallback: const Icon(Icons.broken_image_outlined, color: blue),
    );
  }

  Future<void> _editHeroSettings(String currentAsset) async {
    final controller = TextEditingController(text: currentAsset);
    Uint8List? previewBytes;
    bool uploading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Homepage hero image'),
          content: SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width < 584
                              ? MediaQuery.sizeOf(dialogContext).width - 64
                              : 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (previewBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      previewBytes!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (previewBytes != null) const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          try {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 90,
                              maxWidth: 1800,
                              maxHeight: 1000,
                            );
                            if (file == null) return;

                            final bytes = await file.readAsBytes();
                            setDialogState(() {
                              previewBytes = bytes;
                              uploading = true;
                            });

                            final url = await ImageStorageService.upload(
                              bytes: bytes,
                              folder: 'hero',
                              fileName: file.name,
                            );

                            controller.text = url;
                            setDialogState(() => uploading = false);
                          } catch (e) {
                            setDialogState(() => uploading = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Hero image upload failed: $e')),
                              );
                            }
                          }
                        },
                  icon: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(uploading ? 'Uploading...' : 'Choose & upload image'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uploaded images are stored in Firebase Storage. You can also paste a public image URL.',
                  style: TextStyle(color: muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: uploading
                  ? null
                  : () {
                      controller.clear();
                      Navigator.pop(dialogContext);
                    },
              child: const Text('Remove image'),
            ),
            TextButton(
              onPressed: uploading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: uploading
                  ? null
                  : () async {
                      try {
                        await FirestoreDatabase.instance.saveHomeSettings(
                          heroImageUrl: controller.text.trim(),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Hero image save failed: $e')),
                          );
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
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
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF2F6FF)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDCE6F8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: blue, size: 21),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w900, height: 1.1),
        ),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _menu(BuildContext context, IconData icon, String title, String subtitle, AdminSection section) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section))),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFEAF2FF),
        child: Icon(icon, color: blue, size: 21),
      ),
      title: Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: muted, fontSize: 12, height: 1.35)),
      trailing: const Icon(Icons.chevron_right_rounded, color: muted),
    ),
  );
}
