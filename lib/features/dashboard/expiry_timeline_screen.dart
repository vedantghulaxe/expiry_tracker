import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/services/database_service.dart';

/// Detailed Expiry Timeline Screen
class ExpiryTimelineScreen extends StatefulWidget {
  final String? initialPeriod;

  const ExpiryTimelineScreen({
    super.key,
    this.initialPeriod,
  });

  @override
  State<ExpiryTimelineScreen> createState() => _ExpiryTimelineScreenState();
}

class _ExpiryTimelineScreenState extends State<ExpiryTimelineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  ProductRepository? _repository;
  
  List<Product> _todayProducts = [];
  List<Product> _weekProducts = [];
  List<Product> _monthProducts = [];
  List<Product> _laterProducts = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set initial tab based on period
    if (widget.initialPeriod != null) {
      switch (widget.initialPeriod) {
        case 'today':
          _tabController.index = 0;
          break;
        case 'week':
          _tabController.index = 1;
          break;
        case 'month':
          _tabController.index = 2;
          break;
        case 'later':
          _tabController.index = 3;
          break;
      }
    }
    
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    final database = await _dbService.database;
    _repository = ProductRepository(database);
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_repository == null) return;

    setState(() => _isLoading = true);

    try {
      final allProducts = await _repository!.getAllProducts();
      _categorizeProducts(allProducts);
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _categorizeProducts(List<Product> products) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final oneWeek = today.add(const Duration(days: 7));
    final oneMonth = today.add(const Duration(days: 30));

    _todayProducts = [];
    _weekProducts = [];
    _monthProducts = [];
    _laterProducts = [];

    for (final product in products) {
      if (product.expiryDate == null) continue;

      final expiryDate = DateTime(
        product.expiryDate!.year,
        product.expiryDate!.month,
        product.expiryDate!.day,
      );

      if (expiryDate.isBefore(tomorrow) || expiryDate.isAtSameMomentAs(tomorrow)) {
        _todayProducts.add(product);
      } else if (expiryDate.isBefore(oneWeek)) {
        _weekProducts.add(product);
      } else if (expiryDate.isBefore(oneMonth)) {
        _monthProducts.add(product);
      } else {
        _laterProducts.add(product);
      }
    }

    // Sort by expiry date (earliest first)
    _todayProducts.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    _weekProducts.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    _monthProducts.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    _laterProducts.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Timeline'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.warning_amber_rounded),
              text: 'Today (${_todayProducts.length})',
            ),
            Tab(
              icon: const Icon(Icons.event_note),
              text: 'Week (${_weekProducts.length})',
            ),
            Tab(
              icon: const Icon(Icons.calendar_today),
              text: 'Month (${_monthProducts.length})',
            ),
            Tab(
              icon: const Icon(Icons.schedule),
              text: 'Later (${_laterProducts.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_todayProducts, Colors.red, 'today'),
                _buildProductList(_weekProducts, Colors.orange, 'week'),
                _buildProductList(_monthProducts, Colors.amber, 'month'),
                _buildProductList(_laterProducts, Colors.green, 'later'),
              ],
            ),
    );
  }

  Widget _buildProductList(List<Product> products, Color color, String period) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products expiring in this period',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, color, period);
      },
    );
  }

  Widget _buildProductCard(Product product, Color color, String period) {
    final now = DateTime.now();
    final daysUntilExpiry = product.expiryDate!.difference(now).inDays;
    final isExpired = daysUntilExpiry < 0;
    final expiryText = isExpired
        ? 'Expired ${-daysUntilExpiry} days ago'
        : daysUntilExpiry == 0
            ? 'Expires today'
            : 'Expires in $daysUntilExpiry days';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image or Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.brand != null && product.brand!.isNotEmpty)
                      Text(
                        product.brand!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(product.expiryDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.red.withOpacity(0.1)
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        expiryText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.red : color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Button
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                onPressed: () => _confirmDelete(product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Brand', product.brand ?? 'N/A'),
                  _buildDetailRow('Category', product.category ?? 'N/A'),
                  _buildDetailRow(
                    'Expiry Date',
                    product.expiryDate != null
                        ? DateFormat('MMM dd, yyyy').format(product.expiryDate!)
                        : 'N/A',
                  ),
                  _buildDetailRow(
                    'Manufacturing Date',
                    product.manufacturingDate != null
                        ? DateFormat('MMM dd, yyyy')
                            .format(product.manufacturingDate!)
                        : 'N/A',
                  ),
                  if (product.quantity != null)
                    _buildDetailRow('Quantity', product.quantity!),
                  if (product.notes != null && product.notes!.isNotEmpty)
                    _buildDetailRow('Notes', product.notes!),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(product);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _repository != null) {
      await _repository!.deleteProduct(product.id);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
