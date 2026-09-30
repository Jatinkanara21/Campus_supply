import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const coral = Color(0xFFF97368);
  static const muted = Color(0xFF707681);
  static const border = Color(0xFFE7E2D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Student Bundles', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchBundles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Unable to load bundles.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final bundles = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Built for busy students.',
                style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8),
              ),
              const SizedBox(height: 6),
              Text(
                bundles.isEmpty
                    ? 'No bundles have been added yet. Admins can create them from the catalog manager.'
                    : 'Curated kits that save time, money, and a last-minute campus run.',
                style: const TextStyle(color: muted, height: 1.4),
              ),
              if (bundles.isNotEmpty) const SizedBox(height: 20),
              ...bundles.map((bundle) {
                final badge = (bundle['badge'] ?? 'Student bundle').toString();
                final name = (bundle['name'] ?? bundle['title'] ?? 'Bundle').toString();
                final description = (bundle['description'] ?? 'Curated campus essentials.').toString();
                final price = bundle['price'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 90,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: blue, size: 48),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: coral, borderRadius: BorderRadius.circular(9)),
                              child: Text(
                                badge,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(name, style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: muted, fontSize: 11.5, height: 1.3),
                            ),
                            if (price != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '₹$price',
                                style: const TextStyle(color: blue, fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                            ],
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
}