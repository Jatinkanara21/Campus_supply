import 'package:flutter/material.dart';

import '../widgets/customer_bottom_nav.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4ED8);
  static const yellow = Color(0xFFFFC66D);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const paleBlue = Color(0xFFEAF2FF);
  static const paleGreen = Color(0xFFE6F8EE);
  static const paleCoral = Color(0xFFFFE9E6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text(
          'About Campus Supply',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 1000
              ? 30.0
              : constraints.maxWidth >= 600
                  ? 24.0
                  : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(constraints.maxWidth >= 680),
                      const SizedBox(height: 26),
                      _sectionTitle(
                        'What matters to us',
                        'A simpler way to find the things you need for campus life.',
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final wide = cardConstraints.maxWidth >= 720;
                          final cards = [
                            _valueCard(
                              icon: Icons.school_outlined,
                              title: 'Built for campus life',
                              body:
                                  'From everyday stationery to creative and drafting supplies, the experience is designed around student routines.',
                              tint: paleBlue,
                              iconColor: blue,
                            ),
                            _valueCard(
                              icon: Icons.widgets_outlined,
                              title: 'Curated, not complicated',
                              body:
                                  'Clear categories and ready-to-go bundles help you browse essentials without making shopping feel complicated.',
                              tint: paleYellow,
                              iconColor: const Color(0xFF946200),
                            ),
                            _valueCard(
                              icon: Icons.favorite_border_rounded,
                              title: 'Save what you like',
                              body:
                                  'Keep favourite products together in your wishlist and come back to them when you are ready.',
                              tint: paleCoral,
                              iconColor: const Color(0xFFF06464),
                            ),
                          ];

                          if (!wide) {
                            return Column(
                              children: cards
                                  .map((card) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: card,
                                      ))
                                  .toList(),
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(width: 14),
                                Expanded(child: cards[i]),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(
                        'Make it your way',
                        'A few useful tools to make your shopping experience easier.',
                      ),
                      const SizedBox(height: 14),
                      _featureRow(
                        icon: Icons.search_rounded,
                        title: 'Explore products',
                        body:
                            'Browse the store and discover products for classes, projects and everyday use.',
                        tint: paleBlue,
                        iconColor: blue,
                      ),
                      const SizedBox(height: 10),
                      _featureRow(
                        icon: Icons.inventory_2_outlined,
                        title: 'Find a bundle',
                        body:
                            'Explore student bundles that group useful essentials together.',
                        tint: paleGreen,
                        iconColor: const Color(0xFF17824C),
                      ),
                      const SizedBox(height: 10),
                      _featureRow(
                        icon: Icons.favorite_border_rounded,
                        title: 'Keep favourites close',
                        body:
                            'Save products to your wishlist so they are easy to find again.',
                        tint: paleCoral,
                        iconColor: const Color(0xFFF06464),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ready to look around?',
                              style: TextStyle(
                                color: ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Explore the store or take a look at the student bundles.',
                              style: TextStyle(
                                color: muted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/shop'),
                                  icon: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Explore store'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/bundles'),
                                  icon: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('View bundles'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: blue,
                                    side: const BorderSide(color: border),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _hero(bool showArtwork) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [blue, blueDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x25FFFFFF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: const Text(
                    'BUILT FOR STUDENT LIFE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Create more.\\nSpend less.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.1,
                    letterSpacing: -.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 11),
                const Text(
                  'Campus Supply helps students spend less time searching for essentials and more time creating.',
                  style: TextStyle(
                    color: Color(0xFFEAF2FF),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          if (showArtwork) ...[
            const SizedBox(width: 16),
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0x44FFFFFF)),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: yellow,
                size: 62,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 38,
          decoration: BoxDecoration(
            color: blue,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _valueCard({
    required IconData icon,
    required String title,
    required String body,
    required Color tint,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(
              color: muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String body,
    required Color tint,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const paleYellow = Color(0xFFFFF5D7);
}
