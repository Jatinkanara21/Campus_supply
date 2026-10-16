import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/firestore_database.dart';
import '../widgets/app_image.dart';
import '../widgets/customer_bottom_nav.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const paleBlue = Color(0xFFEAF2FF);
  static const coral = Color(0xFFF06464);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          title: const Text(
            'Wishlist',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: _pageBody(
          count: null,
          child: _state(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to view your wishlist',
            subtitle: 'Your saved products will be waiting here.',
            action: 'Sign in',
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ),
        bottomNavigationBar: const CustomerBottomNav(),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text(
          'Wishlist',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Explore products',
            onPressed: () => Navigator.pushNamed(context, '/shop'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchWishlist(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _pageBody(
              count: null,
              child: _state(
                icon: Icons.cloud_off_outlined,
                title: 'Wishlist unavailable',
                subtitle: 'Please try again in a moment.',
              ),
            );
          }

          if (!snapshot.hasData) {
            return _pageBody(
              count: null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 52),
                child: Center(child: CircularProgressIndicator(color: blue)),
              ),
            );
          }

          final wishes = snapshot.data!;

          if (wishes.isEmpty) {
            return _pageBody(
              count: 0,
              child: _state(
                icon: Icons.favorite_border_rounded,
                title: 'Nothing saved yet',
                subtitle: 'Tap the heart on products you want to keep.',
                action: 'Explore products',
                onPressed: () => Navigator.pushNamed(context, '/shop'),
              ),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productsSnapshot) {
              if (productsSnapshot.hasError) {
                return _pageBody(
                  count: wishes.length,
                  child: _state(
                    icon: Icons.cloud_off_outlined,
                    title: 'Products unavailable',
                    subtitle: 'Your saved products could not be displayed right now.',
                  ),
                );
              }

              if (!productsSnapshot.hasData) {
                return _pageBody(
                  count: wishes.length,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 52),
                    child: Center(child: CircularProgressIndicator(color: blue)),
                  ),
                );
              }

              final byId = {
                for (final product in productsSnapshot.data!)
                  product['id'].toString(): product,
              };

              return _pageBody(
                count: wishes.length,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1080
                        ? 3
                        : constraints.maxWidth >= 680
                            ? 2
                            : 1;

                    final ratio = columns == 1
                        ? 2.05
                        : columns == 2
                            ? 1.32
                            : 1.08;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: wishes.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: ratio,
                      ),
                      itemBuilder: (context, index) {
                        final wish = wishes[index];
                        final productId = wish['productId']?.toString();
                        final product = byId[productId];
                        return _wishlistCard(
                          context: context,
                          uid: uid,
                          productId: productId,
                          product: product,
                          vertical: columns > 1,
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _pageBody({required int? count, required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 1000
            ? 28.0
            : constraints.maxWidth >= 600
                ? 22.0
                : 16.0;

        return ListView(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _pageHeader(count),
                    const SizedBox(height: 20),
                    child,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pageHeader(int? count) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF2FF), Color(0xFFF5F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7F8)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: coral,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your saved favourites',
                  style: TextStyle(
                    color: ink,
                    fontSize: 23,
                    height: 1.15,
                    letterSpacing: -.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Keep the products you like all in one place.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCE7F8)),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _wishlistCard({
    required BuildContext context,
    required String uid,
    required String? productId,
    required Map<String, dynamic>? product,
    required bool vertical,
  }) {
    final name = (product?['name'] ?? 'Product no longer available').toString();
    final image = (product?['imageUrl'] ?? '').toString();
    final rawPrice = product?['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse((rawPrice ?? '').toString());

    final imageArea = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: AppImage(
        source: image,
        fit: BoxFit.contain,
        fallback: const Center(
          child: Icon(Icons.inventory_2_rounded, color: blue, size: 34),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ink,
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          product == null
              ? 'No longer available'
              : price == null
                  ? 'Price unavailable'
                  : '₹' + price.toStringAsFixed(0),
          style: TextStyle(
            color: product == null || price == null ? muted : blue,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: productId == null
                    ? null
                    : () async {
                        try {
                          await FirestoreDatabase.instance.toggleWishlist(
                            uid: uid,
                            productId: productId,
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not update your wishlist. Try again.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.favorite_border_rounded, size: 17),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: coral,
                  side: const BorderSide(color: Color(0xFFF6CECE)),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: productId == null || product == null
                    ? null
                    : () async {
                        try {
                          await FirestoreDatabase.instance.addToCart(
                            uid: uid,
                            productId: productId,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name added to your cart.'),
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/cart'),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not add this item to your cart. Try again.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.shopping_bag_outlined, size: 17),
                label: const Text('Add to cart'),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07172554),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: imageArea),
                const SizedBox(height: 12),
                Expanded(flex: 2, child: details),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 4, child: imageArea),
                const SizedBox(width: 13),
                Expanded(flex: 6, child: details),
              ],
            ),
    );
  }

  Widget _state({
    required IconData icon,
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: paleBlue,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: blue, size: 34),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          if (action != null && onPressed != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
              ),
              child: Text(action),
            ),
          ],
        ],
      ),
    );
  }
}
