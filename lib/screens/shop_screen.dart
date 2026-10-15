import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/app_image.dart';
import '../database/firestore_database.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _routeArgsRead = false;

  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  String category = 'All';
  String query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsRead) return;
    _routeArgsRead = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      query = (args['query'] ?? '').toString();
      category = (args['category'] ?? 'All').toString();
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        toolbarHeight: 82,
        backgroundColor: const Color(0xFFF5F7FB),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Shop essentials',
              style: TextStyle(
                color: ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Find the right gear for campus life',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            child: _ShopActionButton(
              icon: Icons.favorite_border_rounded,
              tooltip: 'Wishlist',
              onTap: () => Navigator.pushNamed(context, '/wishlist'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 14, top: 16, bottom: 16),
            child: _ShopActionButton(
              icon: Icons.shopping_bag_outlined,
              tooltip: 'Cart',
              onTap: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreDatabase.instance.watchCategories(),
        builder: (context, categorySnapshot) {
          if (categorySnapshot.hasError) {
            return _message(
              'Could not load categories.\n\n' +
                  categorySnapshot.error.toString(),
            );
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
                  'Could not load products.\n\n' +
                      productSnapshot.error.toString() +
                      '\n\nCheck Firestore and deployed security rules.',
                );
              }
              if (!productSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = productSnapshot.data!;
              final normalizedQuery = query.trim().toLowerCase();
              final filtered = products.where((p) {
                final productCategory =
                    (p['category'] ?? '').toString().trim();
                final matchesCategory = category == 'All' ||
                    productCategory.toLowerCase() == category.toLowerCase();
                final text = (p['name'] ?? '').toString() +
                    ' ' +
                    (p['description'] ?? '').toString();
                return matchesCategory &&
                    text.toLowerCase().contains(normalizedQuery);
              }).toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 4
                      : constraints.maxWidth >= 700
                          ? 3
                          : 2;
                  final pageWidth = constraints.maxWidth > 1240 ? 1240.0 : constraints.maxWidth;
                  final horizontal = constraints.maxWidth >= 760 ? 28.0 : 16.0;

                  return Center(
                    child: SizedBox(
                      width: pageWidth,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 36),
                        children: [
                          LayoutBuilder(
                            builder: (context, heroConstraints) {
                              final wide = heroConstraints.maxWidth >= 620;
                              final copy = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0x2BFFFFFF),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: const Color(0x3DFFFFFF)),
                                    ),
                                    child: const Text(
                                      'CAMPUS SUPPLY COLLECTION',
                                      style: TextStyle(
                                        color: Color(0xFFFFD77D),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.05,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Find your next\ncampus essential.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: wide ? 30 : 27,
                                      fontWeight: FontWeight.w900,
                                      height: 1.08,
                                      letterSpacing: -.7,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Study, create and get ready for every class — all in one place.',
                                    style: TextStyle(color: Color(0xFFDCE6FF), fontSize: 12, height: 1.55),
                                  ),
                                ],
                              );

                              final visual = Container(
                                height: wide ? 190 : 150,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0x1FFFFFFF),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0x36FFFFFF)),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      top: 1,
                                      right: 1,
                                      child: Container(
                                        width: 65,
                                        height: 65,
                                        decoration: const BoxDecoration(color: Color(0x1EFFFFFF), shape: BoxShape.circle),
                                      ),
                                    ),
                                    Container(
                                      width: 142,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FBFF),
                                        borderRadius: BorderRadius.circular(21),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x22101A40), blurRadius: 20, offset: Offset(0, 8)),
                                        ],
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _ShopMiniIcon(icon: Icons.menu_book_rounded, background: Color(0xFFEAF2FF), foreground: blue),
                                              SizedBox(width: 9),
                                              _ShopMiniIcon(icon: Icons.edit_rounded, background: Color(0xFFFFF1C8), foreground: Color(0xFF9B7200)),
                                              SizedBox(width: 9),
                                              _ShopMiniIcon(icon: Icons.palette_rounded, background: Color(0xFFFFE9E6), foreground: Color(0xFFFF8066)),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'READY FOR CLASS',
                                            style: TextStyle(color: ink, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .6),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                        decoration: BoxDecoration(color: const Color(0xFFFFC66D), borderRadius: BorderRadius.circular(11)),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome_rounded, color: ink, size: 13),
                                            SizedBox(width: 5),
                                            Text(
                                              'MADE FOR STUDENTS',
                                              style: TextStyle(color: ink, fontSize: 7.5, fontWeight: FontWeight.w900),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              return Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF101A3B), Color(0xFF1D3271), Color(0xFF2456B8)],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x1E172554), blurRadius: 25, offset: Offset(0, 10)),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: -68,
                                      right: wide ? 160 : -55,
                                      child: Container(
                                        width: 205,
                                        height: 205,
                                        decoration: const BoxDecoration(color: Color(0x12FFFFFF), shape: BoxShape.circle),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(wide ? 26 : 20),
                                      child: wide
                                          ? Row(
                                              children: [
                                                Expanded(flex: 6, child: copy),
                                                const SizedBox(width: 22),
                                                Expanded(flex: 4, child: visual),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                copy,
                                                const SizedBox(height: 20),
                                                visual,
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => query = value),
                            decoration: InputDecoration(
                              hintText: 'Search stationery, tech, art supplies...',
                              hintStyle: const TextStyle(color: Color(0xFF8792A5), fontSize: 12),
                              prefixIcon: const Icon(Icons.search_rounded, color: blue, size: 22),
                              suffixIcon: query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => query = '');
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: blue, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 23),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Shop by category',
                                  style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.35),
                                ),
                              ),
                              Text(
                                '${categoryNames.length - 1} categories',
                                style: const TextStyle(color: muted, fontSize: 10.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                                  showCheckmark: false,
                                  label: Text(name),
                                  selected: selected,
                                  onSelected: (_) => setState(() => category = name),
                                  selectedColor: blue,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: selected ? blue : border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Explore supplies',
                                      style: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.5),
                                    ),
                                    SizedBox(height: 3),
                                    Text('Selected for your campus routine', style: TextStyle(color: muted, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(11)),
                                child: Text(
                                  '${filtered.length} items',
                                  style: const TextStyle(color: blue, fontSize: 10.5, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
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
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: columns == 2 ? .60 : columns == 3 ? .73 : .78,
                              ),
                              itemBuilder: (_, i) => _card(context, filtered[i]),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: blue, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w700, height: 1.5),
          ),
        ],
      ),
    );
  }
  Widget _card(BuildContext context, Map<String, dynamic> p) {
    final price = p['price'];
    final realPhotoUrl = _realPhotoUrl(p);

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x11172554),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: const BorderSide(color: border),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/product', arguments: p),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEDF3FF), Color(0xFFF8FAFD)],
                    ),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AppImage(
                          source: realPhotoUrl,
                          fit: BoxFit.contain,
                          fallback: const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: blue, size: 54),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (p['category'] ?? 'Campus essential').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: ink, fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (p['name'] ?? 'Product').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                (p['description'] ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 10.5, height: 1.35),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFE0A000), size: 15),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      (p['rating'] ?? 'New').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        price == null ? '₹0' : '₹$price',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: blue, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/product', arguments: p),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                  label: const Text('View product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ShopActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ShopActionButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: const Color(0xFF172554), size: 20),
          ),
        ),
      ),
    );
  }
}

