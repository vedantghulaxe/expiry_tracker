import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../product/product_form_screen_new.dart';
import '../../models/product_info.dart';
import '../../core/services/database_service.dart';

/// Inventory Screen - List all items with search and filter
class InventoryScreenNew extends StatefulWidget {
  const InventoryScreenNew({super.key});

  @override
  State<InventoryScreenNew> createState() => _InventoryScreenNewState();
}

class _InventoryScreenNewState extends State<InventoryScreenNew> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'All';
  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInventory();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadInventory();
    }
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('=== LOADING INVENTORY ===');
      final dbService = DatabaseService();
      final database = await dbService.database;
      final medicineRepo = MedicineRepository(database);
      final productRepo = ProductRepository(database);
      
      print('Fetching medicines...');
      final medicines = await medicineRepo.getAllMedicines();
      print('Fetched ${medicines.length} medicines');
      
      print('Fetching products...');
      final products = await productRepo.getAllProducts();
      print('Fetched ${products.length} products');
      
      print('Total items: ${medicines.length + products.length}');
      
      if (mounted) {
        setState(() {
          _allItems = [...medicines, ...products];
          _filteredItems = _allItems;
          _isLoading = false;
        });
      }
      
      print('Inventory loaded successfully');
      print('=========================');
    } catch (e, stackTrace) {
      print('=== INVENTORY LOAD ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('============================');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    final items = _allItems.where((item) {
      final name = item.name?.toLowerCase() ?? '';
      final matchesSearch = name.contains(query);
      
      bool matchesFilter = true;
      if (_filterType == 'Medicines') {
        matchesFilter = item is ProductInfo && item.isMedicine;
      } else if (_filterType == 'Products') {
        matchesFilter = item is ProductInfo && !item.isMedicine;
      }
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    setState(() => _filteredItems = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadInventory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) => _buildItemCard(_filteredItems[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterType,
                      isExpanded: true,
                      items: ['All', 'Medicines', 'Products'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _filterType = value!);
                        _filterItems();
                      },
                    ),
                  ),
                ),
              ),
            ],
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
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final isExpired = _isItemExpired(item);
    final isExpiringSoon = _isItemExpiringSoon(item);
    final isMedicine = item is ProductInfo ? item.isMedicine : false;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty && File(item.imageUrl!).existsSync();
    
    Color statusColor;
    String statusText;
    
    if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expiring Soon';
    } else {
      statusColor = Colors.green;
      statusText = 'Safe';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _editItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              if (hasImage)
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(item.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            isMedicine ? Icons.medication : Icons.shopping_bag,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    isMedicine ? Icons.medication : Icons.shopping_bag,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                ),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name ?? 'Unknown Item',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (item.brand != null && item.brand!.isNotEmpty)
                      Text(
                        item.brand!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isMedicine ? Icons.medication : Icons.shopping_bag,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMedicine ? 'Medicine' : 'Product',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(item.expiryDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => _editItem(item),
                          icon: const Icon(Icons.edit, size: 18),
                          color: Colors.blue,
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () => _deleteItem(item),
                          icon: const Icon(Icons.delete, size: 18),
                          color: Colors.red,
                          tooltip: 'Delete',
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

  bool _isItemExpired(dynamic item) {
    final expiryDate = item.expiryDate;
    if (expiryDate == null) return false;
    return expiryDate.isBefore(DateTime.now());
  }

  bool _isItemExpiringSoon(dynamic item) {
    final expiryDate = item.expiryDate;
    if (expiryDate == null) return false;
    
    final now = DateTime.now();
    final soonThreshold = now.add(const Duration(days: 7));
    
    return expiryDate.isAfter(now) && expiryDate.isBefore(soonThreshold);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editItem(dynamic item) {
    if (item is ProductInfo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFormScreenNew(
            productInfo: item,
            existingItem: item,
            isEditing: true,
            isMedicine: item.isMedicine,
          ),
        ),
      ).then((_) => _loadInventory());
    } else {
      // Handle medicine items if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit functionality for medicines coming soon!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _deleteItem(dynamic item) {
    if (item is ProductInfo) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final dbService = DatabaseService();
                  final database = await dbService.database;
                  
                  if (item.isMedicine) {
                    final medicineRepo = MedicineRepository(database);
                    await medicineRepo.deleteMedicine(item.id!);
                  } else {
                    final productRepo = ProductRepository(database);
                    await productRepo.deleteProduct(item.id!);
                  }
                  
                  _loadInventory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting item: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }
}
