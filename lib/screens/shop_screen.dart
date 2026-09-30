import 'package:flutter/material.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const coral = Color(0xFFF97368);
  static const yellow = Color(0xFFFACC15);
  static const muted = Color(0xFF707681);
  static const border = Color(0xFFE7E2D9);

  final products = const [
    ('Smooth Gel Pens', '₹149', Icons.edit_rounded, blue, 'Pens & Pencils', '4.8'),
    ('A5 Premium Sketchbook', '₹349', Icons.menu_book_rounded, Color(0xFF7C4DFF), 'Sketchbooks', '4.9'),
    ('Campus Drafting Set', '₹499', Icons.straighten_rounded, coral, 'Drafting Tools', '4.7'),
    ('Studio Marker Pack', '₹599', Icons.palette_rounded, Color(0xFF198754), 'Art Supplies', '4.8'),
    ('Focus Notebook', '₹229', Icons.book_rounded, Color(0xFF7450E8), 'Notebooks', '4.7'),
    ('Desk Cable Organizer', '₹299', Icons.devices_rounded, Color(0xFF087F8C), 'Tech Accessories', '4.6'),
  ];

  String category = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Pens & Pencils', 'Sketchbooks', 'Art Supplies', 'Drafting Tools', 'Notebooks', 'Tech Accessories'];
    final filtered = category == 'All'
        ? products
        : products.where((p) => p.$5 == category).toList();

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1050 ? 4 : constraints.maxWidth >= 700 ? 3 : 2;
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
                    Icon(Icons.auto_awesome_rounded, color: yellow, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Find your next campus essential.',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search_rounded, color: blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    final selected = c == category;
                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => setState(() => category = c),
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 2 ? .72 : .82,
                ),
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.pushNamed(context, '/product'),
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
                              child: Icon(p.$3, color: p.$4, size: 66),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(p.$1, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 15),
                              const SizedBox(width: 3),
                              Text(p.$6, style: const TextStyle(color: muted, fontSize: 11)),
                              const Spacer(),
                              Text(p.$2, style: const TextStyle(color: blue, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/product'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('View product'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
