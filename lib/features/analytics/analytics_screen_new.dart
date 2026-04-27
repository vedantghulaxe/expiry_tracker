import 'package:flutter/material.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/expiry_insights.dart';

/// Analytics Screen - Show statistics and charts
class AnalyticsScreenNew extends StatefulWidget {
  const AnalyticsScreenNew({super.key});

  @override
  State<AnalyticsScreenNew> createState() => _AnalyticsScreenNewState();
}

class _AnalyticsScreenNewState extends State<AnalyticsScreenNew> {
  int _totalItems = 0;
  int _expiredItems = 0;
  int _expiringSoonItems = 0;
  int _medicines = 0;
  int _products = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final db = DatabaseService().db;
      final medicines = await MedicineRepository(db).getAllMedicines();
      final products = await ProductRepository(db).getAllProducts();
      
      final allItems = [...medicines, ...products];

      setState(() {
        _totalItems = allItems.length;
        _medicines = medicines.length;
        _products = products.length;
        
        _expiredItems = allItems.where((item) => 
          ExpiryInsights.getExpiryStatus(item.expiryDate) == ExpiryStatus.expired
        ).length;
        
        _expiringSoonItems = allItems.where((item) => 
          ExpiryInsights.getExpiryStatus(item.expiryDate) == ExpiryStatus.expiringSoon
        ).length;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildCategoryChart(),
                    const SizedBox(height: 24),
                    _buildStatusChart(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Items', _totalItems.toString(), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Expired', _expiredItems.toString(), Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Expiring Soon', _expiringSoonItems.toString(), Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Safe Items', (_totalItems - _expiredItems - _expiringSoonItems).toString(), Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildSimpleBarChart(
                ['Medicines', 'Products'],
                [_medicines, _products],
                [Colors.red, Colors.blue],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    final safeItems = _totalItems - _expiredItems - _expiringSoonItems;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Overview',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildSimpleBarChart(
                ['Safe', 'Expiring Soon', 'Expired'],
                [safeItems, _expiringSoonItems, _expiredItems],
                [Colors.green, Colors.orange, Colors.red],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart(List<String> labels, List<int> values, List<Color> colors) {
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(labels.length, (index) {
        final value = values[index];
        final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: 150 * percentage,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels[index],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }),
    );
  }
}
