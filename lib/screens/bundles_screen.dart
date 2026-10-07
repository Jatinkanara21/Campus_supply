import 'package:flutter/material.dart';
import '../database/firestore_database.dart';

class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const yellow = Color(0xFFFACC15);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE7E2D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text(
          'Student bundles',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [blue, Color(0xFF1747B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Built for busy students.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Curated kits that save time before your next class, project or exam.',
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
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 82,
                          height: 92,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7CC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: _bundleImage(bundle['imageUrl']),

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
                                  fontSize: 17,
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
                                  fontSize: 11.5,
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

  Widget _bundleImage(dynamic value) {
    final path = (value ?? '').toString().trim();

    if (path.isEmpty) {
      return const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF9A7600),
        size: 40,
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF9A7600),
          size: 40,
        ),
      );
    }

    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.broken_image_outlined,
        color: Color(0xFF9A7600),
        size: 40,
      ),
    );
  }
}
