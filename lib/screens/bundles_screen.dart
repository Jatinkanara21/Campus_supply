import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/app_image.dart';
import '../database/firestore_database.dart';

class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});

  static const cream = Color(0xFFF8F9FC);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFACC15);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE4E7EC);

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
              child: Text(
                'Unable to load bundles.',
                style: TextStyle(color: muted),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: blue),
            );
          }

          final bundles = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [blue, Color(0xFF1747B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Color(0x252563EB), blurRadius: 26, offset: Offset(0, 12))],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Built for busy students.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Smart kits for projects, classes and exam season — spend less time searching and more time creating.',
                      style: TextStyle(
                        color: Color(0xFFDDE8FF),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (bundles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      'No bundles yet. Admins can add bundles from the dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              else
                ...bundles.map((bundle) {
                  final price = bundle['price'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border),
                      boxShadow: const [BoxShadow(color: Color(0x08111827), blurRadius: 14, offset: Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 96,
                          height: 104,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7CC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _bundleImage(bundle),

                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (bundle['badge'] ?? 'Student bundle')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF9A7600),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .7,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (bundle['name'] ?? bundle['title'] ?? 'Bundle')
                                    .toString(),
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                (bundle['description'] ??
                                        'Curated campus essentials.')
                                    .toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                              if (price != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(
                                    '₹$price',
                                    style: const TextStyle(
                                      color: blue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showBundleDetails(context, bundle),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      child: const Text('View details'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _buyBundle(context, bundle),
                                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                                      label: const Text('Buy bundle'),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
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
    final productIds = rawIds is List
        ? rawIds.map((id) => id.toString()).toSet().toList()
        : <String>[];

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
    final description =
        (bundle['description'] ?? 'Curated campus essentials.').toString();
    final price = (bundle['price'] as num?)?.toDouble();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
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
                style: TextStyle(color: muted, height: 1.35),
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
