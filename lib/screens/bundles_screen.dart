import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/firestore_database.dart';
import '../widgets/app_image.dart';

class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFFC66D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Student Bundles',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Shop',
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            icon: const Icon(Icons.grid_view_rounded, color: ink),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchBundles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 42, color: muted),
                    SizedBox(height: 12),
                    Text(
                      'Unable to load bundles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: blue),
            );
          }

          final bundles = snapshot.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth < 600 ? 16.0 : 28.0;

                  return ListView(
                    padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 40),
                    children: [
                      _heroBanner(),
                      const SizedBox(height: 26),
                      if (bundles.isEmpty)
                        _emptyState()
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Find your perfect kit',
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 22,
                                      letterSpacing: -.4,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Ready-to-go essentials for campus life.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border),
                              ),
                              child: Text(
                                bundles.length.toString() + (bundles.length == 1 ? ' KIT' : ' KITS'),
                                style: const TextStyle(
                                  color: blue,
                                  fontSize: 10,
                                  letterSpacing: .5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, gridConstraints) {
                            final twoColumns = gridConstraints.maxWidth >= 790;
                            final cardWidth = twoColumns
                                ? (gridConstraints.maxWidth - 18) / 2
                                : gridConstraints.maxWidth;

                            return Wrap(
                              spacing: 18,
                              runSpacing: 18,
                              children: bundles.map((bundle) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: _bundleCard(context, bundle),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final titleSize = constraints.maxWidth < 360 ? 26.0 : 30.0;

        return Container(
          padding: EdgeInsets.all(compact ? 21 : 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [blue, Color(0xFF1D4ED8), Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x252563EB),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x55FFFFFF)),
                      ),
                      child: const Text(
                        'CURATED FOR CAMPUS LIFE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: .85,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Built for busy students.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        height: 1.08,
                        letterSpacing: -.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Smart kits for projects, classes and exam season — spend less time searching and more time creating.',
                      style: TextStyle(
                        color: Color(0xFFDDE8FF),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 22),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: const Color(0x24FFFFFF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(
                        Icons.backpack_rounded,
                        color: ink,
                        size: 54,
                      ),
                      const Positioned(
                        top: 13,
                        right: 13,
                        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4CE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF9A7600),
              size: 35,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'No bundles yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Admins can add student bundles from the dashboard. Check back soon for ready-to-go campus kits.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _bundleCard(BuildContext context, Map<String, dynamic> bundle) {
    final rawPrice = bundle['price'];
    final priceLabel = rawPrice == null
        ? 'Price unavailable'
        : '₹' + (rawPrice is num ? rawPrice.toStringAsFixed(0) : rawPrice.toString());
    final badge = (bundle['badge'] ?? 'Student bundle').toString();
    final name = (bundle['name'] ?? bundle['title'] ?? 'Bundle').toString();
    final description = (bundle['description'] ?? 'Curated campus essentials.').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08111827),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 162,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFFFFF8D9),
                  padding: const EdgeInsets.all(18),
                  child: _bundleImage(bundle),
                ),
                Positioned(
                  top: 13,
                  left: 13,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 210),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: yellow,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 7, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      badge.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF755600),
                        fontSize: 9,
                        letterSpacing: .55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 18,
                    height: 1.2,
                    letterSpacing: -.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 12, height: 1.45),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, color: blue, size: 17),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: rawPrice == null ? muted : blue,
                          fontSize: rawPrice == null ? 12 : 23,
                          letterSpacing: rawPrice == null ? 0 : -.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (rawPrice != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BUNDLE',
                          style: TextStyle(
                            color: blue,
                            fontSize: 8,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, buttonConstraints) {
                    final stackButtons = buttonConstraints.maxWidth < 330;

                    final viewButton = OutlinedButton(
                      onPressed: () => _showBundleDetails(context, bundle),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: blue,
                        side: const BorderSide(color: Color(0xFFBFCEEA)),
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'View details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    );

                    final buyButton = FilledButton.icon(
                      onPressed: () => _buyBundle(context, bundle),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text(
                        'Buy bundle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );

                    if (stackButtons) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: double.infinity, child: viewButton),
                          const SizedBox(height: 9),
                          SizedBox(width: double.infinity, child: buyButton),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: viewButton),
                        const SizedBox(width: 9),
                        Expanded(child: buyButton),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bundleImage(Map<String, dynamic> bundle) {
    final stored = (bundle['imageUrl'] ?? '').toString().trim();
    final name = (bundle['name'] ?? bundle['title'] ?? '').toString().toLowerCase();

    final fallback = name.contains('exam')
        ? 'assets/image/products/calculator.svg'
        : name.contains('campus') || name.contains('daily')
            ? 'assets/image/products/backpack.svg'
            : name.contains('study')
                ? 'assets/image/products/lamp.svg'
                : 'assets/image/products/notebook.svg';

    return AppImage(
      source: stored.isNotEmpty ? stored : fallback,
      fit: BoxFit.contain,
      fallback: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF9A7600),
        size: 40,
      ),
    );
  }

  Future<void> _buyBundle(
    BuildContext context,
    Map<String, dynamic> bundle,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to buy a bundle.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    final rawIds = bundle['productIds'];
    var productIds = rawIds is List
        ? rawIds.map((id) => id.toString()).where((id) => id.trim().isNotEmpty).toSet().toList()
        : <String>[];

    if (productIds.isEmpty) {
      final bundleName = (bundle['name'] ?? bundle['title'] ?? '').toString().toLowerCase();
      if (bundleName.contains('architecture')) {
        productIds = ['premium_notebook', 'gel_pen_pack', 'laptop_sleeve'];
      } else if (bundleName.contains('first-year') || bundleName.contains('first year') || bundleName.contains('essential')) {
        productIds = ['premium_notebook', 'gel_pen_pack', 'campus_pro_backpack'];
      } else if (bundleName.contains('exam')) {
        productIds = ['premium_notebook', 'gel_pen_pack', 'scientific_calculator'];
      }
    }

    if (productIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This bundle has no products configured yet.')),
      );
      return;
    }

    try {
      for (final productId in productIds) {
        await FirestoreDatabase.instance.addToCart(
          uid: uid,
          productId: productId,
          quantity: 1,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productIds.length.toString() + ' bundle items added to your bag.'),
          action: SnackBarAction(
            label: 'VIEW BAG',
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add bundle to bag: ' + e.toString())),
      );
    }
  }

  Future<void> _showBundleDetails(
    BuildContext context,
    Map<String, dynamic> bundle,
  ) async {
    final name = (bundle['name'] ?? bundle['title'] ?? 'Student Bundle').toString();
    final description = (bundle['description'] ?? 'Curated campus essentials.').toString();
    final rawPrice = bundle['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse((rawPrice ?? '').toString());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          name,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 14),
              if (price != null)
                Text(
                  'Bundle price: ₹' + price.toStringAsFixed(0),
                  style: const TextStyle(
                    color: blue,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'This bundle adds all configured products to your bag in one click.',
                style: TextStyle(color: muted, height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _buyBundle(context, bundle);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Buy now'),
          ),
        ],
      ),
    );
  }
}
