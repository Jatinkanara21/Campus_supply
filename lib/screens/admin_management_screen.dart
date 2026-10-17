import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/image_storage_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_image.dart';

enum AdminSection { products, categories, bundles, orders, users, reviews }

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key, required this.section});
  final AdminSection section;

  String get title {
    switch (section) {
      case AdminSection.products: return 'Products';
      case AdminSection.categories: return 'Categories';
      case AdminSection.bundles: return 'Bundles';
      case AdminSection.orders: return 'Orders';
      case AdminSection.users: return 'Users';
      case AdminSection.reviews: return 'Reviews';
    }
  }

  String get collection {
    switch (section) {
      case AdminSection.products: return 'products';
      case AdminSection.categories: return 'categories';
      case AdminSection.bundles: return 'bundles';
      case AdminSection.orders: return 'orders';
      case AdminSection.users: return 'users';
      case AdminSection.reviews: return 'reviews';
    }
  }

  IconData get icon {
    switch (section) {
      case AdminSection.products: return Icons.inventory_2_outlined;
      case AdminSection.categories: return Icons.category_outlined;
      case AdminSection.bundles: return Icons.auto_awesome_outlined;
      case AdminSection.orders: return Icons.receipt_long_outlined;
      case AdminSection.users: return Icons.people_outline_rounded;
      case AdminSection.reviews: return Icons.rate_review_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (section == AdminSection.products) {
      return const _ProductsWorkspace();
    }
    if (section == AdminSection.categories) {
      return const _CategoriesWorkspace();
    }
    if (section == AdminSection.bundles) {
      return const _BundlesWorkspace();
    }
    if (section == AdminSection.orders) {
      return _OrdersWorkspace(onStatusChanged: _setOrderStatus);
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final showSidebar = screenWidth >= 1100;
    final page = Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: _buildSimplePageSidebar(context, compact: true),
                ),
              ),
            ),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _state('Unable to load ' + title + '.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return _state('No ' + title.toLowerCase() + ' yet.', empty: true);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            itemCount: docs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    section == AdminSection.users
                        ? 'Manage campus store accounts and roles'
                        : 'View and manage customer feedback',
                    style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                );
              }
              return _tile(context, docs[index - 1]);
            },
          );
        },
      ),
    );

    if (!showSidebar) return page;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 238, child: _buildSimplePageSidebar(context, compact: false)),
        Expanded(child: page),
      ],
    );
  }

  Widget _buildSimplePageSidebar(BuildContext context, {required bool compact}) {
    return AdminNavigationSidebar(
      selectedSection: section,
      adminName: _currentAdminName,
      compact: compact,
      onNavigate: (destination) {
        void navigate() {
          if (!context.mounted) return;
          if (destination == null) {
            Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
          } else if (destination != section) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => AdminManagementScreen(section: destination)),
            );
          }
        }

        if (compact) {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
        } else {
          navigate();
        }
      },
      onSignOut: () async {
        await AuthService.logout();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }

  String get _currentAdminName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final emailName = user?.email?.split('@').first.trim() ?? '';
    return emailName.isNotEmpty ? emailName : 'Administrator';
  }

  Future<bool?> _showProductItemDialog(
    BuildContext context, {
    required String title,
    required TextEditingController name,
    required TextEditingController description,
    required TextEditingController price,
    required TextEditingController imageUrl,
  }) {
    Uint8List? selectedImageBytes;
    String? selectedFileName;
    bool isSaving = false;

    bool isValidImageUrl(String value) {
      final uri = Uri.tryParse(value.trim());
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    }

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> enterImageUrl() async {
            if (isSaving) return;
            final urlController = TextEditingController(text: imageUrl.text.trim());
            final url = await showDialog<String>(
              context: dialogContext,
              builder: (urlContext) => AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: const Text('Use image URL', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF172554))),
                content: TextField(
                  controller: urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(urlContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final value = urlController.text.trim();
                      if (!isValidImageUrl(value)) {
                        ScaffoldMessenger.of(urlContext).showSnackBar(
                          const SnackBar(content: Text('Enter a valid http:// or https:// image URL')),
                        );
                        return;
                      }
                      Navigator.pop(urlContext, value);
                    },
                    child: const Text('Use URL'),
                  ),
                ],
              ),
            );
            urlController.dispose();
            if (url == null || url.isEmpty) return;
            setDialogState(() {
              imageUrl.text = url;
              selectedImageBytes = null;
              selectedFileName = 'Image URL';
            });
          }

          Future<void> pickImage() async {
            if (isSaving) return;

            try {
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 90,
                maxWidth: 1600,
                maxHeight: 1600,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              final filename = file.name.trim();
              final lowerName = filename.toLowerCase();
              final supported = lowerName.endsWith('.jpg') ||
                  lowerName.endsWith('.jpeg') ||
                  lowerName.endsWith('.png') ||
                  lowerName.endsWith('.webp') ||
                  lowerName.endsWith('.gif');
              if (!supported) {
                throw Exception('Please choose JPG, JPEG, PNG, WEBP or GIF.');
              }

              setDialogState(() {
                selectedImageBytes = bytes;
                selectedFileName = filename;
              });

              final downloadUrl = await ImageStorageService.upload(
                bytes: bytes,
                folder: 'products',
                fileName: filename,
              );

              setDialogState(() {
                imageUrl.text = downloadUrl;
                selectedFileName = '$filename • uploaded';
              });

              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Image uploaded to GitHub Storage successfully')),
                );
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Image upload failed: $e')),
                );
              }
            }
          }

          final screenSize = MediaQuery.sizeOf(dialogContext);
          final narrowDialog = screenSize.width < 560;

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: narrowDialog ? 14 : 32,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF172554), fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text(
                  'Add clear details so students can find the right item.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            content: SizedBox(
              width: narrowDialog ? screenSize.width - 60 : 540,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenSize.height * 0.66),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('PRODUCT DETAILS', style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Product name',
                          hintText: 'e.g. Campus backpack',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: description,
                        maxLines: 3,
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe the product for students',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('PRODUCT IMAGE', style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCE6F8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 150,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: selectedImageBytes != null
                                  ? Image.memory(selectedImageBytes!, fit: BoxFit.contain)
                                  : isValidImageUrl(imageUrl.text)
                                      ? AppImage(
                                          source: imageUrl.text.trim(),
                                          fit: BoxFit.contain,
                                          placeholder: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB))),
                                          fallback: const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFF64748B), size: 34)),
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF2563EB), size: 38),
                                            SizedBox(height: 8),
                                            Text('Product image preview', style: TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w800, fontSize: 12)),
                                            SizedBox(height: 3),
                                            Text('Upload a file or use a public image URL', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                          ],
                                        ),
                            ),
                            if (selectedFileName != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                selectedFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (narrowDialog)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: isSaving ? null : pickImage,
                                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                                    label: const Text('Upload from device'),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: isSaving ? null : enterImageUrl,
                                    icon: const Icon(Icons.link_rounded, size: 18),
                                    label: const Text('Use image URL'),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isSaving ? null : pickImage,
                                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                                      label: const Text('Upload from device'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isSaving ? null : enterImageUrl,
                                      icon: const Icon(Icons.link_rounded, size: 18),
                                      label: const Text('Use image URL'),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: imageUrl,
                              keyboardType: TextInputType.url,
                              decoration: InputDecoration(
                                labelText: 'Image URL',
                                hintText: 'https://example.com/image.jpg',
                                prefixIcon: const Icon(Icons.link_rounded),
                                suffixIcon: imageUrl.text.trim().isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear image URL',
                                        onPressed: isSaving ? null : () {
                                          setDialogState(() {
                                            imageUrl.clear();
                                            selectedImageBytes = null;
                                            selectedFileName = null;
                                          });
                                        },
                                        icon: const Icon(Icons.clear_rounded),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Accepted formats: JPG, JPEG, PNG, WEBP or GIF. You can also paste a direct public image URL.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        final value = imageUrl.text.trim();
                        if (value.isNotEmpty && !isValidImageUrl(value)) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid public http:// or https:// image URL.'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        try {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Save failed: ${e.toString().replaceFirst('Exception: ', '')}')),
                            );
                          }
                        }
                      },
                icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save product'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final displayName = section == AdminSection.orders
        ? '#${doc.id}'
        : section == AdminSection.users
            ? (data['email'] ?? doc.id).toString()
            : section == AdminSection.reviews
                ? 'Customer review'
                : (data['name'] ?? data['title'] ?? doc.id).toString();
    String subtitle;
    switch (section) {
      case AdminSection.products:
        subtitle = '₹${(data['price'] ?? '-').toString()} • ${(data['category'] ?? 'General').toString()}';
        break;
      case AdminSection.categories:
      case AdminSection.bundles:
        subtitle = (data['description'] ?? 'Catalog item').toString();
        break;
      case AdminSection.orders:
        final count = (data['items'] is List) ? (data['items'] as List).length : 0;
        subtitle = 'Total: ₹${(data['total'] ?? '-').toString()} • $count item(s)';
        break;
      case AdminSection.users:
        subtitle = 'Account role';
        break;
      case AdminSection.reviews:
        subtitle = (data['comment'] ?? '').toString().trim().isEmpty
            ? 'No written comment'
            : (data['comment'] ?? '').toString();
        break;
    }

    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final role = (data['role'] ?? 'user').toString().toLowerCase();
    final status = (data['status'] ?? 'pending').toString();
    final rating = (data['rating'] ?? '').toString();
    final hasImage = (section == AdminSection.products || section == AdminSection.categories || section == AdminSection.bundles) && imageUrl.isNotEmpty;
    final badgeText = section == AdminSection.orders
        ? status.toUpperCase()
        : section == AdminSection.users
            ? (role == 'admin' ? 'ADMIN' : 'USER')
            : section == AdminSection.reviews && rating.isNotEmpty
                ? '★ $rating'
                : null;
    final badgeColor = section == AdminSection.orders && status.toLowerCase() == 'delivered'
        ? const Color(0xFF15803D)
        : section == AdminSection.users && role == 'admin'
            ? const Color(0xFF7C3AED)
            : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: hasImage
                ? AppImage(source: imageUrl, fit: BoxFit.contain, fallback: Center(child: Icon(icon, color: const Color(0xFF2563EB))))
                : Center(
                    child: Icon(
                      section == AdminSection.orders ? Icons.receipt_long_outlined :
                      section == AdminSection.users ? Icons.person_outline_rounded :
                      section == AdminSection.reviews ? Icons.rate_review_outlined : icon,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(subtitle, maxLines: section == AdminSection.reviews ? 3 : 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), height: 1.35, fontSize: 12)),
                if (badgeText != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: badgeColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(9)),
                      child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .3)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Actions',
            onSelected: (value) {
              if (value == 'edit') _edit(context, doc);
              if (value == 'delete') _delete(context, doc);
              if (value.startsWith('status:')) _setOrderStatus(doc.id, value.substring(7));
              if (value.startsWith('role:')) _setRole(doc.id, value.substring(5));
            },
            itemBuilder: (_) {
              if (section == AdminSection.products || section == AdminSection.categories || section == AdminSection.bundles) {
                return const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ];
              }
              if (section == AdminSection.orders) {
                return const [
                  PopupMenuItem(value: 'status:pending', child: Text('Pending')),
                  PopupMenuItem(value: 'status:confirmed', child: Text('Confirmed')),
                  PopupMenuItem(value: 'status:shipped', child: Text('Shipped')),
                  PopupMenuItem(value: 'status:delivered', child: Text('Delivered')),
                  PopupMenuItem(value: 'status:cancelled', child: Text('Cancelled')),
                ];
              }
              if (section == AdminSection.users) {
                return const [
                  PopupMenuItem(value: 'role:user', child: Text('Make user')),
                  PopupMenuItem(value: 'role:admin', child: Text('Make admin')),
                ];
              }
              return const [PopupMenuItem(value: 'delete', child: Text('Delete review'))];
            },
          ),
        ],
      ),
    );
  }

  Widget _state(String message, {bool empty = false}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(empty ? icon : Icons.cloud_off_outlined, color: const Color(0xFF2563EB), size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w800)),
      ]),
    ),
  );

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final price = TextEditingController();
    final imageUrl = TextEditingController();
    final saved = section == AdminSection.categories
        ? await _showCategoryItemDialog(
            context,
            title: 'Add category',
            name: name,
            description: description,
            imageUrl: imageUrl,
          )
        : section == AdminSection.products
            ? await _showProductItemDialog(
                context,
                title: 'Add product',
                name: name,
                description: description,
                price: price,
                imageUrl: imageUrl,
              )
            : await _showItemDialog(
                context,
                title: 'Add bundle',
                name: name,
                description: description,
                price: price,
                imageUrl: imageUrl,
              );
    if (saved != true || name.text.trim().isEmpty) return;
    final data = <String, dynamic>{
      'name': name.text.trim(),
      'description': description.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (section == AdminSection.products || section == AdminSection.bundles) {
      data['price'] = double.tryParse(price.text.trim()) ?? 0;
      data['category'] = 'General';
      data['stock'] = 0;
    }
    if (section == AdminSection.products || section == AdminSection.categories || section == AdminSection.bundles) {
      data['imageUrl'] = imageUrl.text.trim();
    }
    try {
      await FirebaseFirestore.instance.collection(collection).add(data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database save failed: $e')),
        );
      }
    } finally {
      name.dispose();
      description.dispose();
      price.dispose();
      imageUrl.dispose();
    }
  }

  Future<void> _edit(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final name = TextEditingController(text: (data['name'] ?? data['title'] ?? '').toString());
    final description = TextEditingController(text: (data['description'] ?? '').toString());
    final price = TextEditingController(text: (data['price'] ?? '').toString());
    final imageUrl = TextEditingController(text: (data['imageUrl'] ?? '').toString());
    final saved = section == AdminSection.categories
        ? await _showCategoryItemDialog(
            context,
            title: 'Edit category',
            name: name,
            description: description,
            imageUrl: imageUrl,
          )
        : section == AdminSection.products
            ? await _showProductItemDialog(
                context,
                title: 'Edit product',
                name: name,
                description: description,
                price: price,
                imageUrl: imageUrl,
              )
            : await _showItemDialog(
                context,
                title: 'Edit item',
                name: name,
                description: description,
                price: price,
                imageUrl: imageUrl,
              );
    if (saved != true) return;
    final update = <String, dynamic>{
      'name': name.text.trim(),
      'description': description.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (section == AdminSection.products || section == AdminSection.bundles) {
      update['price'] = double.tryParse(price.text.trim()) ?? 0;
    }
    if (section == AdminSection.products || section == AdminSection.categories || section == AdminSection.bundles) {
      update['imageUrl'] = imageUrl.text.trim();
    }
    try {
      await doc.reference.update(update);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database update failed: $e')),
        );
      }
    } finally {
      name.dispose();
      description.dispose();
      price.dispose();
      imageUrl.dispose();
    }
  }


  Future<bool?> _showCategoryItemDialog(
    BuildContext context, {
    required String title,
    required TextEditingController name,
    required TextEditingController description,
    required TextEditingController imageUrl,
  }) {
    Uint8List? selectedImageBytes;
    String? selectedFileName;
    bool isSaving = false;
    bool isUploading = false;

    bool isValidImageUrl(String value) {
      final uri = Uri.tryParse(value.trim());
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    }

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> enterImageUrl() async {
            if (isSaving || isUploading) return;
            final urlController = TextEditingController(text: imageUrl.text.trim());
            final url = await showDialog<String>(
              context: dialogContext,
              builder: (urlContext) => AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: const Text(
                  'Use image URL',
                  style: TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w900),
                ),
                content: TextField(
                  controller: urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/category.jpg',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(urlContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final value = urlController.text.trim();
                      if (!isValidImageUrl(value)) {
                        ScaffoldMessenger.of(urlContext).showSnackBar(
                          const SnackBar(content: Text('Enter a valid http:// or https:// image URL')),
                        );
                        return;
                      }
                      Navigator.pop(urlContext, value);
                    },
                    child: const Text('Use URL'),
                  ),
                ],
              ),
            );
            urlController.dispose();
            if (url == null || url.isEmpty) return;
            setDialogState(() {
              imageUrl.text = url;
              selectedImageBytes = null;
              selectedFileName = 'Image URL';
            });
          }

          Future<void> pickImage() async {
            if (isSaving || isUploading) return;
            try {
              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 90,
                maxWidth: 1600,
                maxHeight: 1600,
              );
              if (file == null) return;
              final bytes = await file.readAsBytes();
              final filename = file.name.trim();
              final lowerName = filename.toLowerCase();
              final supported = lowerName.endsWith('.jpg') ||
                  lowerName.endsWith('.jpeg') ||
                  lowerName.endsWith('.png') ||
                  lowerName.endsWith('.webp') ||
                  lowerName.endsWith('.gif');
              if (!supported) {
                throw Exception('Please choose JPG, JPEG, PNG, WEBP or GIF.');
              }
              setDialogState(() {
                isUploading = true;
                selectedImageBytes = bytes;
                selectedFileName = filename;
              });

              final downloadUrl = await ImageStorageService.upload(
                bytes: bytes,
                folder: 'categories',
                fileName: filename,
              );
              setDialogState(() {
                imageUrl.text = downloadUrl;
                selectedFileName = '$filename • uploaded';
                isUploading = false;
              });
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Image uploaded to GitHub Storage successfully')),
                );
              }
            } catch (e) {
              setDialogState(() => isUploading = false);
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Image upload failed: $e')),
                );
              }
            }
          }

          final screenSize = MediaQuery.sizeOf(dialogContext);
          final narrow = screenSize.width < 560;

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: narrow ? 14 : 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            titlePadding: const EdgeInsets.fromLTRB(23, 22, 23, 7),
            contentPadding: const EdgeInsets.fromLTRB(23, 8, 23, 12),
            actionsPadding: const EdgeInsets.fromLTRB(18, 2, 18, 17),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.category_outlined, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Color(0xFF172554), fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Organize your campus store.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: narrow ? screenSize.width - 60 : 520,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenSize.height * 0.68),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CATEGORY DETAILS',
                        style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: name,
                        enabled: !isSaving && !isUploading,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Category name',
                          hintText: 'e.g. Stationery',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: description,
                        enabled: !isSaving && !isUploading,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe the items in this category',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 19),
                      const Text(
                        'CATEGORY IMAGE',
                        style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFDCE6F8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 145,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: selectedImageBytes != null
                                  ? Image.memory(selectedImageBytes!, fit: BoxFit.contain)
                                  : isValidImageUrl(imageUrl.text)
                                      ? AppImage(
                                          source: imageUrl.text.trim(),
                                          fit: BoxFit.contain,
                                          placeholder: const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                          ),
                                          fallback: const Center(
                                            child: Icon(Icons.broken_image_outlined, color: Color(0xFF64748B), size: 34),
                                          ),
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 37),
                                            SizedBox(height: 8),
                                            Text(
                                              'Category image preview',
                                              style: TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w800, fontSize: 12),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Upload an image or paste a URL',
                                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                            ),
                                          ],
                                        ),
                            ),
                            if (selectedFileName != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                selectedFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (narrow)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: isSaving || isUploading ? null : pickImage,
                                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                                    label: Text(isUploading ? 'Uploading...' : 'Upload from device'),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: isSaving || isUploading ? null : enterImageUrl,
                                    icon: const Icon(Icons.link_rounded, size: 18),
                                    label: const Text('Use image URL'),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isSaving || isUploading ? null : pickImage,
                                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                                      label: Text(isUploading ? 'Uploading...' : 'Upload from device'),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isSaving || isUploading ? null : enterImageUrl,
                                      icon: const Icon(Icons.link_rounded, size: 18),
                                      label: const Text('Use image URL'),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: imageUrl,
                              enabled: !isSaving && !isUploading,
                              keyboardType: TextInputType.url,
                              decoration: InputDecoration(
                                labelText: 'Image URL (optional)',
                                hintText: 'https://example.com/category.jpg',
                                prefixIcon: const Icon(Icons.link_rounded),
                                suffixIcon: imageUrl.text.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear image URL',
                                        onPressed: isSaving || isUploading
                                            ? null
                                            : () => setDialogState(() {
                                                  imageUrl.clear();
                                                  selectedImageBytes = null;
                                                  selectedFileName = null;
                                                }),
                                        icon: const Icon(Icons.clear_rounded),
                                      ),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Use a JPG, PNG, WEBP or GIF image, or paste a public direct image URL.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving || isUploading ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSaving || isUploading
                    ? null
                    : () {
                        final url = imageUrl.text.trim();
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Please enter a category name.')),
                          );
                          return;
                        }
                        if (url.isNotEmpty && !isValidImageUrl(url)) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid public http:// or https:// image URL.')),
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        Navigator.pop(dialogContext, true);
                      },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save category'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool?> _showItemDialog(
    BuildContext context, {
    required String title,
    required TextEditingController name,
    required TextEditingController description,
    required TextEditingController price,
    required TextEditingController imageUrl,
  }) {
    Uint8List? selectedImageBytes;
    String? selectedFileName;
    bool isSaving = false;
    bool isUploading = false;

    bool isValidImageUrl(String value) {
      final uri = Uri.tryParse(value.trim());
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    }

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> enterImageUrl() async {
            if (isSaving || isUploading) return;
            final urlController = TextEditingController(text: imageUrl.text.trim());
            final url = await showDialog<String>(
              context: dialogContext,
              builder: (urlContext) => AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: const Text(
                  'Use image URL',
                  style: TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w900),
                ),
                content: TextField(
                  controller: urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Direct image URL',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(urlContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final value = urlController.text.trim();
                      if (!isValidImageUrl(value)) {
                        ScaffoldMessenger.of(urlContext).showSnackBar(
                          const SnackBar(content: Text('Enter a valid http:// or https:// image URL')),
                        );
                        return;
                      }
                      Navigator.pop(urlContext, value);
                    },
                    child: const Text('Use URL'),
                  ),
                ],
              ),
            );
            urlController.dispose();
            if (url == null || url.isEmpty || !dialogContext.mounted) return;
            setDialogState(() {
              imageUrl.text = url;
              selectedImageBytes = null;
              selectedFileName = 'Image URL';
            });
          }

          Future<void> pickImage() async {
            if (isSaving || isUploading) return;
            try {
              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 90,
                maxWidth: 1600,
                maxHeight: 1600,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              final filename = file.name.trim();
              final lowerName = filename.toLowerCase();
              final supported = lowerName.endsWith('.jpg') ||
                  lowerName.endsWith('.jpeg') ||
                  lowerName.endsWith('.png') ||
                  lowerName.endsWith('.webp') ||
                  lowerName.endsWith('.gif');
              if (!supported) {
                throw Exception('Please choose JPG, JPEG, PNG, WEBP or GIF.');
              }

              setDialogState(() {
                isUploading = true;
                selectedImageBytes = bytes;
                selectedFileName = filename;
              });

              final downloadUrl = await ImageStorageService.upload(
                bytes: bytes,
                folder: 'bundles',
                fileName: filename,
              );

              if (!dialogContext.mounted) return;
              setDialogState(() {
                imageUrl.text = downloadUrl;
                selectedFileName = '$filename • uploaded';
                isUploading = false;
              });
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Image uploaded to GitHub Storage successfully')),
              );
            } catch (e) {
              if (dialogContext.mounted) {
                setDialogState(() => isUploading = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Image upload failed: $e')),
                );
              }
            }
          }

          final screenSize = MediaQuery.sizeOf(dialogContext);
          final narrow = screenSize.width < 560;

          Widget imagePreview() {
            if (selectedImageBytes != null) {
              return Image.memory(
                selectedImageBytes!,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
              );
            }
            if (isValidImageUrl(imageUrl.text)) {
              return AppImage(
                source: imageUrl.text.trim(),
                fit: BoxFit.cover,
                placeholder: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                ),
                fallback: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 34, color: Color(0xFF2563EB)),
                      SizedBox(height: 6),
                      Text('Image URL could not be loaded'),
                    ],
                  ),
                ),
              );
            }
            return Container(
              color: const Color(0xFFEAF2FF),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_mosaic_outlined, color: Color(0xFF2563EB), size: 38),
                  SizedBox(height: 8),
                  Text('Bundle image preview', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            );
          }

          InputDecoration fieldDecoration({
            required String label,
            required IconData icon,
            String? hint,
          }) {
            return InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFDCE6F8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFDCE6F8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFFFFFEFC),
            surfaceTintColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: narrow ? 14 : 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            titlePadding: const EdgeInsets.fromLTRB(23, 22, 23, 8),
            contentPadding: const EdgeInsets.fromLTRB(23, 8, 23, 10),
            title: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF172554),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: screenSize.height * 0.62,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bundle details',
                      style: TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      decoration: fieldDecoration(
                        label: 'Bundle name',
                        hint: 'e.g. Exam Ready Kit',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      minLines: 2,
                      maxLines: 4,
                      decoration: fieldDecoration(
                        label: 'Description',
                        hint: 'What is included in this bundle?',
                        icon: Icons.notes_rounded,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: fieldDecoration(
                        label: 'Price (₹)',
                        hint: '0.00',
                        icon: Icons.currency_rupee_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bundle image',
                      style: TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        width: double.infinity,
                        height: 170,
                        child: imagePreview(),
                      ),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        selectedFileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrl,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: fieldDecoration(
                        label: 'Image URL',
                        hint: 'https://example.com/image.jpg',
                        icon: Icons.link_rounded,
                      ).copyWith(
                        suffixIcon: imageUrl.text.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear image URL',
                                onPressed: () => setDialogState(() {
                                  imageUrl.clear();
                                  selectedImageBytes = null;
                                  selectedFileName = null;
                                }),
                                icon: const Icon(Icons.clear_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isSaving || isUploading ? null : pickImage,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: Text(isUploading ? 'Uploading...' : 'Upload from device'),
                        ),
                        OutlinedButton.icon(
                          onPressed: isSaving || isUploading ? null : enterImageUrl,
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('Use image URL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose an image file or paste a public direct image URL.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
            actions: [
              TextButton(
                onPressed: isSaving || isUploading ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSaving || isUploading
                    ? null
                    : () {
                        final value = imageUrl.text.trim();
                        if (value.isNotEmpty && !isValidImageUrl(value)) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid public http:// or https:// image URL.'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        Navigator.pop(dialogContext, true);
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Save bundle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) await doc.reference.delete();
  }

  Future<void> _setOrderStatus(String id, String status) {
    return FirebaseFirestore.instance.collection('orders').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _setRole(String uid, String role) {
    return FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}


/// Dedicated stateful workspace for Products only. Other admin sections continue
/// to use the existing AdminManagementScreen UI and handlers.
class _ProductsWorkspace extends StatefulWidget {
  const _ProductsWorkspace();

  @override
  State<_ProductsWorkspace> createState() => _ProductsWorkspaceState();
}

class _ProductsWorkspaceState extends State<_ProductsWorkspace> {
  static const _canvas = Color(0xFFFAF8F3);
  static const _ink = Color(0xFF172554);
  static const _blue = Color(0xFF2563EB);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFDCE6F8);
  static const _softBlue = Color(0xFFEAF2FF);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(text: '0');
  final TextEditingController _imageUrlController = TextEditingController();
  final FocusNode _imageUrlFocusNode = FocusNode();

  QueryDocumentSnapshot<Map<String, dynamic>>? _editingDoc;
  String _selectedProductCategory = 'General';
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  String _categoryFilter = 'All categories';
  bool _mobileEditorOpen = false;
  bool _desktopEditorOpen = true;
  bool _saving = false;
  bool _uploading = false;
  int _refreshKey = 0;

  bool get _isCompact => MediaQuery.sizeOf(context).width < 1120;

  String get _adminName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final emailName = user?.email?.split('@').first.trim() ?? '';
    return emailName.isNotEmpty ? emailName : 'Administrator';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showSidebar = screenWidth >= 1280;

    return Scaffold(
      backgroundColor: _canvas,
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: _buildSidebar(compact: true),
                ),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSidebar) SizedBox(width: 238, child: _buildSidebar()),
          Expanded(
            child: Column(
              children: [
                _buildTopbar(showSidebar: showSidebar, screenWidth: screenWidth),
                Expanded(child: _buildProductsBody(screenWidth)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar({required bool showSidebar, required double screenWidth}) {
    final compact = screenWidth < 560;
    return Container(
      height: compact ? 76 : 100,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : (showSidebar ? 30 : 24)),
      decoration: const BoxDecoration(
        color: _canvas,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!showSidebar)
            Builder(
              builder: (drawerContext) => IconButton(
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: _ink),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'Admin   /   Products',
                      style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                Text(
                  'Products',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 21 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.1,
                  ),
                ),
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Manage your campus store catalog',
                      style: TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (compact)
            IconButton(
              tooltip: 'Refresh products',
              onPressed: () => setState(() => _refreshKey++),
              icon: const Icon(Icons.refresh_rounded, color: _blue),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() => _refreshKey++),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFB9D0FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool compact = false}) {
    return AdminNavigationSidebar(
      selectedSection: AdminSection.products,
      adminName: _adminName,
      compact: compact,
      onNavigate: (section) => _navigate(section, compact: compact),
      onSignOut: () async {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }

  void _navigate(AdminSection? section, {required bool compact}) {
    if (compact) {
      Navigator.pop(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (section == null) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        } else if (section != AdminSection.products) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section)),
          );
        }
      });
      return;
    }

    if (section == null) {
      Navigator.pop(context);
    } else if (section != AdminSection.products) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section)),
      );
    }
  }

  Widget _buildProductsBody(double screenWidth) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(_refreshKey),
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _stateCard(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load products',
            message: 'Please check your connection and try again.',
            action: FilledButton.icon(
              onPressed: _startAdding,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue),
                ),
                SizedBox(height: 14),
                Text(
                  'Loading products...',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final categories = <String>{'All categories'};
        for (final doc in docs) {
          final value = (doc.data()['category'] ?? 'General').toString().trim();
          categories.add(value.isEmpty ? 'General' : value);
        }
        final categoryOptions = categories.toList()..sort();
        categoryOptions.remove('All categories');
        categoryOptions.insert(0, 'All categories');
        final editorCategoryOptions = categoryOptions
            .where((category) => category != 'All categories')
            .toSet()
            .toList()
          ..add('General');
        editorCategoryOptions.sort();
        final selectedCategory = categoryOptions.contains(_categoryFilter)
            ? _categoryFilter
            : 'All categories';

        final query = _searchController.text.trim().toLowerCase();
        final visibleDocs = docs.where((doc) {
          final data = doc.data();
          final category = (data['category'] ?? 'General').toString().toLowerCase();
          final name = (data['name'] ?? data['title'] ?? doc.id).toString().toLowerCase();
          final price = (data['price'] ?? '').toString().toLowerCase();
          final matchesQuery = query.isEmpty ||
              name.contains(query) ||
              category.contains(query) ||
              price.contains(query);
          final matchesCategory = selectedCategory == 'All categories' ||
              (data['category'] ?? 'General').toString() == selectedCategory;
          return matchesQuery && matchesCategory;
        }).toList();

        final showSplit = screenWidth >= 1120 && !_mobileEditorOpen;
        if (showSplit) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _buildProductListPane(
                  docs: visibleDocs,
                  total: docs.length,
                  categories: categoryOptions,
                  selectedCategory: selectedCategory,
                  width: screenWidth,
                ),
              ),
              if (_desktopEditorOpen)
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 22, 18),
                    child: _buildEditorPanel(categories: editorCategoryOptions),
                  ),
                ),
            ],
          );
        }

        if (_mobileEditorOpen) {
          return Padding(
            padding: EdgeInsets.fromLTRB(screenWidth < 560 ? 12 : 22, 10, screenWidth < 560 ? 12 : 22, 18),
            child: _buildEditorPanel(mobile: true, categories: editorCategoryOptions),
          );
        }

        return _buildProductListPane(
          docs: visibleDocs,
          total: docs.length,
          categories: categoryOptions,
          selectedCategory: selectedCategory,
          width: screenWidth,
          fullWidth: true,
        );
      },
    );
  }

  Widget _buildProductListPane({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required int total,
    required List<String> categories,
    required String selectedCategory,
    required double width,
    bool fullWidth = false,
  }) {
    final compact = width < 560;
    final padding = EdgeInsets.fromLTRB(
      fullWidth ? (compact ? 14 : 28) : (compact ? 12 : 22),
      18,
      fullWidth ? (compact ? 14 : 28) : (compact ? 12 : 18),
      compact ? 100 : 24,
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product catalog',
                      style: TextStyle(
                        color: _ink,
                        fontSize: compact ? 16 : 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      total == 1 ? '1 product in your catalog' : '$total products in your catalog',
                      style: const TextStyle(color: _muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (!compact)
                FilledButton.icon(
                  onPressed: _startAdding,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.3)),
            ),
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.filter_list_rounded, color: _muted),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            ),
            items: categories.map((category) => DropdownMenuItem(
              value: category,
              child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _categoryFilter = value);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: docs.isEmpty
                ? _stateCard(
                    icon: total == 0 ? Icons.inventory_2_outlined : Icons.search_off_rounded,
                    title: total == 0 ? 'Your catalog is ready to grow' : 'No matching products',
                    message: total == 0
                        ? 'Add your first product to start building your campus store catalog.'
                        : 'Try another search or category filter.',
                    action: total == 0
                        ? FilledButton.icon(
                            onPressed: _startAdding,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add your first product'),
                          )
                        : TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _categoryFilter = 'All categories');
                            },
                            icon: const Icon(Icons.filter_alt_off_rounded),
                            label: const Text('Clear filters'),
                          ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _productCard(docs[index], compact: width < 600),
                  ),
          ),
          if (compact)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startAdding,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool compact,
  }) {
    final data = doc.data();
    final name = (data['name'] ?? data['title'] ?? doc.id).toString().trim();
    final price = (data['price'] ?? '-').toString();
    final rawCategory = (data['category'] ?? 'General').toString().trim();
    final category = rawCategory.isEmpty ? 'General' : rawCategory;
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final stock = int.tryParse((data['stock'] ?? 0).toString()) ?? 0;
    final selected = _editingDoc?.id == doc.id;
    final imageSize = compact ? 66.0 : 78.0;

    return Material(
      color: selected ? const Color(0xFFF5F9FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startEditing(doc),
        child: Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? const Color(0xFF90B8FF) : _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: imageUrl.isNotEmpty
                    ? AppImage(
                        source: imageUrl,
                        fit: BoxFit.contain,
                        fallback: const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: _blue, size: 25),
                        ),
                      )
                    : Icon(Icons.inventory_2_outlined, color: _blue, size: compact ? 28 : 32),
              ),
              SizedBox(width: compact ? 10 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Untitled product' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: compact ? 13 : 14,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 130),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _softBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _blue, fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹$price',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          stock > 0 ? Icons.circle : Icons.circle,
                          size: 7,
                          color: stock > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            stock > 0 ? 'In stock ($stock)' : 'Out of stock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: stock > 0 ? _muted : const Color(0xFFB42318),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Product actions',
                icon: const Icon(Icons.more_vert_rounded, color: _muted),
                onSelected: (value) {
                  if (value == 'edit') _startEditing(doc);
                  if (value == 'delete') _deleteProduct(doc);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 19),
                      SizedBox(width: 9),
                      Text('Edit product'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 19),
                      SizedBox(width: 9),
                      Text('Delete product'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorPanel({
    bool mobile = false,
    required List<String> categories,
  }) {
    final editing = _editingDoc != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(mobile ? 15 : 18, 16, mobile ? 12 : 16, 14),
            child: Row(
              children: [
                if (mobile)
                  IconButton(
                    tooltip: 'Back to products',
                    onPressed: _closeMobileEditor,
                    icon: const Icon(Icons.arrow_back_rounded, color: _blue),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)),
                    child: Icon(editing ? Icons.edit_note_rounded : Icons.inventory_2_outlined, color: _blue, size: 25),
                  ),
                if (!mobile) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing ? 'Edit Product' : 'Add Product',
                        style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        editing ? 'Update the details for this catalog item.' : 'Fill in the details to add a new product to your store.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
                if (!mobile)
                  IconButton(
                    tooltip: 'Close editor',
                    onPressed: () {
                      if (MediaQuery.sizeOf(context).width >= 1120) {
                        setState(() {
                          _desktopEditorOpen = false;
                          _editingDoc = null;
                          _clearForm();
                        });
                      } else {
                        _closeMobileEditor();
                      }
                    },
                    icon: const Icon(Icons.close_rounded, color: _muted),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EEF6)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 680;
                final details = _buildProductFields(
                  categories: categories,
                  compact: !twoColumns,
                );
                final imageSection = _buildImageSection(compact: !twoColumns);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(mobile ? 15 : 18),
                  child: twoColumns
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: details),
                            const SizedBox(width: 18),
                            Expanded(flex: 5, child: imageSection),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            details,
                            const SizedBox(height: 20),
                            imageSection,
                          ],
                        ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EEF6)),
          Padding(
            padding: EdgeInsets.fromLTRB(15, 12, 15, mobile ? 14 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _saving || _uploading
                      ? null
                      : () {
                          if (mobile) {
                            _closeMobileEditor();
                          } else if (editing) {
                            _loadProductIntoEditor(_editingDoc!);
                          } else {
                            _clearForm();
                            setState(() => _desktopEditorOpen = false);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: Color(0xFFB9D0FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _saving || _uploading ? null : _saveProduct,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'Saving...' : editing ? 'Save changes' : 'Save product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductFields({
    required List<String> categories,
    required bool compact,
  }) {
    final options = categories.toSet().toList()..sort();
    if (options.isEmpty) options.add('General');
    final selectedCategory = options.contains(_selectedProductCategory)
        ? _selectedProductCategory
        : (options.contains('General') ? 'General' : options.first);

    final categoryField = DropdownButtonFormField<String>(
      value: selectedCategory,
      isExpanded: true,
      decoration: _inputDecoration(
        'Category',
        icon: Icons.category_outlined,
      ),
      items: options
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _saving || _uploading
          ? null
          : (value) {
              if (value != null) {
                setState(() => _selectedProductCategory = value);
              }
            },
    );

    final stockField = TextField(
      controller: _stockController,
      enabled: !_saving && !_uploading,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(
        'Stock quantity',
        icon: Icons.inventory_2_outlined,
        hint: 'e.g. 25',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'PRODUCT DETAILS',
          style: TextStyle(
            color: _blue,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 11),
        TextField(
          controller: _nameController,
          enabled: !_saving && !_uploading,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            'Product name',
            hint: 'e.g. Campus backpack',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _descriptionController,
          enabled: !_saving && !_uploading,
          minLines: 3,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            'Description',
            hint: 'Describe the product for students',
            icon: Icons.notes_rounded,
            alignLabel: true,
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _priceController,
          enabled: !_saving && !_uploading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration(
            'Price (₹)',
            hint: 'Enter price',
            icon: Icons.currency_rupee_rounded,
          ),
        ),
        const SizedBox(height: 13),
        if (compact) ...[
          categoryField,
          const SizedBox(height: 13),
          stockField,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: categoryField),
              const SizedBox(width: 12),
              Expanded(child: stockField),
            ],
          ),
        const SizedBox(height: 7),
        const Text(
          'Choose a category and enter the available stock quantity.',
          style: TextStyle(color: _muted, fontSize: 10.5, height: 1.4),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
    bool alignLabel = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFD8E4F4)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabel,
      prefixIcon: icon == null ? null : Icon(icon, size: 19, color: _muted),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFBFDFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _blue, width: 1.3),
      ),
    );
  }

  Widget _buildImageSection({required bool compact}) {
    final validUrl = _isValidImageUrl(_imageUrlController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('PRODUCT IMAGE', style: TextStyle(color: _blue, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: compact ? 145 : 122,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImageBytes != null
                    ? Image.memory(_selectedImageBytes!, fit: BoxFit.contain)
                    : validUrl
                        ? AppImage(
                            source: _imageUrlController.text.trim(),
                            fit: BoxFit.contain,
                            placeholder: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue)),
                            fallback: const Center(child: Icon(Icons.broken_image_outlined, size: 34, color: _muted)),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 37, color: _blue),
                              SizedBox(height: 8),
                              Text('Product image preview', style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text('Upload an image or paste a URL', style: TextStyle(color: _muted, fontSize: 10.5)),
                            ],
                          ),
              ),
              if (_selectedFileName != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedFileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 11),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving || _uploading ? null : _pickAndUploadImage,
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(_uploading ? 'Uploading...' : 'Upload from device'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _saving || _uploading ? null : _openImageUrlEntry,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Use image URL'),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _pickAndUploadImage,
                        icon: const Icon(Icons.upload_file_rounded, size: 17),
                        label: const Text('Upload from device'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _openImageUrlEntry,
                        icon: const Icon(Icons.link_rounded, size: 17),
                        label: const Text('Use image URL'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 13),
              TextField(
                controller: _imageUrlController,
                focusNode: _imageUrlFocusNode,
                enabled: !_saving && !_uploading,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration('Image URL (optional)', hint: 'https://example.com/image.jpg', icon: Icons.link_rounded).copyWith(
                  suffixIcon: _imageUrlController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear image URL',
                          onPressed: _saving || _uploading
                              ? null
                              : () {
                                  setState(() {
                                    _imageUrlController.clear();
                                    _selectedImageBytes = null;
                                    _selectedFileName = null;
                                  });
                                },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 7),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Use JPG, PNG, WEBP or GIF, or a public direct image URL.',
                  style: TextStyle(color: _muted, fontSize: 10.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isValidImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _openImageUrlEntry() async {
    if (_saving || _uploading) return;
    final urlController = TextEditingController(text: _imageUrlController.text.trim());
    final url = await showDialog<String>(
      context: context,
      builder: (urlContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Use image URL', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: urlController,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: _inputDecoration('Image URL', hint: 'https://example.com/image.jpg', icon: Icons.link_rounded),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(urlContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = urlController.text.trim();
              if (!_isValidImageUrl(value)) {
                ScaffoldMessenger.of(urlContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid http:// or https:// image URL')),
                );
                return;
              }
              Navigator.pop(urlContext, value);
            },
            child: const Text('Use URL'),
          ),
        ],
      ),
    );
    urlController.dispose();
    if (!mounted || url == null || url.isEmpty) return;
    setState(() {
      _imageUrlController.text = url;
      _selectedImageBytes = null;
      _selectedFileName = 'Image URL';
    });
  }

  Future<void> _pickAndUploadImage() async {
    if (_saving || _uploading) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final filename = file.name.trim();
      final lowerName = filename.toLowerCase();
      final supported = lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png') ||
          lowerName.endsWith('.webp') ||
          lowerName.endsWith('.gif');
      if (!supported) {
        throw Exception('Please choose JPG, JPEG, PNG, WEBP or GIF.');
      }

      setState(() {
        _uploading = true;
        _selectedImageBytes = bytes;
        _selectedFileName = filename;
      });

      final downloadUrl = await ImageStorageService.upload(
        bytes: bytes,
        folder: 'products',
        fileName: filename,
      );
      if (!mounted) return;
      setState(() {
        _imageUrlController.text = downloadUrl;
        _selectedFileName = '$filename • uploaded';
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded to GitHub Storage successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }
  }

  void _startAdding() {
    _clearForm();
    setState(() {
      _editingDoc = null;
      if (_isCompact) {
        _mobileEditorOpen = true;
      } else {
        _desktopEditorOpen = true;
      }
    });
  }

  void _startEditing(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    _loadProductIntoEditor(doc);
    setState(() {
      _editingDoc = doc;
      if (_isCompact) {
        _mobileEditorOpen = true;
      } else {
        _desktopEditorOpen = true;
      }
    });
  }

  void _loadProductIntoEditor(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    _nameController.text = (data['name'] ?? data['title'] ?? '').toString();
    _descriptionController.text = (data['description'] ?? '').toString();
    _priceController.text = (data['price'] ?? '').toString();
    _stockController.text = (data['stock'] ?? 0).toString();
    _selectedProductCategory = (data['category'] ?? 'General').toString().trim();
    if (_selectedProductCategory.isEmpty) _selectedProductCategory = 'General';
    _imageUrlController.text = (data['imageUrl'] ?? '').toString();
    _selectedImageBytes = null;
    _selectedFileName = null;
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.text = '0';
    _selectedProductCategory = 'General';
    _imageUrlController.clear();
    _selectedImageBytes = null;
    _selectedFileName = null;
  }

  void _closeMobileEditor() {
    setState(() {
      _mobileEditorOpen = false;
      _editingDoc = null;
      _clearForm();
    });
  }

  Future<void> _saveProduct() async {
    if (_saving || _uploading) return;
    final productName = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final priceText = _priceController.text.trim();
    final stockText = _stockController.text.trim();
    final stock = int.tryParse(stockText);
    final category = _selectedProductCategory.trim().isEmpty
        ? 'General'
        : _selectedProductCategory.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name.')),
      );
      return;
    }
    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a stock quantity of 0 or more.')),
      );
      return;
    }
    if (imageUrl.isNotEmpty && !_isValidImageUrl(imageUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid public http:// or https:// image URL.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_editingDoc == null) {
        await FirebaseFirestore.instance.collection('products').add({
          'name': productName,
          'description': description,
          'price': double.tryParse(priceText) ?? 0,
          'category': category,
          'stock': stock,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully')),
        );
        _clearForm();
        setState(() {
          _saving = false;
          if (_isCompact) _mobileEditorOpen = false;
        });
      } else {
        await _editingDoc!.reference.update({
          'name': productName,
          'description': description,
          'price': double.tryParse(priceText) ?? 0,
          'category': category,
          'stock': stock,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        setState(() {
          _saving = false;
          if (_isCompact) {
            _mobileEditorOpen = false;
            _editingDoc = null;
            _clearForm();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database save failed: $e')),
      );
    }
  }

  Future<void> _deleteProduct(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete product?', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await doc.reference.delete();
    if (!mounted) return;
    if (_editingDoc?.id == doc.id) {
      setState(() {
        _editingDoc = null;
        _clearForm();
        if (_isCompact) _mobileEditorOpen = false;
      });
    }
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 27),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(20)),
                  child: Icon(icon, size: 32, color: _blue),
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.5),
                ),
                if (action != null) ...[
                  const SizedBox(height: 18),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _CategoriesWorkspace extends StatefulWidget {
  const _CategoriesWorkspace();

  @override
  State<_CategoriesWorkspace> createState() => _CategoriesWorkspaceState();
}

class _CategoriesWorkspaceState extends State<_CategoriesWorkspace> {
  static const _canvas = Color(0xFFFAF8F3);
  static const _ink = Color(0xFF172554);
  static const _blue = Color(0xFF2563EB);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFDCE6F8);
  static const _softBlue = Color(0xFFEAF2FF);

  final _actions = const AdminManagementScreen(section: AdminSection.categories);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  QueryDocumentSnapshot<Map<String, dynamic>>? _editingDoc;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _mobileEditorOpen = false;
  bool _desktopEditorOpen = true;
  bool _saving = false;
  bool _uploading = false;
  int _refreshKey = 0;

  String get _adminName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final emailName = user?.email?.split('@').first.trim() ?? '';
    return emailName.isNotEmpty ? emailName : 'Administrator';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showSidebar = screenWidth >= 1280;

    return Scaffold(
      backgroundColor: _canvas,
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: SafeArea(
                child: SingleChildScrollView(child: _buildSidebar(compact: true)),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSidebar) SizedBox(width: 238, child: _buildSidebar()),
          Expanded(
            child: Column(
              children: [
                _buildHeader(screenWidth: screenWidth, showSidebar: showSidebar),
                Expanded(child: _buildCategoryContent(screenWidth)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required double screenWidth, required bool showSidebar}) {
    final compact = screenWidth < 560;
    return Container(
      height: compact ? 76 : 100,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : (showSidebar ? 30 : 24)),
      decoration: const BoxDecoration(
        color: _canvas,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!showSidebar)
            Builder(
              builder: (drawerContext) => IconButton(
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: _ink),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'Admin   /   Categories',
                      style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                Text(
                  'Categories',
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 21 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Organize your campus store',
                      style: TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (compact)
            IconButton(
              tooltip: 'Refresh categories',
              onPressed: () => setState(() => _refreshKey++),
              icon: const Icon(Icons.refresh_rounded, color: _blue),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: () => setState(() => _refreshKey++),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFB9D0FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _startAdding,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add category'),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar({bool compact = false}) {
    return AdminNavigationSidebar(
      selectedSection: AdminSection.categories,
      adminName: _adminName,
      compact: compact,
      onNavigate: (section) => _navigate(section, compact: compact),
      onSignOut: () async {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }

  void _navigate(AdminSection? section, {required bool compact}) {
    if (compact) Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (section == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
      } else if (section != AdminSection.categories) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section)),
        );
      }
    });
  }

  Widget _buildCategoryContent(double screenWidth) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(_refreshKey),
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _stateCard(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load categories',
            message: 'Please check your connection and try again.',
            action: FilledButton.icon(
              onPressed: _startAdding,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
              style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue)),
                SizedBox(height: 14),
                Text('Loading categories...', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final query = _searchController.text.trim().toLowerCase();
        final visibleDocs = docs.where((doc) {
          final data = doc.data();
          final name = (data['name'] ?? data['title'] ?? doc.id).toString().toLowerCase();
          final description = (data['description'] ?? '').toString().toLowerCase();
          return query.isEmpty || name.contains(query) || description.contains(query);
        }).toList();

        final showSplit = screenWidth >= 1120 && !_mobileEditorOpen;
        if (showSplit) {
          final showEditor = _desktopEditorOpen;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: showEditor ? 5 : 12,
                child: _buildCategoryListPane(
                  docs: visibleDocs,
                  total: docs.length,
                  width: screenWidth,
                  fullWidth: !showEditor,
                ),
              ),
              if (showEditor)
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 22, 18),
                    child: _buildEditorPanel(),
                  ),
                ),
            ],
          );
        }

        if (_mobileEditorOpen) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth < 560 ? 12 : 22,
              10,
              screenWidth < 560 ? 12 : 22,
              18,
            ),
            child: _buildEditorPanel(mobile: true),
          );
        }

        return _buildCategoryListPane(
          docs: visibleDocs,
          total: docs.length,
          width: screenWidth,
          fullWidth: true,
        );
      },
    );
  }

  Widget _buildCategoryListPane({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required int total,
    required double width,
    bool fullWidth = false,
  }) {
    final compact = width < 560;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : (fullWidth ? 28 : 22),
        18,
        compact ? 14 : (fullWidth ? 28 : 18),
        compact ? 20 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category catalog',
                      style: TextStyle(
                        color: _ink,
                        fontSize: compact ? 16 : 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      total == 1 ? '1 category in your catalog' : '$total categories in your catalog',
                      style: const TextStyle(color: _muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (!compact)
                FilledButton.icon(
                  onPressed: _startAdding,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add category'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search categories...',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _blue, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: docs.isEmpty
                ? _stateCard(
                    icon: total == 0 ? Icons.category_outlined : Icons.search_off_rounded,
                    title: total == 0 ? 'Start organizing your store' : 'No matching categories',
                    message: total == 0
                        ? 'Add your first category to help students browse products more easily.'
                        : 'Try another search term.',
                    action: total == 0
                        ? FilledButton.icon(
                            onPressed: _startAdding,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add your first category'),
                            style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
                          )
                        : TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.search_off_rounded),
                            label: const Text('Clear search'),
                          ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _categoryCard(docs[index], compact: width < 600),
                  ),
          ),
          if (compact)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startAdding,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add category'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, {required bool compact}) {
    final data = doc.data();
    final name = (data['name'] ?? data['title'] ?? doc.id).toString().trim();
    final description = (data['description'] ?? '').toString().trim();
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final imageSize = compact ? 70.0 : 78.0;
    final selected = _editingDoc?.id == doc.id;

    return Material(
      color: selected ? const Color(0xFFF5F9FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startEditing(doc),
        child: Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? const Color(0xFF90B8FF) : _border),
          ),
          child: Row(
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)),
                child: imageUrl.isNotEmpty
                    ? AppImage(
                        source: imageUrl,
                        fit: BoxFit.contain,
                        fallback: const Center(
                          child: Icon(Icons.category_outlined, color: _blue, size: 30),
                        ),
                      )
                    : Icon(Icons.category_outlined, color: _blue, size: compact ? 29 : 32),
              ),
              SizedBox(width: compact ? 10 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Untitled category' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: compact ? 13.5 : 14,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description.isEmpty ? 'No description added.' : description,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.4),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Category actions',
                icon: const Icon(Icons.more_vert_rounded, color: _muted),
                onSelected: (value) {
                  if (value == 'edit') _startEditing(doc);
                  if (value == 'delete') _deleteCategory(doc);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 9),
                      Text('Edit category'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 18),
                      SizedBox(width: 9),
                      Text('Delete category'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorPanel({bool mobile = false}) {
    final editing = _editingDoc != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(mobile ? 14 : 18, 15, mobile ? 10 : 16, 13),
            child: Row(
              children: [
                if (mobile)
                  IconButton(
                    tooltip: 'Back to categories',
                    onPressed: _closeMobileEditor,
                    icon: const Icon(Icons.arrow_back_rounded, color: _blue),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)),
                    child: Icon(
                      editing ? Icons.edit_note_rounded : Icons.category_outlined,
                      color: _blue,
                      size: 25,
                    ),
                  ),
                if (!mobile) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing ? 'Edit Category' : 'Add Category',
                        style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        editing ? 'Update this category for your store.' : 'Create a category to organize your catalog.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
                if (!mobile)
                  IconButton(
                    tooltip: 'Close editor',
                    onPressed: () {
                      setState(() {
                        _desktopEditorOpen = false;
                        _editingDoc = null;
                        _clearForm();
                      });
                    },
                    icon: const Icon(Icons.close_rounded, color: _muted),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EEF6)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 680;
                final details = _buildCategoryFields();
                final image = _buildImageSection(compact: !sideBySide);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(mobile ? 15 : 18),
                  child: sideBySide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: details),
                            const SizedBox(width: 18),
                            Expanded(flex: 5, child: image),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            details,
                            const SizedBox(height: 20),
                            image,
                          ],
                        ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EEF6)),
          Padding(
            padding: EdgeInsets.fromLTRB(15, 12, 15, mobile ? 14 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _saving || _uploading ? null : _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: Color(0xFFB9D0FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _saving || _uploading ? null : _saveCategory,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'Saving...' : editing ? 'Save changes' : 'Save category'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CATEGORY DETAILS',
          style: TextStyle(color: _blue, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 11),
        TextField(
          controller: _nameController,
          enabled: !_saving && !_uploading,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            'Category name',
            hint: 'e.g. Stationery',
            icon: Icons.category_outlined,
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _descriptionController,
          enabled: !_saving && !_uploading,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            'Description',
            hint: 'Describe the items in this category',
            icon: Icons.notes_rounded,
            alignLabel: true,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Keep the description short and clear so students can find the right products.',
          style: TextStyle(color: _muted, fontSize: 10.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildImageSection({required bool compact}) {
    final validUrl = _isValidImageUrl(_imageUrlController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CATEGORY IMAGE',
          style: TextStyle(color: _blue, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                height: compact ? 145 : 125,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(12)),
                child: _selectedImageBytes != null
                    ? Image.memory(_selectedImageBytes!, fit: BoxFit.contain)
                    : validUrl
                        ? AppImage(
                            source: _imageUrlController.text.trim(),
                            fit: BoxFit.contain,
                            placeholder: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
                            ),
                            fallback: const Center(
                              child: Icon(Icons.broken_image_outlined, color: _muted, size: 34),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: _blue, size: 37),
                              SizedBox(height: 8),
                              Text(
                                'Category image preview',
                                style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload an image or paste a URL',
                                style: TextStyle(color: _muted, fontSize: 10.5),
                              ),
                            ],
                          ),
              ),
              if (_selectedFileName != null) ...[
                const SizedBox(height: 8),
                Text(
                  _selectedFileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 11),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving || _uploading ? null : _pickAndUploadImage,
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(_uploading ? 'Uploading...' : 'Upload from device'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _saving || _uploading ? null : _openImageUrlEntry,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Use image URL'),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _pickAndUploadImage,
                        icon: const Icon(Icons.upload_file_rounded, size: 17),
                        label: Text(_uploading ? 'Uploading...' : 'Upload from device'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _openImageUrlEntry,
                        icon: const Icon(Icons.link_rounded, size: 17),
                        label: const Text('Use image URL'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageUrlController,
                enabled: !_saving && !_uploading,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  'Image URL (optional)',
                  hint: 'https://example.com/category.jpg',
                  icon: Icons.link_rounded,
                ).copyWith(
                  suffixIcon: _imageUrlController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear image URL',
                          onPressed: _saving || _uploading
                              ? null
                              : () {
                                  setState(() {
                                    _imageUrlController.clear();
                                    _selectedImageBytes = null;
                                    _selectedFileName = null;
                                  });
                                },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Use a JPG, PNG, WEBP or GIF image, or paste a public direct image URL.',
                style: TextStyle(color: _muted, fontSize: 10.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
    bool alignLabel = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFD8E4F4)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabel,
      prefixIcon: icon == null ? null : Icon(icon, size: 19, color: _muted),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFBFDFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _blue, width: 1.3),
      ),
    );
  }

  bool _isValidImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _openImageUrlEntry() async {
    if (_saving || _uploading) return;
    final urlController = TextEditingController(text: _imageUrlController.text.trim());
    final url = await showDialog<String>(
      context: context,
      builder: (urlContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Use image URL', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: urlController,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://example.com/category.jpg',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(urlContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = urlController.text.trim();
              if (!_isValidImageUrl(value)) {
                ScaffoldMessenger.of(urlContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid http:// or https:// image URL')),
                );
                return;
              }
              Navigator.pop(urlContext, value);
            },
            child: const Text('Use URL'),
          ),
        ],
      ),
    );
    urlController.dispose();
    if (!mounted || url == null || url.isEmpty) return;
    setState(() {
      _imageUrlController.text = url;
      _selectedImageBytes = null;
      _selectedFileName = 'Image URL';
    });
  }

  Future<void> _pickAndUploadImage() async {
    if (_saving || _uploading) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final filename = file.name.trim();
      final lowerName = filename.toLowerCase();
      final supported = lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png') ||
          lowerName.endsWith('.webp') ||
          lowerName.endsWith('.gif');
      if (!supported) {
        throw Exception('Please choose JPG, JPEG, PNG, WEBP or GIF.');
      }

      setState(() {
        _uploading = true;
        _selectedImageBytes = bytes;
        _selectedFileName = filename;
      });

      final downloadUrl = await ImageStorageService.upload(
        bytes: bytes,
        folder: 'categories',
        fileName: filename,
      );
      if (!mounted) return;
      setState(() {
        _imageUrlController.text = downloadUrl;
        _selectedFileName = '$filename • uploaded';
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded to GitHub Storage successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }
  }

  void _startAdding() {
    _clearForm();
    setState(() {
      _editingDoc = null;
      if (MediaQuery.sizeOf(context).width < 1120) {
        _mobileEditorOpen = true;
      } else {
        _desktopEditorOpen = true;
      }
    });
  }

  void _startEditing(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    _loadCategoryIntoEditor(doc);
    setState(() {
      _editingDoc = doc;
      if (MediaQuery.sizeOf(context).width < 1120) {
        _mobileEditorOpen = true;
      } else {
        _desktopEditorOpen = true;
      }
    });
  }

  void _loadCategoryIntoEditor(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    _nameController.text = (data['name'] ?? data['title'] ?? '').toString();
    _descriptionController.text = (data['description'] ?? '').toString();
    _imageUrlController.text = (data['imageUrl'] ?? '').toString();
    _selectedImageBytes = null;
    _selectedFileName = null;
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _selectedImageBytes = null;
    _selectedFileName = null;
  }

  void _cancelEditing() {
    if (MediaQuery.sizeOf(context).width < 1120) {
      _closeMobileEditor();
      return;
    }
    setState(() {
      _editingDoc = null;
      _clearForm();
      _desktopEditorOpen = false;
    });
  }

  void _closeMobileEditor() {
    setState(() {
      _mobileEditorOpen = false;
      _editingDoc = null;
      _clearForm();
    });
  }

  Future<void> _saveCategory() async {
    if (_saving || _uploading) return;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }
    if (imageUrl.isNotEmpty && !_isValidImageUrl(imageUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid public http:// or https:// image URL.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_editingDoc == null) {
        await FirebaseFirestore.instance.collection('categories').add({
          'name': name,
          'description': description,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully')),
        );
        _clearForm();
        setState(() {
          _saving = false;
          _mobileEditorOpen = false;
        });
      } else {
        await _editingDoc!.reference.update({
          'name': name,
          'description': description,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        setState(() {
          _saving = false;
          if (MediaQuery.sizeOf(context).width < 1120) {
            _mobileEditorOpen = false;
            _editingDoc = null;
            _clearForm();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database save failed: $e')),
      );
    }
  }

  Future<void> _deleteCategory(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      await _actions._delete(context, doc);
      if (!mounted) return;
      if (_editingDoc?.id == doc.id) {
        setState(() {
          _editingDoc = null;
          _clearForm();
          if (MediaQuery.sizeOf(context).width < 1120) _mobileEditorOpen = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete category: $e')),
      );
    }
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(20)),
                  child: Icon(icon, size: 32, color: _blue),
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.5),
                ),
                if (action != null) ...[
                  const SizedBox(height: 18),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Dedicated management workspace for Bundles. Uses the same visual language
/// and navigation as the Products and Categories screens.
class _BundlesWorkspace extends StatefulWidget {
  const _BundlesWorkspace();

  @override
  State<_BundlesWorkspace> createState() => _BundlesWorkspaceState();
}

class _BundlesWorkspaceState extends State<_BundlesWorkspace> {
  static const _canvas = Color(0xFFFAF8F3);
  static const _ink = Color(0xFF172554);
  static const _blue = Color(0xFF2563EB);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFDCE6F8);
  static const _softBlue = Color(0xFFEAF2FF);

  final _actions = const AdminManagementScreen(section: AdminSection.bundles);
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  QueryDocumentSnapshot<Map<String, dynamic>>? _editingDoc;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _mobileEditorOpen = false;
  bool _desktopEditorOpen = true;
  bool _saving = false;
  bool _uploading = false;
  int _refreshKey = 0;

  bool get _isCompact => MediaQuery.sizeOf(context).width < 1120;

  String get _adminName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final emailName = user?.email?.split('@').first.trim() ?? '';
    return emailName.isNotEmpty ? emailName : 'Administrator';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 1280;
    return Scaffold(
      backgroundColor: _canvas,
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: SafeArea(
                child: SingleChildScrollView(child: _buildSidebar(compact: true)),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSidebar) SizedBox(width: 238, child: _buildSidebar()),
          Expanded(
            child: Column(
              children: [
                _buildHeader(width: width, showSidebar: showSidebar),
                Expanded(child: _buildBody(width)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required double width, required bool showSidebar}) {
    final compact = width < 560;
    final veryNarrow = width < 390;
    return Container(
      height: compact ? 76 : 100,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : (showSidebar ? 30 : 24)),
      decoration: const BoxDecoration(
        color: _canvas,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!showSidebar)
            Builder(
              builder: (drawerContext) => IconButton(
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: _ink),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'Admin   /   Bundles',
                      style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                Text(
                  'Bundles',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 21 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                if (!compact)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Manage student bundles and package details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          if (compact)
            IconButton(
              tooltip: 'Refresh bundles',
              onPressed: () => setState(() => _refreshKey++),
              icon: const Icon(Icons.refresh_rounded, color: _blue),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() => _refreshKey++),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFB9D0FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
            ),
          const SizedBox(width: 7),
          FilledButton(
            onPressed: _saving || _uploading ? null : _startAdding,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 15, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: Size(veryNarrow ? 40 : 0, 42),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 19),
                if (!veryNarrow) ...[
                  const SizedBox(width: 5),
                  Text(compact ? 'Add' : 'Add Bundle'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool compact = false}) {
    return AdminNavigationSidebar(
      selectedSection: AdminSection.bundles,
      adminName: _adminName,
      compact: compact,
      onNavigate: (section) => _navigate(section, compact: compact),
      onSignOut: () async {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }

  void _navigate(AdminSection? section, {required bool compact}) {
    if (compact) Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (section == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
      } else if (section != AdminSection.bundles) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section)),
        );
      }
    });
  }

  Widget _buildBody(double width) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(_refreshKey),
      stream: FirebaseFirestore.instance.collection('bundles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _stateCard(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load bundles',
            message: 'Please check your connection and try again.',
            action: FilledButton.icon(
              onPressed: () => setState(() => _refreshKey++),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue)),
                SizedBox(height: 14),
                Text('Loading bundles...', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final query = _searchController.text.trim().toLowerCase();
        final visibleDocs = docs.where((doc) {
          final data = doc.data();
          final name = (data['name'] ?? data['title'] ?? doc.id).toString().toLowerCase();
          final description = (data['description'] ?? '').toString().toLowerCase();
          final price = (data['price'] ?? '').toString().toLowerCase();
          return query.isEmpty || name.contains(query) || description.contains(query) || price.contains(query);
        }).toList();

        if (width >= 1120 && !_mobileEditorOpen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _buildBundleListPane(docs: visibleDocs, total: docs.length, width: width),
              ),
              if (_desktopEditorOpen)
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 22, 18),
                    child: _buildEditorPanel(),
                  ),
                ),
            ],
          );
        }
        if (_mobileEditorOpen) {
          return Padding(
            padding: EdgeInsets.fromLTRB(width < 560 ? 12 : 22, 10, width < 560 ? 12 : 22, 18),
            child: _buildEditorPanel(mobile: true),
          );
        }
        return _buildBundleListPane(
          docs: visibleDocs,
          total: docs.length,
          width: width,
          fullWidth: true,
        );
      },
    );
  }

  Widget _buildBundleListPane({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required int total,
    required double width,
    bool fullWidth = false,
  }) {
    final compact = width < 560;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        fullWidth ? (compact ? 14 : 28) : (compact ? 12 : 22),
        18,
        fullWidth ? (compact ? 14 : 28) : (compact ? 12 : 18),
        compact ? 18 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bundle catalog',
                      style: TextStyle(color: _ink, fontSize: compact ? 16 : 19, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      total == 1 ? '1 bundle in your catalog' : '$total bundles in your catalog',
                      style: const TextStyle(color: _muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (!compact)
                FilledButton.icon(
                  onPressed: _startAdding,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Bundle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search bundles...',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.3)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: docs.isEmpty
                ? _stateCard(
                    icon: total == 0 ? Icons.inventory_2_outlined : Icons.search_off_rounded,
                    title: total == 0 ? 'No bundles yet' : 'No matching bundles',
                    message: total == 0
                        ? 'Add your first bundle to manage student essentials as one package.'
                        : 'Try another search term to find a bundle.',
                    action: total == 0
                        ? FilledButton.icon(
                            onPressed: _startAdding,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add your first bundle'),
                            style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
                          )
                        : TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('Clear search'),
                          ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _bundleListCard(docs[index], compact: width < 600),
                  ),
          ),
          if (compact)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startAdding,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Bundle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bundleListCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool compact,
  }) {
    final data = doc.data();
    final name = (data['name'] ?? data['title'] ?? doc.id).toString().trim();
    final description = (data['description'] ?? '').toString().trim();
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final price = _formatPrice(data['price']);
    final selected = _editingDoc?.id == doc.id;
    final imageSize = compact ? 66.0 : 78.0;

    return Material(
      color: selected ? const Color(0xFFF5F9FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startEditing(doc),
        child: Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? const Color(0xFF90B8FF) : _border),
          ),
          child: Row(
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)),
                child: imageUrl.isEmpty
                    ? Icon(Icons.auto_awesome_mosaic_outlined, color: _blue, size: compact ? 28 : 32)
                    : AppImage(
                        source: imageUrl,
                        fit: BoxFit.cover,
                        fallback: const Center(
                          child: Icon(Icons.broken_image_outlined, color: _blue, size: 25),
                        ),
                      ),
              ),
              SizedBox(width: compact ? 10 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Untitled bundle' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _ink, fontSize: compact ? 13 : 14, height: 1.3, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ink, fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description.isEmpty ? 'No description provided.' : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Bundle actions',
                icon: const Icon(Icons.more_vert_rounded, color: _muted),
                onSelected: (value) {
                  if (value == 'edit') _startEditing(doc);
                  if (value == 'delete') _deleteBundle(doc);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 19),
                      SizedBox(width: 9),
                      Text('Edit bundle'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 19),
                      SizedBox(width: 9),
                      Text('Delete bundle'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorPanel({bool mobile = false}) {
    final editing = _editingDoc != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(mobile ? 15 : 18, 16, mobile ? 12 : 16, 14),
            child: Row(
              children: [
                if (mobile)
                  IconButton(
                    tooltip: 'Back to bundles',
                    onPressed: _closeMobileEditor,
                    icon: const Icon(Icons.arrow_back_rounded, color: _blue),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)),
                    child: Icon(editing ? Icons.edit_note_rounded : Icons.auto_awesome_outlined, color: _blue, size: 25),
                  ),
                if (!mobile) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing ? 'Edit Bundle' : 'Add Bundle',
                        style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        editing ? 'Update the details for this student bundle.' : 'Enter details to create a new bundle.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
                if (!mobile)
                  IconButton(
                    tooltip: 'Close editor',
                    onPressed: _saving || _uploading
                        ? null
                        : () {
                            if (MediaQuery.sizeOf(context).width >= 1120) {
                              setState(() {
                                _desktopEditorOpen = false;
                                _editingDoc = null;
                                _clearForm();
                              });
                            } else {
                              _closeMobileEditor();
                            }
                          },
                    icon: const Icon(Icons.close_rounded, color: _muted),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7EDF7)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(mobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bundle details', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(label: 'Bundle name', hint: 'e.g. Exam Ready Kit', icon: Icons.inventory_2_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: _fieldDecoration(label: 'Description', hint: 'What is included in this bundle?', icon: Icons.notes_rounded).copyWith(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _fieldDecoration(label: 'Price (₹)', hint: '0.00', icon: Icons.currency_rupee_rounded),
                  ),
                  const SizedBox(height: 20),
                  const Text('Bundle image', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(height: 178, width: double.infinity, child: _buildImagePreview()),
                  ),
                  if (_selectedFileName != null) ...[
                    const SizedBox(height: 7),
                    Text(_selectedFileName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDecoration(label: 'Image URL', hint: 'https://example.com/image.jpg', icon: Icons.link_rounded).copyWith(
                      suffixIcon: _imageUrlController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear image URL',
                              onPressed: _saving || _uploading
                                  ? null
                                  : () => setState(() {
                                        _imageUrlController.clear();
                                        _selectedImageBytes = null;
                                        _selectedFileName = null;
                                      }),
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _uploadImage,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(_uploading ? 'Uploading...' : 'Upload from device'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _enterImageUrl,
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Use image URL'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose an image file or paste a public direct image URL.',
                    style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7EDF7)),
          Padding(
            padding: EdgeInsets.fromLTRB(mobile ? 14 : 18, 12, mobile ? 14 : 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving || _uploading ? null : _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving || _uploading ? null : _saveBundle,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _saving
                        ? const SizedBox(height: 17, width: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_saving ? 'Saving...' : editing ? 'Save changes' : 'Save bundle'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({required String label, required IconData icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _blue, width: 1.3)),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageBytes != null) {
      return Image.memory(_selectedImageBytes!, width: double.infinity, height: 178, fit: BoxFit.cover);
    }
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty && _isValidImageUrl(url)) {
      return AppImage(
        source: url,
        fit: BoxFit.cover,
        placeholder: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue)),
        fallback: Container(
          color: _softBlue,
          child: const Center(child: Icon(Icons.broken_image_outlined, color: _blue, size: 38)),
        ),
      );
    }
    return Container(
      color: _softBlue,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_mosaic_outlined, color: _blue, size: 38),
          SizedBox(height: 8),
          Text('Bundle image preview', style: TextStyle(color: _muted)),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '₹0';
    if (rawPrice is num) return '₹${rawPrice % 1 == 0 ? rawPrice.toStringAsFixed(0) : rawPrice.toStringAsFixed(2)}';
    return '₹${rawPrice.toString()}';
  }

  void _startAdding() {
    if (_saving || _uploading) return;
    setState(() {
      _editingDoc = null;
      _clearForm();
      if (_isCompact) {
        _mobileEditorOpen = true;
      } else {
        _desktopEditorOpen = true;
      }
    });
  }

  void _startEditing(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    if (_saving || _uploading) return;
    final data = doc.data();
    setState(() {
      _editingDoc = doc;
      _nameController.text = (data['name'] ?? data['title'] ?? '').toString();
      _descriptionController.text = (data['description'] ?? '').toString();
      _priceController.text = (data['price'] ?? '').toString();
      _imageUrlController.text = (data['imageUrl'] ?? '').toString();
      _selectedImageBytes = null;
      _selectedFileName = null;
      if (_isCompact) {
        _mobileEditorOpen = true;
      } else {
        _desktopEditorOpen = true;
      }
    });
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _imageUrlController.clear();
    _selectedImageBytes = null;
    _selectedFileName = null;
  }

  void _cancelEditing() {
    if (_saving || _uploading) return;
    setState(() {
      _editingDoc = null;
      _clearForm();
      if (_isCompact) _mobileEditorOpen = false;
    });
  }

  void _closeMobileEditor() {
    if (_saving || _uploading) return;
    setState(() {
      _mobileEditorOpen = false;
      _editingDoc = null;
      _clearForm();
    });
  }

  Future<void> _enterImageUrl() async {
    if (_saving || _uploading) return;
    final urlController = TextEditingController(text: _imageUrlController.text.trim());
    final url = await showDialog<String>(
      context: context,
      builder: (urlContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Use image URL', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: urlController,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Direct image URL',
            hintText: 'https://example.com/image.jpg',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(urlContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = urlController.text.trim();
              if (!_isValidImageUrl(value)) {
                ScaffoldMessenger.of(urlContext).showSnackBar(
                  const SnackBar(content: Text('Enter a valid http:// or https:// image URL')),
                );
                return;
              }
              Navigator.pop(urlContext, value);
            },
            child: const Text('Use URL'),
          ),
        ],
      ),
    );
    urlController.dispose();
    if (url == null || url.isEmpty || !mounted) return;
    setState(() {
      _imageUrlController.text = url;
      _selectedImageBytes = null;
      _selectedFileName = 'Image URL';
    });
  }

  Future<void> _uploadImage() async {
    if (_saving || _uploading) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      final filename = file.name.trim();
      final lowerName = filename.toLowerCase();
      final supported = lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png') ||
          lowerName.endsWith('.webp') ||
          lowerName.endsWith('.gif');
      if (!supported) throw Exception('Please choose JPG, JPEG, PNG, WEBP or GIF.');

      setState(() {
        _uploading = true;
        _selectedImageBytes = bytes;
        _selectedFileName = filename;
      });

      final downloadUrl = await ImageStorageService.upload(
        bytes: bytes,
        folder: 'bundles',
        fileName: filename,
      );

      if (!mounted) return;
      setState(() {
        _imageUrlController.text = downloadUrl;
        _selectedFileName = '$filename • uploaded';
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded to GitHub Storage successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }
  }

  Future<void> _saveBundle() async {
    if (_saving || _uploading) return;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final priceText = _priceController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bundle name.')),
      );
      return;
    }
    if (imageUrl.isNotEmpty && !_isValidImageUrl(imageUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid public http:// or https:// image URL.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_editingDoc == null) {
        await FirebaseFirestore.instance.collection('bundles').add({
          'name': name,
          'description': description,
          'price': double.tryParse(priceText) ?? 0,
          'category': 'General',
          'stock': 0,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully')),
        );
      } else {
        await _editingDoc!.reference.update({
          'name': name,
          'description': description,
          'price': double.tryParse(priceText) ?? 0,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }

      setState(() {
        _saving = false;
        _editingDoc = null;
        _clearForm();
        if (_isCompact) _mobileEditorOpen = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database save failed: $e')),
      );
    }
  }

  Future<void> _deleteBundle(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete bundle?', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await doc.reference.delete();
      if (!mounted) return;
      if (_editingDoc?.id == doc.id) {
        setState(() {
          _editingDoc = null;
          _clearForm();
          if (_isCompact) _mobileEditorOpen = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundle deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete bundle: $e')),
      );
    }
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(20)),
                  child: Icon(icon, size: 32, color: _blue),
                ),
                const SizedBox(height: 17),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.5)),
                if (action != null) ...[
                  const SizedBox(height: 18),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Dedicated Orders UI: desktop split view and mobile list/details navigation.
class _OrdersWorkspace extends StatefulWidget {
  const _OrdersWorkspace({required this.onStatusChanged});
  final Future<void> Function(String id, String status) onStatusChanged;

  @override
  State<_OrdersWorkspace> createState() => _OrdersWorkspaceState();
}

class _OrdersWorkspaceState extends State<_OrdersWorkspace> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFDCE6F8);
  static const softBlue = Color(0xFFEAF2FF);
  static const amber = Color(0xFF9A6700);
  static const green = Color(0xFF15803D);
  static const red = Color(0xFFB42318);
  static const purple = Color(0xFF5B4BDB);
  static const statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];

  String? selectedId;
  bool mobileDetailOpen = false;
  String? updatingId;

  bool get compact => MediaQuery.sizeOf(context).width < 980;

  String get _adminName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final emailName = user?.email?.split('@').first.trim() ?? '';
    return emailName.isNotEmpty ? emailName : 'Administrator';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 1100;

    return Scaffold(
      backgroundColor: cream,
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: SafeArea(
                child: SingleChildScrollView(child: _buildSidebar(compact: true)),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSidebar) SizedBox(width: 238, child: _buildSidebar()),
          Expanded(
            child: Column(
              children: [
                _buildHeader(width: width, showSidebar: showSidebar),
                Expanded(child: _buildOrdersContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required double width, required bool showSidebar}) {
    final compactWidth = width < 560;
    return Container(
      height: compactWidth ? 76 : 100,
      padding: EdgeInsets.symmetric(horizontal: compactWidth ? 10 : (showSidebar ? 30 : 24)),
      decoration: const BoxDecoration(
        color: cream,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!showSidebar)
            mobileDetailOpen && compact
                ? IconButton(
                    tooltip: 'Back to order list',
                    onPressed: () => setState(() => mobileDetailOpen = false),
                    icon: const Icon(Icons.arrow_back_rounded, color: ink),
                  )
                : Builder(
                    builder: (drawerContext) => IconButton(
                      tooltip: 'Open navigation',
                      onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                      icon: const Icon(Icons.menu_rounded, color: ink),
                    ),
                  ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compactWidth)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'Admin   /   Orders',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                Text(
                  compact && mobileDetailOpen ? 'Order details' : 'Orders',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: compactWidth ? 19 : 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                if (!compactWidth)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'View and manage customer orders.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool compact = false}) {
    return AdminNavigationSidebar(
      selectedSection: AdminSection.orders,
      adminName: _adminName,
      compact: compact,
      onNavigate: (section) => _navigate(section, compact: compact),
      onSignOut: () async {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      },
    );
  }

  void _navigate(AdminSection? section, {required bool compact}) {
    if (compact) Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (section == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
      } else if (section != AdminSection.orders) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminManagementScreen(section: section)),
        );
      }
    });
  }

  Widget _buildOrdersContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(22),
              child: _stateCard(Icons.cloud_off_outlined, 'Unable to load orders', 'Please check your connection and try again.', isError: true),
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.5, color: blue)),
                SizedBox(height: 14),
                Text('Loading orders…', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ));
          }

          final docs = snapshot.data!.docs;
          final pending = docs.where((d) => (d.data()['status'] ?? 'pending').toString().toLowerCase() == 'pending').length;
          final delivered = docs.where((d) => (d.data()['status'] ?? 'pending').toString().toLowerCase() == 'delivered').length;

          if (docs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _heading(),
                const SizedBox(height: 18),
                _stats(docs.length, pending, delivered),
                const SizedBox(height: 22),
                _stateCard(Icons.receipt_long_outlined, 'No orders yet.', 'Customer orders will appear here when they place an order.'),
              ],
            );
          }

          QueryDocumentSnapshot<Map<String, dynamic>> chosen = docs.first;
          for (final doc in docs) {
            if (doc.id == selectedId) {
              chosen = doc;
              break;
            }
          }

          if (compact && mobileDetailOpen) return _detailsScreen(chosen);
          if (compact) return _mobileList(docs, chosen, pending, delivered);
          return _desktopView(docs, chosen, pending, delivered);
        },
      );
  }

  Widget _heading() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Orders', style: TextStyle(color: ink, fontSize: 27, height: 1.14, letterSpacing: -.7, fontWeight: FontWeight.w900)),
      SizedBox(height: 7),
      Text('View and manage customer orders.', style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
    ],
  );

  Widget _stats(int all, int pending, int delivered) => Row(
    children: [
      Expanded(child: _statCard('All orders', all, Icons.receipt_long_outlined, blue, softBlue)),
      const SizedBox(width: 9),
      Expanded(child: _statCard('Pending', pending, Icons.schedule_rounded, amber, const Color(0xFFFFF4D6))),
      const SizedBox(width: 9),
      Expanded(child: _statCard('Delivered', delivered, Icons.check_circle_outline_rounded, green, const Color(0xFFE8F7EE))),
    ],
  );

  Widget _statCard(String label, int value, IconData icon, Color color, Color fill) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
    child: Row(children: [
      Container(width: 33, height: 33, decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value.toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 19, height: 1.05, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );

  Widget _desktopView(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      QueryDocumentSnapshot<Map<String, dynamic>> chosen, int pending, int delivered) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading(),
        const SizedBox(height: 17),
        _stats(docs.length, pending, delivered),
        const SizedBox(height: 18),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 5, child: _listPane(docs, chosen.id)),
          const SizedBox(width: 18),
          Expanded(flex: 6, child: _detailPane(chosen)),
        ])),
      ]),
    );
  }

  Widget _mobileList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      QueryDocumentSnapshot<Map<String, dynamic>> chosen, int pending, int delivered) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _heading(),
        const SizedBox(height: 17),
        _stats(docs.length, pending, delivered),
        const SizedBox(height: 22),
        Row(children: [
          const Expanded(child: Text('Order list', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900))),
          Text(docs.length.toString() + ' total', style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        ...docs.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _orderCard(doc, selected: chosen.id == doc.id, onTap: () => setState(() {
            selectedId = doc.id;
            mobileDetailOpen = true;
          })),
        )),
      ],
    );
  }

  Widget _listPane(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String chosenId) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(17, 17, 16, 14),
        child: Row(children: [
          const Expanded(child: Text('Order list', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(9)),
            child: Text(docs.length.toString(), style: const TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
      const Divider(height: 1, color: border),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (_, i) => _orderCard(docs[i], selected: docs[i].id == chosenId,
          onTap: () => setState(() => selectedId = docs[i].id)),
      )),
    ]),
  );

  Widget _orderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, {required bool selected, required VoidCallback onTap}) {
    final data = doc.data();
    final status = (data['status'] ?? 'pending').toString();
    final itemCount = _itemCount(data['items']);
    return Material(
      color: selected ? const Color(0xFFF2F6FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? const Color(0xFF8CB5FF) : const Color(0xFFE8EDF5), width: selected ? 1.4 : 1),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 39, height: 39, decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_outlined, color: blue, size: 20)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ORDER ID', style: TextStyle(color: muted, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('#' + doc.id, maxLines: 2, overflow: TextOverflow.ellipsis, softWrap: true,
                  style: const TextStyle(color: ink, fontSize: 12, height: 1.25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(_total(data['total']), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(itemCount.toString() + (itemCount == 1 ? ' item' : ' items'),
                  style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
            const SizedBox(width: 7),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _statusBadge(status),
              const SizedBox(height: 10),
              Icon(selected ? Icons.chevron_right_rounded : Icons.arrow_forward_ios_rounded, size: 14,
                  color: selected ? blue : const Color(0xFF94A3B8)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _detailsScreen(QueryDocumentSnapshot<Map<String, dynamic>> doc) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
    child: _detailPane(doc),
  );

  Widget _detailPane(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] ?? 'pending').toString();
    final items = data['items'] is List ? data['items'] as List : const <dynamic>[];
    final userId = (data['userId'] ?? '').toString().trim();
    final date = _date(data['createdAt']);
    final updating = updatingId == doc.id;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(width: 43, height: 43, decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.receipt_long_rounded, color: blue, size: 22)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Order details', style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900))),
            _statusBadge(status),
          ]),
          const SizedBox(height: 21),
          _sectionLabel('ORDER ID'),
          const SizedBox(height: 6),
          Text('#' + doc.id, maxLines: 3, overflow: TextOverflow.ellipsis, softWrap: true,
              style: const TextStyle(color: ink, fontSize: 14, height: 1.4, fontWeight: FontWeight.w800)),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(17), border: Border.all(color: border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ORDER TOTAL', style: TextStyle(color: muted, fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(_total(data['total']), style: const TextStyle(color: ink, fontSize: 28, letterSpacing: -.5, fontWeight: FontWeight.w900)),
              if (date != null) ...[
                const SizedBox(height: 11),
                const Divider(height: 1, color: border),
                const SizedBox(height: 11),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.calendar_today_outlined, color: muted, size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(date, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ],
            ]),
          ),
          if (userId.isNotEmpty) ...[
            const SizedBox(height: 17),
            _sectionLabel('CUSTOMER ACCOUNT ID'),
            const SizedBox(height: 6),
            Text(userId, maxLines: 2, overflow: TextOverflow.ellipsis, softWrap: true,
                style: const TextStyle(color: muted, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(child: Text('Items in this order', style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w900))),
            Text(items.length.toString() + (items.length == 1 ? ' item' : ' items'),
                style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(13)),
              child: const Text('No item details are available for this order.', style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
            )
          else
            ...items.map((item) {
              if (item is Map) return Padding(padding: const EdgeInsets.only(bottom: 9), child: _itemCard(item));
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(13)),
                  child: Text(item.toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 12)),
                ),
              );
            }),
          const SizedBox(height: 14),
          _sectionLabel('UPDATE ORDER STATUS'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFFFAFBFE), borderRadius: BorderRadius.circular(15), border: Border.all(color: border)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Current status', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                _statusBadge(status),
              ])),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                enabled: !updating,
                tooltip: 'Update order status',
                onSelected: (value) => _changeStatus(doc.id, value),
                itemBuilder: (_) => statuses.map((value) {
                  final current = value == status.toLowerCase().trim();
                  final color = _statusColor(value);
                  return PopupMenuItem<String>(
                    value: value,
                    child: SizedBox(width: 190, child: Row(children: [
                      Icon(current ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: current ? color : const Color(0xFF94A3B8), size: 17),
                      const SizedBox(width: 9),
                      Expanded(child: Text(_displayStatus(value), style: TextStyle(
                          color: current ? color : ink, fontSize: 13, fontWeight: current ? FontWeight.w800 : FontWeight.w600))),
                      if (current) Text('Current', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                    ])),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (updating) ...[
                      const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      const SizedBox(width: 7),
                    ],
                    Text(updating ? 'Saving' : 'Change', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 5),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _itemCard(Map item) {
    final itemName = (item['name'] ?? item['title'] ?? '').toString().trim();
    final quantity = item['quantity'];
    final price = item['price'];
    String? priceLabel;
    if (price is num) priceLabel = _currency(price.toDouble());
    if (priceLabel == null && price != null && double.tryParse(price.toString()) != null) {
      priceLabel = _currency(double.parse(price.toString()));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE8EDF5))),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.shopping_bag_outlined, color: blue, size: 17)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(itemName.isEmpty ? 'Order item' : itemName, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ink, fontSize: 12, height: 1.3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(quantity is num ? 'Quantity: ' + quantity.toInt().toString() : 'Quantity not provided',
              style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        if (priceLabel != null) ...[
          const SizedBox(width: 8),
          Text(priceLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ]),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(color: blue, fontSize: 10, letterSpacing: .9, fontWeight: FontWeight.w900));

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: .18))),
      child: Text(_displayStatus(status), maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 10, letterSpacing: .15, fontWeight: FontWeight.w900)),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending': return amber;
      case 'confirmed': return blue;
      case 'shipped': return purple;
      case 'delivered': return green;
      case 'cancelled': return red;
      default: return muted;
    }
  }

  String _displayStatus(String status) {
    final normalized = status.toLowerCase().trim();
    switch (normalized) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'shipped': return 'Shipped';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return normalized.isEmpty ? 'Unknown' : normalized[0].toUpperCase() + normalized.substring(1);
    }
  }

  int _itemCount(dynamic value) {
    if (value is! List) return 0;
    return value.fold<int>(0, (count, item) {
      if (item is Map && item['quantity'] is num) {
        final quantity = (item['quantity'] as num).toInt();
        return count + (quantity < 0 ? 0 : quantity);
      }
      return count + 1;
    });
  }

  String _total(dynamic value) {
    if (value is num) return _currency(value.toDouble());
    final parsed = double.tryParse((value ?? '').toString());
    return parsed == null ? 'Total unavailable' : _currency(parsed);
  }

  String _currency(double value) => '₹' + (value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2));

  String? _date(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;
    if (date == null) return null;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return date.day.toString() + ' ' + months[date.month - 1] + ' ' + date.year.toString() +
        ' • ' + hour.toString() + ':' + minute + ' ' + period;
  }

  Future<void> _changeStatus(String id, String status) async {
    if (updatingId != null) return;
    setState(() => updatingId = id);
    try {
      await widget.onStatusChanged(id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order status updated to ' + _displayStatus(status) + '.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not update order status: ' + error.toString()),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => updatingId = null);
    }
  }

  Widget _errorScreen() => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(child: _stateCard(Icons.cloud_off_outlined, 'Unable to load orders',
        'Please check your connection and try again.', isError: true)),
  );

  Widget _stateCard(IconData icon, String title, String message, {bool isError = false}) {
    final tint = isError ? red : blue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 62, height: 62, decoration: BoxDecoration(color: tint.withValues(alpha: .09), borderRadius: BorderRadius.circular(19)),
          child: Icon(icon, size: 30, color: tint)),
        const SizedBox(height: 15),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12, height: 1.5)),
      ]),
    );
  }
}


