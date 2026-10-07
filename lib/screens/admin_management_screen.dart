import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/material.dart';

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
      appBar: AppBar(title: Text(title)),
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
          if (snapshot.hasError) return Center(child: Text('Unable to load ' + title + '.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No ' + title + ' yet.'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _tile(context, docs[index]),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] ?? data['title'] ?? doc.id).toString();
    String subtitle;
    switch (section) {
      case AdminSection.products:
        subtitle = '₹' + (data['price'] ?? '-').toString() + ' • ' + (data['category'] ?? 'General').toString();
        break;
      case AdminSection.categories:
      case AdminSection.bundles:
        subtitle = (data['description'] ?? 'Catalog item').toString();
        break;
      case AdminSection.orders:
        subtitle = 'Status: ' + (data['status'] ?? 'pending').toString() + ' • Total: ₹' + (data['total'] ?? '-').toString();
        break;
      case AdminSection.users:
        subtitle = (data['email'] ?? '').toString() + ' • Role: ' + (data['role'] ?? 'user').toString();
        break;
      case AdminSection.reviews:
        subtitle = 'Rating: ' + (data['rating'] ?? '-').toString() + ' • ' + (data['comment'] ?? '').toString();
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFEAF2FF), child: Icon(icon, color: const Color(0xFF2563EB))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
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
      ),
    );
  }

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
    await FirebaseFirestore.instance.collection(collection).add(data);
    name.dispose();
    description.dispose();
    price.dispose();
    imageUrl.dispose();
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
    await doc.reference.update(update);
    name.dispose();
    description.dispose();
    price.dispose();
    imageUrl.dispose();
  }

  Future<bool?> _showItemDialog(
    BuildContext context, {
    required String title,
    required TextEditingController name,
    required TextEditingController description,
    required TextEditingController price,
    required TextEditingController imageUrl,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    if (section == AdminSection.products || section == AdminSection.bundles)
                      TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                    if (section == AdminSection.products || section == AdminSection.categories || section == AdminSection.bundles) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageUrl,
                        decoration: InputDecoration(
                          labelText: section == AdminSection.products
                              ? 'Product asset path'
                              : section == AdminSection.categories
                                  ? 'Category asset path'
                                  : 'Bundle asset path',
                          hintText: 'assets/image/products/backpack.svg',
                          prefixIcon: const Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use a bundled asset path such as assets/image/products/backpack.svg. Images are packaged with the app and are not uploaded to Firebase.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF707681)),
                      ),
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
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
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
