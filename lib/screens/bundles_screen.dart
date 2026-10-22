import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_bottom_nav.dart';

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
                            final twoColumns = gridConstraints.maxWidth >= 760;
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
      bottomNavigationBar: const CustomerBottomNav(),
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
                      'Smart kits for projects, classes and exam season. Spend less time searching and more time creating.',
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
            'There are no student bundles available right now. Please check back soon for ready-to-go campus kits.',
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE5F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B172554),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF4F7FF), Color(0xFFFFF7DD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  right: -28,
                  bottom: -52,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Color(0x30FFFFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                  child: _bundleImage(bundle),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 210),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFF4D98C)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      badge.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF795A05),
                        fontSize: 9,
                        letterSpacing: .55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xEFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: blue,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 19,
                    height: 1.2,
                    letterSpacing: -.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 36,
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 12, height: 1.45),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FF),
                    border: Border.all(color: const Color(0xFFE2EBFC)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.sell_outlined, color: blue, size: 18),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BUNDLE PRICE',
                              style: TextStyle(
                                color: muted,
                                fontSize: 9,
                                letterSpacing: .7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: rawPrice == null ? muted : blue,
                                fontSize: rawPrice == null ? 12 : 22,
                                height: 1.05,
                                letterSpacing: -.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (rawPrice != null)
                        const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 19),
                    ],
                  ),
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
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
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
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
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
                        const SizedBox(width: 10),
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
    final productIds = rawIds is List
        ? rawIds.map((id) => id.toString().trim()).where((id) => id.isNotEmpty).toSet().toList()
        : <String>[];
    if (productIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This bundle needs included products. Please ask the store admin to update it.')),
      );
      return;
    }
    try {
      await FirestoreDatabase.instance.addBundleToCart(uid: uid, bundle: bundle);
      if (!context.mounted) return;
      final name = (bundle['name'] ?? bundle['title'] ?? 'Student Bundle').toString();
      final rawPrice = bundle['price'];
      final price = rawPrice is num ? rawPrice.toDouble() : double.tryParse((rawPrice ?? '').toString()) ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added to your bag at ₹${price.toStringAsFixed(0)}.'),
          action: SnackBarAction(label: 'VIEW BAG', onPressed: () => Navigator.pushNamed(context, '/cart')),
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
    final badge = (bundle['badge'] ?? 'Student bundle').toString();
    final rawPrice = bundle['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse((rawPrice ?? '').toString());
    final priceLabel = price == null ? 'Price unavailable' : '₹' + price.toStringAsFixed(0);

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x990D1733),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5EAF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3008172F),
                  blurRadius: 36,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 190,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFEAF1FF), Color(0xFFFFF6D7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -22,
                          bottom: -58,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: const BoxDecoration(
                              color: Color(0x55FFFFFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                          child: _bundleImage(bundle),
                        ),
                        Positioned(
                          left: 18,
                          top: 17,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 220),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: const Color(0xFFE7D28F)),
                            ),
                            child: Text(
                              badge.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF795A05),
                                fontSize: 9,
                                letterSpacing: .6,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 14,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            child: IconButton(
                              tooltip: 'Close details',
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded, color: ink, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 23, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 24,
                                  height: 1.15,
                                  letterSpacing: -.55,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F5FF),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.backpack_outlined, color: blue, size: 21),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF566680),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FF),
                            border: Border.all(color: const Color(0xFFE2EBFC)),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(Icons.sell_outlined, color: blue, size: 21),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'BUNDLE PRICE',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 10,
                                        letterSpacing: .8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      priceLabel,
                                      style: TextStyle(
                                        color: price == null ? muted : blue,
                                        fontSize: price == null ? 13 : 25,
                                        height: 1.05,
                                        letterSpacing: -.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (price != null)
                                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: blue, size: 19),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This kit is added as one bundle at the listed price. Its included products stay grouped in your bag.',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 23),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackButtons = constraints.maxWidth < 330;
                            final closeButton = OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ink,
                                side: const BorderSide(color: Color(0xFFD4DCE9)),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            );
                            final buyButton = FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _buyBundle(context, bundle);
                              },
                              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                              label: const Text(
                                'Buy now',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: blue,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            );

                            if (stackButtons) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(width: double.infinity, child: buyButton),
                                  const SizedBox(height: 10),
                                  SizedBox(width: double.infinity, child: closeButton),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: closeButton),
                                const SizedBox(width: 12),
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
            ),
          ),
        ),
      ),
    );
  }
}
