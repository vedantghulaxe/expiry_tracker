import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/ui_helpers.dart';

/// Enhanced Inventory Screen with expiry color coding
class EnhancedInventoryScreen extends StatefulWidget {
  const EnhancedInventoryScreen({super.key});

  @override
  State<EnhancedInventoryScreen> createState() => _EnhancedInventoryScreenState();
}

class _EnhancedInventoryScreenState extends State<EnhancedInventoryScreen> {
  late MedicineRepository _repository;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _repository = MedicineRepository(DatabaseService().db);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    
    try {
      final medicines = await _repository.getAllMedicines();
      
      List<Map<String, dynamic>> allItems = [];
      
      // Process medicines
      for (final medicine in medicines) {
        allItems.add({
          'id': medicine.id,
          'name': medicine.name,
          'category': 'medicine',
          'expiryDate': medicine.createdAt, // Using available field
          'dosage': medicine.dosage,
          'manufacturer': medicine.brand,
        });
      }
      
      // Sort by expiry date (nearest first)
      allItems.sort((a, b) {
        final dateA = a['expiryDate'] as DateTime?;
        final dateB = b['expiryDate'] as DateTime?;
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return dateA.compareTo(dateB);
      });
      
      setState(() {
        _items = allItems;
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

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((item) => item['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          
          // Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildItemCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'medicine', 'product'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.capitalize()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to add items',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to scanner
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'Unknown';
    final category = item['category'] as String? ?? 'product';
    final expiryDate = item['expiryDate'] as DateTime?;
    final dosage = item['dosage'] as String?;
    final manufacturer = item['manufacturer'] as String?;
    final brand = item['brand'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: UIHelpers.createExpiryCard(
        expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
        context: context,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and category
              Row(
                children: [
                  Icon(
                    UIHelpers.getCategoryIcon(category),
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category.capitalize(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details
              if (dosage != null || manufacturer != null || brand != null) ...[
                Row(
                  children: [
                    if (dosage != null) ...[
                      Text(
                        'Dosage: $dosage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (dosage != null && (manufacturer != null || brand != null)) ...[
                      const Text(' · '),
                    ],
                    if (manufacturer != null) ...[
                      Text(
                        manufacturer,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ] else if (brand != null) ...[
                      Text(
                        brand,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Expiry Information
              Row(
                children: [
                  Icon(
                    UIHelpers.getExpiryIcon(expiryDate ?? DateTime.now()),
                    size: 16,
                    color: UIHelpers.getExpiryColor(expiryDate ?? DateTime.now()),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expiryDate != null
                        ? 'Expiry: ${UIHelpers.formatDate(expiryDate)}'
                        : 'No expiry date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UIHelpers.getExpiryColor(expiryDate ?? DateTime.now()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    UIHelpers.getDaysUntilExpiry(expiryDate ?? DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UIHelpers.getExpiryColor(expiryDate ?? DateTime.now()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
