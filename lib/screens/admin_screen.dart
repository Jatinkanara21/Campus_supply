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
      return Scaffold(
        backgroundColor: cream,
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.shopping_bag_rounded, color: blue, size: 30),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: blue),
                ),
                SizedBox(height: 14),
                Text(
                  'Loading admin dashboard...',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!admin) {
      return Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: cream,
          title: const Text('Admin access'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, size: 34, color: blue),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Admin access required',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Set your Firebase users document role to admin before opening this page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final wide = pageConstraints.maxWidth >= 1100;
        return Scaffold(
          backgroundColor: cream,
          drawer: !wide
              ? Drawer(
                  backgroundColor: Colors.white,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: _buildSidebar(context, compact: true),
                    ),
                  ),
                )
              : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) SizedBox(width: 238, child: _buildSidebar(context)),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, wide: wide),
                    Expanded(child: _buildDashboardContent(context)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool wide}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 520;

    return Container(
      height: compact ? 76 : 94,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : (wide ? 30 : 22)),
      decoration: const BoxDecoration(
        color: cream,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!wide)
            Builder(
              builder: (scaffoldContext) => IconButton(
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: ink),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'Admin   /   Overview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                Text(
                  'Admin dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: compact ? 19 : 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'A quick look at your campus store.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (compact)
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, color: blue),
            )
          else
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: blue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFB9D0FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool compact = false}) {
    return AdminNavigationSidebar(
      selectedSection: null,
      adminName: name,
      compact: compact,
      onNavigate: (destination) {
        if (destination == null) return;
        void navigate() {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminManagementScreen(section: destination)),
          );
        }

        if (compact) {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
        } else {
          navigate();
        }
      },
      onSignOut: () async {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }

  Widget _buildWelcomeBanner(double width) {
    final compact = width < 480;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(compact ? 18 : 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 30,
              top: -32,
              child: Transform.rotate(
                angle: -0.7,
                child: Container(
                  width: 40,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0x267DB4FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -48,
              child: Transform.rotate(
                angle: -0.7,
                child: Container(
                  width: 32,
                  height: 132,
                  decoration: BoxDecoration(
                    color: const Color(0x267DB4FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: compact ? 54 : 72,
                  height: compact ? 54 : 72,
                  decoration: const BoxDecoration(color: yellow, shape: BoxShape.circle),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: ink,
                    size: compact ? 27 : 35,
                  ),
                ),
                SizedBox(width: compact ? 13 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: const Color(0xFFEAF2FF),
                          fontSize: compact ? 12 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$name!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 21 : 28,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Here's what's happening with Campus Supply today.",
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFEAF2FF),
                          fontSize: compact ? 11 : 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, products) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, orders) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, users) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final horizontalPadding = width >= 1100 ? 32.0 : (width >= 700 ? 24.0 : 14.0);
                    final statColumns = width >= 1000 ? 4 : (width < 350 ? 1 : 2);
                    final sideBySide = width >= 1080;

                    return ListView(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 30),
                      children: [
                        _buildWelcomeBanner(width),
                        const SizedBox(height: 22),
                        GridView.count(
                          crossAxisCount: statColumns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: statColumns == 4
                              ? 1.42
                              : (statColumns == 2 ? (width < 500 ? 1.12 : 1.4) : 3.0),
                          children: [
                            _metric(
                              products.data?.docs.length.toString() ?? '0',
                              'Products',
                              Icons.inventory_2_outlined,
                            ),
                            _metric(
                              orders.data?.docs.length.toString() ?? '0',
                              'Orders',
                              Icons.shopping_cart_outlined,
                            ),
                            _metric(
                              users.data?.docs.length.toString() ?? '0',
                              'Users',
                              Icons.people_outline_rounded,
                            ),
                            _metric('5', 'Modules', Icons.grid_view_rounded),
                          ],
                        ),
                        const SizedBox(height: 22),
                        if (sideBySide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildStoreSetupPanel()),
                              const SizedBox(width: 18),
                              Expanded(child: _buildQuickAccessPanel()),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildStoreSetupPanel(),
                              const SizedBox(height: 18),
                              _buildQuickAccessPanel(),
                            ],
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStoreSetupPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFFFFF0BF), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB77900), size: 25),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Store setup', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Keep your storefront looking its best.', style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStarterCatalogCard(),
          const SizedBox(height: 14),
          _heroSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildStarterCatalogCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440;
        const titleAndDescription = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Starter catalog', style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w900)),
            SizedBox(height: 5),
            Text(
              'Add ready-to-use products, categories and bundles.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD8E6FF)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(color: Color(0xFFE3EEFF), shape: BoxShape.circle),
                          child: const Icon(Icons.inventory_2_outlined, color: blue, size: 25),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: titleAndDescription),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _seedCatalog,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                        label: const Text('Seed catalog'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: Color(0xFFE3EEFF), shape: BoxShape.circle),
                      child: const Icon(Icons.inventory_2_outlined, color: blue, size: 25),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(child: titleAndDescription),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _seedCatalog,
                      child: const Text('Seed catalog'),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildQuickAccessPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quick access',
            style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 430 ? 2 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 2 ? 2.45 : 4.3,
                children: [
                  _menu(context, Icons.inventory_2_outlined, 'Products', 'Add, edit and remove items', AdminSection.products),
                  _menu(context, Icons.grid_view_rounded, 'Categories', 'Organize your catalog', AdminSection.categories),
                  _menu(context, Icons.sell_outlined, 'Bundles', 'Curated student essentials', AdminSection.bundles),
                  _menu(context, Icons.shopping_cart_outlined, 'Orders', 'Review and update status', AdminSection.orders),
                  _menu(context, Icons.people_outline_rounded, 'Users', 'Manage accounts and roles', AdminSection.users),
                ],
              );
            },
          ),
        ],
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
