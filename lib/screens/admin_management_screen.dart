import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/image_storage_service.dart';
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
    final saved = await _showItemDialog(
      context,
      title: section == AdminSection.products
          ? 'Add product'
          : section == AdminSection.categories
              ? 'Add category'
              : 'Add bundle',
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
    final saved = await _showItemDialog(
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
