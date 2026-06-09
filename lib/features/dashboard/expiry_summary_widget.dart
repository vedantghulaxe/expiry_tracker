import 'package:flutter/material.dart';
import '../../core/services/theme_service.dart';
import '../dashboard/expiry_timeline_screen.dart';
import '../inventory/inventory_screen_new.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/expiry_insights.dart';
import '../../models/product_info.dart';

class ExpirySummaryWidget extends StatefulWidget {
  const ExpirySummaryWidget({super.key});

  @override
  State<ExpirySummaryWidget> createState() => _ExpirySummaryWidgetState();
}

class _ExpirySummaryWidgetState extends State<ExpirySummaryWidget> {
  int _expiredCount = 0;
  int _expiringSoonCount = 0;
  int _safeCount = 0;
  int _totalCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dbService = DatabaseService();
      final database = await dbService.database;
      final productRepo = ProductRepository(database);
      final medicineRepo = MedicineRepository(database);

      final products = await productRepo.getAllProducts();
      final medicines = await medicineRepo.getAllMedicines();

      int expired = 0;
      int expiringSoon = 0;
      int safe = 0;

      // Process all items
      final allItems = [...products, ...medicines];
      for (final item in allItems) {
        if (item.expiryDate != null) {
          final daysRemaining = ExpiryInsights.getDaysRemaining(item.expiryDate!);
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
          _expiredCount = expired;
          _expiringSoonCount = expiringSoon;
          _safeCount = safe;
          _totalCount = allItems.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading expiry summary: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeService.currentTheme == ThemeMode.dark 
            ? Colors.grey[800] 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expiry Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpiryTimelineScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.timeline),
                      label: const Text('Timeline'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(context, 'Expired', _expiredCount.toString(), Colors.red, Icons.warning),
                    const SizedBox(width: 12),
                    _buildStatCard(context, 'Expiring Soon', _expiringSoonCount.toString(), Colors.orange, Icons.schedule),
                    const SizedBox(width: 12),
                    _buildStatCard(context, 'Safe', _safeCount.toString(), Colors.green, Icons.check_circle),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Items: $_totalCount',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InventoryScreenNew(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.inventory, size: 16),
                        label: const Text('View All', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String count, Color color, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InventoryScreenNew(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
