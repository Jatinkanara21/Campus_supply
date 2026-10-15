import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_bottom_nav.dart';

import '../database/firestore_database.dart';
import '../widgets/app_image.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const softBlue = Color(0xFFEAF2FF);
  static const yellow = Color(0xFFFFC66D);

  int quantity = 1;
  bool saving = false;
  bool wishlistSaving = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final product = args is Map
        ? Map<String, dynamic>.from(args)
        : <String, dynamic>{};

    if (product.isEmpty) {
      return _emptyProductPage(context);
    }

    final name = (product['name'] ?? '').toString().trim();
    final description = (product['description'] ?? '').toString().trim();
    final category = (product['category'] ?? '').toString().trim();
    final storedImage = (product['imageUrl'] ?? '').toString().trim();
    final imageSource =
        storedImage.isNotEmpty ? storedImage : _fallbackImageUrl(product);
    final rawPrice = product['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse((rawPrice ?? '').toString());
    final rawRating = product['rating'];
    final ratingText = rawRating?.toString().trim() ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final productId = product['id']?.toString();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          final imageHeight = wide
              ? 460.0
              : constraints.maxWidth >= 560
                  ? 390.0
                  : 310.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth >= 850 ? 30 : 16,
              12,
              constraints.maxWidth >= 850 ? 30 : 16,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 11,
                            child: _imagePanel(imageSource, imageHeight),
                          ),
                          const SizedBox(width: 34),
                          Expanded(
                            flex: 10,
                            child: _details(
                              context: context,
                              product: product,
                              name: name,
                              description: description,
                              category: category,
                              price: price,
                              ratingText: ratingText,
                              uid: uid,
                              productId: productId,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _imagePanel(imageSource, imageHeight),
                          const SizedBox(height: 24),
                          _details(
                            context: context,
                            product: product,
                            name: name,
                            description: description,
                            category: category,
                            price: price,
                            ratingText: ratingText,
                            uid: uid,
                            productId: productId,
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _emptyProductPage(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Product details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: softBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: blue,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Product details unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a product from the shop to see its details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/shop'),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Explore products'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  String _fallbackImageUrl(Map<String, dynamic> product) {
    final value = ((product['name'] ?? '').toString() +
            ' ' +
            (product['category'] ?? '').toString())
        .toLowerCase();

    if (value.contains('backpack') || value.contains('bag')) {
      return 'assets/image/products/backpack.svg';
    }
    if (value.contains('headphone')) {
      return 'assets/image/products/headphones.svg';
    }
    if (value.contains('bottle') || value.contains('tumbler')) {
      return 'assets/image/products/bottle.svg';
    }
    if (value.contains('calculator')) {
      return 'assets/image/products/calculator.svg';
    }
    if (value.contains('lamp')) {
      return 'assets/image/products/lamp.svg';
    }
    if (value.contains('sleeve')) {
      return 'assets/image/products/sleeve.svg';
    }
    if (value.contains('pen')) {
      return 'assets/image/products/pen.svg';
    }
    return 'assets/image/products/notebook.svg';
  }

  Widget _imagePanel(String source, double height) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F8FF), Colors.white, Color(0xFFF8F6F0)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -55,
            right: -42,
            child: Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                color: Color(0x1A2563EB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -44,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: Color(0x24FFC66D),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: AppImage(
              source: source,
              fit: BoxFit.contain,
              placeholder: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              fallback: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: blue,
                  size: 76,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details({
    required BuildContext context,
    required Map<String, dynamic> product,
    required String name,
    required String description,
    required String category,
    required double? price,
    required String ratingText,
    required String? uid,
    required String? productId,
  }) {
    final displayName = name.isEmpty ? 'Product details' : name;
    final canUseActions = productId != null && productId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: softBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'PRODUCT DETAILS',
                style: TextStyle(
                  color: blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            if (category.isNotEmpty)
              Flexible(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            color: ink,
            fontSize: 32,
            height: 1.1,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (ratingText.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 20),
              const SizedBox(width: 5),
              Text(
                ratingText,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Rating',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ],
        if (price != null) ...[
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE8FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRICE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹' + price.toStringAsFixed(0),
                  style: const TextStyle(
                    color: blue,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (description.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'About this product',
            style: TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: muted, height: 1.65, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantity',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                ),
              ),
              _quantityButton(
                icon: Icons.remove_rounded,
                tooltip: 'Decrease quantity',
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
              ),
              SizedBox(
                width: 34,
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _quantityButton(
                icon: Icons.add_rounded,
                tooltip: 'Increase quantity',
                onPressed: () => setState(() => quantity++),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: saving || !canUseActions
                ? null
                : () => _addToCart(context, product),
            icon: saving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined),
            label: Text(saving ? 'Adding to cart...' : 'Add to cart'),
          ),
        ),
        const SizedBox(height: 10),
        _wishlistButton(
          context: context,
          product: product,
          uid: uid,
          productId: productId,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Continue shopping'),
          ),
        ),
      ],
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: blue,
        backgroundColor: softBlue,
        disabledForegroundColor: const Color(0xFFB7C3D4),
      ),
      icon: Icon(icon, size: 19),
    );
  }

  Widget _wishlistButton({
    required BuildContext context,
    required Map<String, dynamic> product,
    required String? uid,
    required String? productId,
  }) {
    final stream = uid == null
        ? Stream<List<Map<String, dynamic>>>.value(
            <Map<String, dynamic>>[],
          )
        : FirestoreDatabase.instance.watchWishlist(uid);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final wishlisted = productId != null &&
            (snapshot.data ?? <Map<String, dynamic>>[]).any(
              (item) => item['productId']?.toString() == productId,
            );

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: wishlistSaving || productId == null || productId.isEmpty
                ? null
                : () => _toggleWishlist(
                      context: context,
                      product: product,
                      uid: uid,
                      productId: productId,
                      currentlySaved: wishlisted,
                    ),
            icon: wishlistSaving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    wishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: wishlisted ? const Color(0xFFFF8066) : blue,
                  ),
            label: Text(
              wishlistSaving
                  ? 'Updating wishlist...'
                  : wishlisted
                      ? 'Remove from wishlist'
                      : 'Add to wishlist',
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleWishlist({
    required BuildContext context,
    required Map<String, dynamic> product,
    required String? uid,
    required String productId,
    required bool currentlySaved,
  }) async {
    if (uid == null) {
      await Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => wishlistSaving = true);
    try {
      await FirestoreDatabase.instance.toggleWishlist(
        uid: uid,
        productId: productId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlySaved ? 'Removed from wishlist' : 'Added to wishlist',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update wishlist. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => wishlistSaving = false);
    }
  }

  Future<void> _addToCart(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = product['id']?.toString();

    if (uid == null) {
      await Navigator.pushNamed(context, '/login');
      return;
    }
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product cannot be added right now.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await FirestoreDatabase.instance.addToCart(
        uid: uid,
        productId: id,
        quantity: quantity,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not add to cart. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
