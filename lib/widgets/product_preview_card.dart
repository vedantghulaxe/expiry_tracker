import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_info.dart';

class ProductPreviewCard extends StatelessWidget {
  final ProductInfo productInfo;
  final VoidCallback onAddToInventory;
  final VoidCallback onEdit;

  const ProductPreviewCard({
    super.key,
    required this.productInfo,
    required this.onAddToInventory,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image and Basic Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                if (productInfo.imageUrl != null && productInfo.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: productInfo.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                
                const SizedBox(width: 16),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (productInfo.name != null)
                        Text(
                          productInfo.name!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      if (productInfo.brand != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Brand: ${productInfo.brand!}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      
                      if (productInfo.category != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: productInfo.isMedicine 
                                  ? Colors.red.shade50 
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              productInfo.category!,
                              style: TextStyle(
                                fontSize: 12,
                                color: productInfo.isMedicine 
                                    ? Colors.red.shade700 
                                    : Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional Details
            if (productInfo.isMedicine) ...[
              _buildMedicineDetails(),
            ] else ...[
              _buildProductDetails(),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddToInventory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Inventory'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (productInfo.ingredients != null) ...[
          _buildDetailRow('Ingredients', productInfo.ingredients!),
          const SizedBox(height: 8),
        ],
        if (productInfo.quantity != null) ...[
          _buildDetailRow('Quantity', productInfo.quantity!),
          const SizedBox(height: 8),
        ],
        if (productInfo.packaging != null) ...[
          _buildDetailRow('Packaging', productInfo.packaging!),
          const SizedBox(height: 8),
        ],
        if (productInfo.origins != null) ...[
          _buildDetailRow('Origins', productInfo.origins!),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildMedicineDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (productInfo.dosage != null) ...[
          _buildDetailRow('Dosage', productInfo.dosage!),
          const SizedBox(height: 8),
        ],
        if (productInfo.uses != null) ...[
          _buildDetailRow('Uses', productInfo.uses!),
          const SizedBox(height: 8),
        ],
        if (productInfo.sideEffects != null) ...[
          _buildDetailRow('Side Effects', productInfo.sideEffects!),
          const SizedBox(height: 8),
        ],
        if (productInfo.warnings != null) ...[
          _buildDetailRow('Warnings', productInfo.warnings!),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
