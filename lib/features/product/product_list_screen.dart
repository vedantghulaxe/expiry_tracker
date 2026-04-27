import 'package:flutter/material.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/services/database_service.dart';
import '../../models/product_info.dart';
import '../../core/services/logger_service.dart';
import '../product/product_form_screen_new.dart';
import '../product/product_entry_options_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository(DatabaseService().db);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductInfo>>(
        stream: repository.watchAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final products = snapshot.data ?? [];
          
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No products found', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: product.imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(product.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, 
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                      )
                    : const CircleAvatar(child: Icon(Icons.shopping_cart)),
                  title: Text(product.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brand != null) Text(product.brand!),
                      const SizedBox(height: 4),
                      Text(
                        'Expires: ${product.expiryDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                        style: TextStyle(
                          color: _getExpiryColor(product.expiryDate),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Details
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const ProductEntryOptionsScreen(),
    );
  }

  Color _getExpiryColor(DateTime? expiryDate) {
    if (expiryDate == null) return Colors.grey;
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < 0) return Colors.red;
    if (difference <= 7) return Colors.orange;
    return Colors.green;
  }
}