/// Shared navigation for every Campus Supply admin section.
class AdminNavigationSidebar extends StatelessWidget {
  const AdminNavigationSidebar({
    super.key,
    required this.selectedSection,
    required this.adminName,
    required this.compact,
    required this.onNavigate,
    required this.onSignOut,
  });

  final AdminSection? selectedSection;
  final String adminName;
  final bool compact;
  final ValueChanged<AdminSection?> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    Widget navItem(IconData icon, String title, AdminSection? section) {
      final selected = selectedSection == section;
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Material(
          color: selected ? const Color(0xFFE2EDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: selected ? null : () => onNavigate(section),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  Icon(icon, size: 21, color: selected ? const Color(0xFF2563EB) : const Color(0xFF172554)),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: selected ? const Color(0xFF2563EB) : const Color(0xFF172554),
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final safeName = adminName.trim().isEmpty ? 'Administrator' : adminName.trim();
    return Container(
      constraints: const BoxConstraints(minHeight: 540),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.fromLTRB(17, 24, 17, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Campus\nSupply',
                  style: TextStyle(
                    color: Color(0xFF172554),
                    fontSize: 19,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 31),
          navItem(Icons.home_rounded, 'Overview', null),
          navItem(Icons.inventory_2_outlined, 'Products', AdminSection.products),
          navItem(Icons.grid_view_rounded, 'Categories', AdminSection.categories),
          navItem(Icons.sell_outlined, 'Bundles', AdminSection.bundles),
          navItem(Icons.shopping_cart_outlined, 'Orders', AdminSection.orders),
          navItem(Icons.people_outline_rounded, 'Users', AdminSection.users),
          navItem(Icons.star_border_rounded, 'Reviews', AdminSection.reviews),
          if (!compact) const Spacer() else const SizedBox(height: 22),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  safeName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const Text('Administrator', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB42318),
              backgroundColor: const Color(0xFFFFF0F2),
              side: BorderSide.none,
              minimumSize: const Size.fromHeight(45),
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
