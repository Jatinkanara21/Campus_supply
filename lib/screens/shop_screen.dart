import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _routeArgsRead = false;
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF707681);
  static const border = Color(0xFFE7E2D9);

  String category = 'All';
  String query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsRead) return;
    _routeArgsRead = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      query = (args['query'] ?? '').toString();
      category = (args['category'] ?? 'All').toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Shop', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/wishlist'),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchCategories(),
        builder: (context, categorySnapshot) {
          if (categorySnapshot.hasError) {
            return _message('Could not load categories.\n\n${categorySnapshot.error}');
          }
          if (!categorySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categoryDocs = categorySnapshot.data!;
          final categoryNames = <String>[
            'All',
            ...categoryDocs.map(
              (c) => (c['name'] ?? c['slug'] ?? 'Category').toString(),
            ),
          ];

          if (!categoryNames.contains(category)) {
            category = 'All';
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreDatabase.instance.watchProducts(),
            builder: (context, productSnapshot) {
              if (productSnapshot.hasError) {
                return _message(
                  'Could not load products.\n\n${productSnapshot.error}\n\n'
                  'Check Firestore and deployed security rules.',
                );
              }
              if (!productSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = productSnapshot.data!;
              final normalizedQuery = query.trim().toLowerCase();
              final filtered = products.where((p) {
                final productCategory = (p['category'] ?? '').toString().trim();
                final matchesCategory =
                    category == 'All' ||
                    productCategory.toLowerCase() == category.toLowerCase();
                final text =
                    '${p['name'] ?? ''} ${p['description'] ?? ''}'.toLowerCase();
                return matchesCategory && text.contains(normalizedQuery);
              }).toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 4
                      : constraints.maxWidth >= 700
                          ? 3
                          : 2;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFFACC15),
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Find your next campus essential.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                          hintText: query.isEmpty ? 'Search products...' : query,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: blue,
                          ),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () => setState(() => query = ''),
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categoryNames.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final name = categoryNames[i];
                            final selected = name == category;
                            return ChoiceChip(
                              label: Text(name),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => category = name),
                              selectedColor: blue,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        _message(
                          products.isEmpty
                              ? 'No products yet. Add products from Admin Dashboard.'
                              : 'No products match this category or search.',
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: columns == 2 ? .72 : .82,
                          ),
                          itemBuilder: (_, i) => _card(context, filtered[i]),
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

  Widget _card(BuildContext context, Map<String, dynamic> p) {
    final price = p['price'];
    final imageUrl = (p['imageUrl'] ?? '').toString().trim();
    final displayImageUrl =
        imageUrl.isNotEmpty ? imageUrl : _fallbackImageUrl(p);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.pushNamed(context, '/product', arguments: p),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(17),
                ),
                clipBehavior: Clip.antiAlias,
                child: displayImageUrl.isNotEmpty
                    ? Image.network(
                        displayImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: blue,
                            size: 50,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: blue,
                          size: 58,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              (p['name'] ?? 'Product').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF4B400),
                  size: 15,
                ),
                const SizedBox(width: 3),
                Text(
                  (p['rating'] ?? 'New').toString(),
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  price == null ? '₹0' : '₹$price',
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/product', arguments: p),
                child: const Text('View product'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.4),
          ),
        ),
      );
}

String _fallbackImageUrl(Map<String, dynamic> product) {
  final value =
      '${product['name'] ?? ''} ${product['category'] ?? ''}'.toLowerCase();

  if (value.contains('backpack') || value.contains('bag')) {
    return 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=85';
  }
  if (value.contains('headphone')) {
    return 'https://images.unsplash.com/photo-1558365916-848463c5d803?auto=format&fit=crop&w=900&q=85';
  }
  if (value.contains('bottle') || value.contains('tumbler')) {
    return 'https://images.unsplash.com/photo-1561180796-dbaa5caf76e0?auto=format&fit=crop&w=900&q=85';
  }
  if (value.contains('notebook') ||
      value.contains('stationery') ||
      value.contains('pen')) {
    return 'https://images.unsplash.com/photo-1743760521201-ddb298df18cd?auto=format&fit=crop&w=900&q=85';
  }
  return '';
}
