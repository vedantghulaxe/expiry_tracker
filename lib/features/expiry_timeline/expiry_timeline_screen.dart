import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../models/product_info.dart';
import '../../core/services/database_service.dart';

class ExpiryTimelineScreen extends StatefulWidget {
  const ExpiryTimelineScreen({super.key});

  @override
  State<ExpiryTimelineScreen> createState() => _ExpiryTimelineScreenState();
}

class _ExpiryTimelineScreenState extends State<ExpiryTimelineScreen> {
  late List<ProductInfo> _allItems;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();
    final database = await dbService.database;
      final items = await database.getAllItems();
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekFromNow = today.subtract(const Duration(days: 7));
    final monthFromNow = DateTime(now.year, now.month, 1);

    // Group items by time periods
    final todayItems = _allItems.where((item) {
      if (item.expiryDate == null) return false;
      final expiryDate = item.expiryDate!;
      return expiryDate.year == today.year &&
             expiryDate.month == today.month &&
             expiryDate.day == today.day;
    }).toList();

    final weekItems = _allItems.where((item) {
      if (item.expiryDate == null) return false;
      final expiryDate = item.expiryDate!;
      return !expiryDate.isBefore(today) && 
             expiryDate.isBefore(weekFromNow) &&
             expiryDate.isAfter(today);
    }).toList();

    final monthItems = _allItems.where((item) {
      if (item.expiryDate == null) return false;
      final expiryDate = item.expiryDate!;
      return !expiryDate.isBefore(monthFromNow) && 
             expiryDate.isAfter(monthFromNow);
    }).toList();

    final laterItems = _allItems.where((item) {
      if (item.expiryDate == null) return false;
      final expiryDate = item.expiryDate!;
      return expiryDate.isAfter(monthFromNow);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Timeline'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTimelineSection('📅 Today', todayItems, Colors.red),
          const SizedBox(height: 16),
          _buildTimelineSection('📆 This Week', weekItems, Colors.orange),
          const SizedBox(height: 16),
          _buildTimelineSection('🗓️ This Month', monthItems, Colors.blue),
          const SizedBox(height: 16),
          _buildTimelineSection('📦 Later', laterItems, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(String title, List<ProductInfo> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No items in this period',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          )
        else
          ...items.map((item) => _buildItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildItemCard(ProductInfo item) {
    final now = DateTime.now();
    final daysUntilExpiry = item.expiryDate?.difference(now).inDays ?? 999;
    final isExpired = daysUntilExpiry < 0;
    final isExpiringSoon = daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
    final statusColor = isExpired ? Colors.red : isExpiringSoon ? Colors.orange : Colors.green;
    final statusIcon = isExpired ? Icons.dangerous : isExpiringSoon ? Icons.warning : Icons.check_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to item details (you can implement this later)
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    item.category == 'Medicine' ? '💊' : '🥫',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? 'Unknown Item',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.brand != null && item.brand!.isNotEmpty)
                      Text(
                        item.brand!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${item.expiryDate != null ? DateFormat('MMM dd, yyyy').format(item.expiryDate!) : 'Not set'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpired ? 'Expired' : isExpiringSoon ? 'Expiring Soon' : 'Safe',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
