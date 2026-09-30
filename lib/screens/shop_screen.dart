import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const cream = Color(0xFFFAF8F3), ink = Color(0xFF172033), blue = Color(0xFF2563EB), coral = Color(0xFFF97368), muted = Color(0xFF707681), border = Color(0xFFE7E2D9);
  String category = 'All';
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Shop', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/wishlist'), icon: const Icon(Icons.favorite_border_rounded)),
          IconButton(onPressed: () => Navigator.pushNamed(context, '/cart'), icon: const Icon(Icons.shopping_bag_outlined)),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            return _message(
              'Could not load products.\\n\\n$error\\n\\n'
              'Check that Firestore is created and firestore.rules are deployed.',
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!;
          final categories = <String>{'All', ...products.map((p) => (p['category'] ?? 'General').toString())}.toList();
          final filtered = products.where((p) {
            final matchesCategory = category == 'All' || (p['category'] ?? 'General') == category;
            final text = '${p['name'] ?? ''} ${p['description'] ?? ''}'.toLowerCase();
            return matchesCategory && text.contains(query.toLowerCase());
          }).toList();

          return LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050 ? 4 : constraints.maxWidth >= 700 ? 3 : 2;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(24)),
                  child: const Row(children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFFFACC15), size: 24),
                    SizedBox(width: 10),
                    Expanded(child: Text('Find your next campus essential.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
                  ]),
                ),
                const SizedBox(height: 16),
                TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search_rounded, color: blue), suffixIcon: query.isEmpty ? null : IconButton(onPressed: () => setState(() => query = ''), icon: const Icon(Icons.clear_rounded)))),
                const SizedBox(height: 14),
                SizedBox(height: 44, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) {
                  final c = categories[i]; final selected = c == category;
                  return ChoiceChip(label: Text(c), selected: selected, onSelected: (_) => setState(() => category = c), selectedColor: blue, labelStyle: TextStyle(color: selected ? Colors.white : ink, fontWeight: FontWeight.w700, fontSize: 11));
                })),
                const SizedBox(height: 18),
                if (filtered.isEmpty) _message(products.isEmpty ? 'No products yet. Add products from Admin Dashboard.' : 'No products match your search.')
                else GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: columns == 2 ? .72 : .82),
                  itemBuilder: (_, i) => _card(context, filtered[i]),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> p) {
    final price = p['price'];
    final imageUrl = (p['imageUrl'] ?? '').toString();
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.pushNamed(context, '/product', arguments: p),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF5F3EE), borderRadius: BorderRadius.circular(17)), clipBehavior: Clip.antiAlias, child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_rounded, color: blue, size: 66)) : const Icon(Icons.inventory_2_rounded, color: blue, size: 66))),
          const SizedBox(height: 10),
          Text((p['name'] ?? 'Product').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 15), const SizedBox(width: 3), Text((p['rating'] ?? 'New').toString(), style: const TextStyle(color: muted, fontSize: 11)), const Spacer(), Text(price == null ? '₹0' : '₹$price', style: const TextStyle(color: blue, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 40, child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/product', arguments: p), child: const Text('View product'))),
        ]),
      ),
    );
  }

  Widget _message(String text) => Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)), child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.4))));
}
