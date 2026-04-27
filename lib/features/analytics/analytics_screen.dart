import 'package:flutter/material.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/expiry_insights.dart';
import '../../data/database/app_database.dart';
import '../../models/product_info.dart';

/// Analytics Screen
/// Shows comprehensive data insights and charts
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late ProductRepository _productRepo;
  late MedicineRepository _medicineRepo;
  List<ProductInfo> _products = [];
  List<ProductInfo> _medicines = [];
  bool _isLoading = true;
  
  // Analytics data
  int totalItems = 0;
  int expiredItems = 0;
  int expiringSoonItems = 0;
  int safeItems = 0;
  int totalProducts = 0;
  int totalMedicines = 0;

  @override
  void initState() {
    super.initState();
    _productRepo = ProductRepository(DatabaseService().db);
    _medicineRepo = MedicineRepository(DatabaseService().db);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productRepo.getAllProducts();
      final medicines = await _medicineRepo.getAllMedicines();
      
      // Calculate analytics
      int expired = 0;
      int expiringSoon = 0;
      int safe = 0;
      
      // Process products
      for (final product in products) {
        if (product.expiryDate != null) {
          final daysRemaining = ExpiryInsights.getDaysRemaining(product.expiryDate!);
          if (daysRemaining < 0) {
            expired++;
          } else if (daysRemaining <= 7) {
            expiringSoon++;
          } else {
            safe++;
          }
        }
      }
      
      // Process medicines
      for (final medicine in medicines) {
        if (medicine.expiryDate != null) {
          final daysRemaining = ExpiryInsights.getDaysRemaining(medicine.expiryDate!);
          if (daysRemaining < 0) {
            expired++;
          } else if (daysRemaining <= 7) {
            expiringSoon++;
          } else {
            safe++;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _products = products;
          _medicines = medicines;
          totalProducts = products.length;
          totalMedicines = medicines.length;
          totalItems = products.length + medicines.length;
          expiredItems = expired;
          expiringSoonItems = expiringSoon;
          safeItems = safe;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics Dashboard',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewSection(),
                    const SizedBox(height: 32),
                    
                    // Category Distribution
                    _buildCategorySection(),
                    const SizedBox(height: 32),
                    
                    // Expiry Status Distribution
                    _buildExpirySection(),
                    const SizedBox(height: 32),
                    
                    // Recent Items
                    _buildRecentItemsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard('Total Items', totalItems, Colors.blue, Icons.inventory_2_outlined),
            _buildStatCard('Products', totalProducts, Colors.purple, Icons.shopping_bag_outlined),
            _buildStatCard('Medicines', totalMedicines, Colors.green, Icons.medication_outlined),
            _buildStatCard('Safe Items', safeItems, Colors.teal, Icons.check_circle_outline),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Distribution',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Simple Pie Chart Representation
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      // Pie Chart Placeholder
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pie_chart, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Products vs Medicines',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Legend
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Products', totalProducts, Colors.purple),
                            const SizedBox(height: 12),
                            _buildLegendItem('Medicines', totalMedicines, Colors.green),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Percentages
                if (totalItems > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: totalProducts / totalItems,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${((totalProducts / totalItems) * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Products: ${((totalProducts / totalItems) * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiry Status',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildExpiryCard('Expired', expiredItems, Colors.red, Icons.error_outline),
            _buildExpiryCard('Expiring Soon', expiringSoonItems, Colors.orange, Icons.warning_amber_outlined),
            _buildExpiryCard('Safe', safeItems, Colors.green, Icons.check_circle_outline),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Items',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              // Products
              if (_products.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined, color: Colors.purple),
                  title: Text('Latest Product: ${_products.last.name}'),
                  subtitle: Text('Added: ${_products.last.createdAt?.toString().split(' ')[0] ?? 'Unknown'}'),
                ),
                const Divider(),
              ],
              // Medicines
              if (_medicines.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.medication_outlined, color: Colors.green),
                  title: Text('Latest Medicine: ${_medicines.last.name}'),
                  subtitle: Text('Added: ${_medicines.last.createdAt?.toString().split(' ')[0] ?? 'Unknown'}'),
                ),
              ],
              if (_products.isEmpty && _medicines.isEmpty)
                const ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text('No items yet'),
                  subtitle: Text('Start adding items to see analytics'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryCard(String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ($value)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
