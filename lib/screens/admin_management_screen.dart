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

    final canAdd = section == AdminSection.products || section == AdminSection.categories || section == AdminSection.bundles;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(section == AdminSection.products ? 'Product' : section == AdminSection.categories ? 'Category' : 'Bundle'),
            )
          : null,
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
                    section == AdminSection.products ? 'Manage your campus store catalog' :
                    section == AdminSection.categories ? 'Organize your campus store' :
                    section == AdminSection.bundles ? 'Manage student bundles and package details' :
                    section == AdminSection.orders ? 'View and manage customer orders' :
                    section == AdminSection.users ? 'Manage campus store accounts and roles' :
                    'View and manage customer feedback',
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
    final saved = section == AdminSection.products
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
            title: section == AdminSection.categories ? 'Add category' : 'Add bundle',
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
    final saved = section == AdminSection.products
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
                title: const Text('Use image URL'),
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
              final folder = section == AdminSection.products
                  ? 'products'
                  : section == AdminSection.categories
                      ? 'categories'
                      : 'bundles';

              setDialogState(() {
                selectedImageBytes = bytes;
                selectedFileName = filename;
              });

              final downloadUrl = await ImageStorageService.upload(
                bytes: bytes,
                folder: folder,
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

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(title, style: const TextStyle(color: Color(0xFF172554), fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: MediaQuery.sizeOf(dialogContext).width < 584
                              ? MediaQuery.sizeOf(dialogContext).width - 64
                              : 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.label_outline_rounded)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded)),
                    ),
                    const SizedBox(height: 12),
                    if (section == AdminSection.products || section == AdminSection.bundles)
                      TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                      ),
                    if (section == AdminSection.products ||
                        section == AdminSection.categories ||
                        section == AdminSection.bundles) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: pickImage,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD6DCE5)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              if (selectedImageBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    selectedImageBytes!,
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Color(0xFF2563EB),
                                    size: 30,
                                  ),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedFileName ?? 'Upload Image',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedFileName == null
                                          ? 'Choose JPG, PNG, WEBP or GIF'
                                          : 'Image selected',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.add_photo_alternate_outlined),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: imageUrl,
                        decoration: InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: imageUrl.text.trim().isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear image URL',
                                  onPressed: () => setDialogState(() => imageUrl.clear()),
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text('Upload from device'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: enterImageUrl,
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('Use image URL'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use a local image (uploaded to GitHub Storage) or paste a public direct image URL.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      if (isValidImageUrl(imageUrl.text)) ...[
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Image preview',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 150,
                            child: AppImage(
                              source: imageUrl.text.trim(),
                              fit: BoxFit.cover,
                              placeholder: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              fallback: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image_outlined, size: 34),
                                    SizedBox(height: 6),
                                    Text('Image URL could not be loaded'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
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
                              SnackBar(
                                content: Text(
                                  'Save failed: ${e.toString().replaceFirst('Exception: ', '')}',
                                ),
                                duration: const Duration(seconds: 6),
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
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
  final TextEditingController _imageUrlController = TextEditingController();
  final FocusNode _imageUrlFocusNode = FocusNode();

  QueryDocumentSnapshot<Map<String, dynamic>>? _editingDoc;
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
    Widget navItem(
      IconData icon,
      String title, {
      AdminSection? section,
      bool selected = false,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Material(
          color: selected ? const Color(0xFFE2EDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigate(section, compact: compact),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  Icon(icon, size: 21, color: selected ? _blue : _ink),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: selected ? _blue : _ink,
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
                decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Campus\nSupply',
                  style: TextStyle(
                    color: _ink,
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
          navItem(Icons.home_rounded, 'Overview'),
          navItem(Icons.inventory_2_outlined, 'Products', section: AdminSection.products, selected: true),
          navItem(Icons.grid_view_rounded, 'Categories', section: AdminSection.categories),
          navItem(Icons.sell_outlined, 'Bundles', section: AdminSection.bundles),
          navItem(Icons.shopping_cart_outlined, 'Orders', section: AdminSection.orders),
          navItem(Icons.people_outline_rounded, 'Users', section: AdminSection.users),
          navItem(Icons.star_border_rounded, 'Reviews', section: AdminSection.reviews),
          if (!compact) const Spacer() else const SizedBox(height: 22),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _blue,
                child: Text(
                  _adminName.trim().isEmpty ? 'A' : _adminName.trim().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const Text('Administrator', style: TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
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
                    child: _buildEditorPanel(),
                  ),
                ),
            ],
          );
        }

        if (_mobileEditorOpen) {
          return Padding(
            padding: EdgeInsets.fromLTRB(screenWidth < 560 ? 12 : 22, 10, screenWidth < 560 ? 12 : 22, 18),
            child: _buildEditorPanel(mobile: true),
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

  Widget _buildEditorPanel({bool mobile = false}) {
    final editing = _editingDoc != null;
    final data = _editingDoc?.data() ?? <String, dynamic>{};
    final category = (data['category'] ?? 'General').toString().trim();
    final stock = (data['stock'] ?? 0).toString();

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
                  category: category.isEmpty ? 'General' : category,
                  stock: stock,
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
    required String category,
    required String stock,
    required bool compact,
  }) {
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('PRODUCT DETAILS', style: TextStyle(color: _blue, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
        const SizedBox(height: 11),
        TextField(
          controller: _nameController,
          enabled: !_saving && !_uploading,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration('Product name', hint: 'e.g. Campus backpack', icon: Icons.inventory_2_outlined),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _descriptionController,
          enabled: !_saving && !_uploading,
          minLines: 3,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration('Description', hint: 'Describe the product for students', icon: Icons.notes_rounded, alignLabel: true),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _priceController,
          enabled: !_saving && !_uploading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration('Price (₹)', hint: 'Enter price', icon: Icons.currency_rupee_rounded),
        ),
        const SizedBox(height: 13),
        if (compact) ...[
          _readOnlyValue('Category', category),
          const SizedBox(height: 13),
          _readOnlyValue('Stock quantity', stock),
        ] else
          Row(
            children: [
              Expanded(child: _readOnlyValue('Category', category)),
              const SizedBox(width: 12),
              Expanded(child: _readOnlyValue('Stock quantity', stock)),
            ],
          ),
        const SizedBox(height: 7),
        const Text(
          'Category and stock values are preserved as currently stored.',
          style: TextStyle(color: _muted, fontSize: 10.5, height: 1.4),
        ),
      ],
    );
    return fields;
  }

  Widget _readOnlyValue(String label, String value) {
    return InputDecorator(
      decoration: _inputDecoration(label, icon: label == 'Category' ? Icons.category_outlined : Icons.inventory_2_outlined)
          .copyWith(fillColor: const Color(0xFFF5F7FB)),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
      ),
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
    _imageUrlController.text = (data['imageUrl'] ?? '').toString();
    _selectedImageBytes = null;
    _selectedFileName = null;
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
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
    final imageUrl = _imageUrlController.text.trim();

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name.')),
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