class _ShopMiniIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _ShopMiniIcon({required this.icon, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 37,
      height: 39,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, color: foreground, size: 20),
    );
  }
}

String _realPhotoUrl(Map<String, dynamic> product) {
  // Prefer the image path selected in the Admin panel.
  final storedPath = (product['imageUrl'] ?? '').toString().trim();
  if (storedPath.isNotEmpty) {
    // Supports both bundled assets and Firebase Storage download URLs.
    return storedPath;
  }

  // Backward-compatible fallback for existing products.
  final value = '${product['name'] ?? ''} ${product['category'] ?? ''}'.toLowerCase();

  if (value.contains('backpack') || value.contains('bag')) return 'assets/image/products/backpack.svg';
  if (value.contains('headphone')) return 'assets/image/products/headphones.svg';
  if (value.contains('bottle') || value.contains('tumbler')) return 'assets/image/products/bottle.svg';
  if (value.contains('calculator')) return 'assets/image/products/calculator.svg';
  if (value.contains('lamp')) return 'assets/image/products/lamp.svg';
  if (value.contains('sleeve')) return 'assets/image/products/sleeve.svg';
  if (value.contains('pen')) return 'assets/image/products/pen.svg';
  return 'assets/image/products/notebook.svg';
}

String _productSvg({
  required String bg,
  required String body,
  required String accent,
  required String shape,
}) {
  String art;

  switch (shape) {
    case 'bag':
      art =
          '<path d="M210 175c0-68 40-105 90-105s90 37 90 105v45h-48v-43c0-34-14-55-42-55s-42 21-42 55v43h-48z" fill="$body"/>'
          '<rect x="155" y="150" width="290" height="265" rx="48" fill="$body"/>'
          '<rect x="205" y="225" width="190" height="125" rx="24" fill="#1D4ED8"/>'
          '<rect x="250" y="245" width="100" height="18" rx="9" fill="$accent"/>';
      break;
    case 'headphones':
      art =
          '<path d="M170 275v-45c0-78 58-140 130-140s130 62 130 140v45" fill="none" stroke="#172033" stroke-width="42" stroke-linecap="round"/>'
          '<rect x="135" y="250" width="95" height="150" rx="38" fill="$body"/>'
          '<rect x="370" y="250" width="95" height="150" rx="38" fill="$body"/>'
          '<rect x="160" y="278" width="45" height="80" rx="18" fill="$accent"/>'
          '<rect x="395" y="278" width="45" height="80" rx="18" fill="$accent"/>';
      break;
    case 'bottle':
      art =
          '<rect x="245" y="70" width="110" height="55" rx="16" fill="#172033"/>'
          '<path d="M225 115h150l38 60v205c0 36-29 65-65 65H252c-36 0-65-29-65-65V175z" fill="$body"/>'
          '<rect x="225" y="205" width="150" height="70" rx="18" fill="$accent"/>';
      break;
    case 'pen':
      art =
          '<g transform="rotate(-25 300 250)"><rect x="150" y="220" width="300" height="58" rx="20" fill="$body"/><rect x="210" y="220" width="145" height="58" fill="$accent"/><path d="M450 220l70 29-70 29z" fill="#172033"/></g>';
      break;
    case 'calculator':
      art =
          '<rect x="170" y="55" width="260" height="390" rx="34" fill="$body"/>'
          '<rect x="205" y="90" width="190" height="95" rx="16" fill="#EAF2FF"/>'
          '<rect x="205" y="215" width="45" height="45" rx="10" fill="$accent"/>'
          '<rect x="275" y="215" width="45" height="45" rx="10" fill="$accent"/>'
          '<rect x="345" y="215" width="45" height="45" rx="10" fill="$accent"/>';
      break;
    case 'lamp':
      art =
          '<path d="M200 120h190l65 120H135z" fill="$body"/>'
          '<path d="M300 240v155" stroke="#172033" stroke-width="20" stroke-linecap="round"/>'
          '<path d="M220 410h160" stroke="#172033" stroke-width="25" stroke-linecap="round"/>'
          '<circle cx="300" cy="225" r="28" fill="$accent"/>';
      break;
    case 'sleeve':
      art =
          '<rect x="105" y="100" width="390" height="300" rx="30" fill="$body"/>'
          '<rect x="135" y="130" width="330" height="235" rx="18" fill="$accent"/>'
          '<rect x="205" y="165" width="190" height="135" rx="12" fill="#EAF2FF"/>';
      break;
    default:
      art =
          '<rect x="150" y="75" width="300" height="350" rx="24" fill="#172033"/>'
          '<rect x="175" y="55" width="300" height="350" rx="24" fill="#fff"/>'
          '<rect x="215" y="120" width="190" height="18" rx="9" fill="$accent"/>'
          '<rect x="215" y="170" width="150" height="12" rx="6" fill="#CBD5E1"/>'
          '<rect x="215" y="205" width="175" height="12" rx="6" fill="#CBD5E1"/>';
  }

  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 500"><rect width="600" height="500" rx="48" fill="$bg"/>$art</svg>';
}
