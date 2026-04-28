import 'package:flutter/material.dart';
import '../product/product_form_screen_new.dart';
import '../inventory/inventory_screen_new.dart';
import 'package:expiry_tracker_app/features/common/image_capture_screen_simple.dart';
import '../settings/settings_screen.dart';
import '../expiry_timeline/expiry_timeline_screen.dart';
import 'expiry_summary_widget.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../core/services/database_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/utils/expiry_insights.dart';
import '../../data/database/app_database.dart';
import '../../models/product_info.dart';
import '../security/biometric_check_screen.dart';

/// Unified Dashboard Screen
/// Combines Home and Analytics functionality
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ProductRepository _productRepo;
  late MedicineRepository _medicineRepo;
  List<ProductInfo> _products = [];
  List<ProductInfo> _medicines = [];
  bool _isLoading = false;
  Widget? child;
  
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
    _initializeRepos();
  }

  Future<void> _initializeRepos() async {
    try {
      final dbService = DatabaseService();
      final database = await dbService.database;
      _productRepo = ProductRepository(database);
      _medicineRepo = MedicineRepository(database);
      _loadData();
    } catch (e) {
      print('=== Dashboard initialization error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
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
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Expiry Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              ThemeService.currentTheme == ThemeMode.dark 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
            ),
            onPressed: () {
              ThemeService.toggleTheme();
            },
            tooltip: ThemeService.currentTheme == ThemeMode.dark 
                ? 'Switch to Light Mode' 
                : 'Switch to Dark Mode',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              print('=== SETTINGS BUTTON PRESSED ===');
              print('Using Navigator.push with MaterialPageRoute');
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) {
                  print('=== SETTINGS NAVIGATION SUCCESSFUL ===');
                }).catchError((e) {
                  print('=== SETTINGS NAVIGATION ERROR: $e ===');
                });
              } catch (e) {
                print('=== SETTINGS NAVIGATION ERROR: $e ===');
              }
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActionsSection(),
                    const SizedBox(height: 20),
                    const ExpirySummaryWidget(),
                    const SizedBox(height: 20),
                    _buildRecentItemsSection(),
                    const SizedBox(height: 20),
                    _buildAnalyticsOverviewSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Medicine',
                Icons.medication,
                Colors.blue,
                () => _navigateToForm(context, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Add Product',
                Icons.shopping_bag,
                Colors.green,
                () => _navigateToForm(context, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Scan Medicine',
                Icons.camera_alt,
                Colors.orange,
                () => _navigateToScan(context, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Scan Product',
                Icons.camera_alt,
                Colors.purple,
                () => _navigateToScan(context, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Biometric Check',
                Icons.fingerprint,
                Colors.purple,
                () => _navigateToBiometricCheck(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF075E54),
          ),
        ),
        const SizedBox(height: 16),
        
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Items', 
                totalItems.toString(), 
                Icons.inventory, 
                Colors.blue,
                onTap: () => _navigateToInventory('all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Expired', 
                expiredItems.toString(), 
                Icons.error, 
                Colors.red,
                onTap: () => _navigateToInventory('expired'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Expiring Soon', 
                expiringSoonItems.toString(), 
                Icons.warning, 
                Colors.orange,
                onTap: () => _navigateToInventory('expiring_soon'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Safe', 
                safeItems.toString(), 
                Icons.check_circle, 
                Colors.green,
                onTap: () => _navigateToInventory('safe'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Medicines', 
                totalMedicines.toString(), 
                Icons.medication, 
                Colors.purple,
                onTap: () => _navigateToInventory('medicines'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Products', 
                totalProducts.toString(), 
                Icons.shopping_bag, 
                Colors.teal,
                onTap: () => _navigateToInventory('products'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(icon, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (onTap != null)
                const SizedBox(height: 4),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItemsSection() {
    final allItems = [..._products, ..._medicines];
    final recentItems = allItems.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF075E54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryScreenNew(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View Inventory',
                Icons.inventory,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryScreenNew(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View Timeline',
                Icons.timeline,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpiryTimelineScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Expiry Calendar',
                Icons.calendar_today,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpiryTimelineScreen(),
                    ),
                  );
                },
              ),
            ),
                      ],
        ),
        const SizedBox(height: 16),
        
        if (recentItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No items yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start by adding your first item',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          ...recentItems.map((item) {
            final isMedicine = item.isMedicine;
            final name = item.name ?? 'Unknown';
            final expiryDate = item.expiryDate;
            final daysRemaining = expiryDate != null 
                ? ExpiryInsights.getDaysRemaining(expiryDate!) 
                : null;
            final expiryStatus = expiryDate != null 
                ? ExpiryInsights.getExpiryStatus(expiryDate!) 
                : null;
            final expiryColor = expiryDate != null 
                ? ExpiryInsights.getStatusColor(expiryStatus!) 
                : Colors.grey;
                
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMedicine ? Colors.purple.shade100 : Colors.green.shade100,
                    child: Icon(
                      isMedicine ? Icons.medication : Icons.shopping_bag,
                      color: isMedicine ? Colors.purple : Colors.green,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    expiryDate != null 
                        ? 'Expires: ${_formatDate(expiryDate!)}'
                        : 'No expiry date',
                    style: TextStyle(
                      color: expiryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: expiryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(daysRemaining),
                      style: TextStyle(
                        color: expiryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(int? daysRemaining) {
    if (daysRemaining == null) return 'Unknown';
    if (daysRemaining < 0) return 'Expired';
    if (daysRemaining <= 7) return 'Expiring Soon';
    return 'Safe';
  }

  void _navigateToForm(BuildContext context, bool isMedicine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreenNew(
          isMedicine: isMedicine,
          isEditing: false,
        ),
      ),
    );
    
    // Reload dashboard if item was saved
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _navigateToScan(BuildContext context, bool isMedicine) {
    // Navigate to image capture screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreenSimple(
          isMedicine: isMedicine,
        ),
      ),
    );
  }

  void _navigateToBarcodeScan(BuildContext context, bool isMedicine) {
    // Navigate to barcode scanning screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreenSimple(
          isMedicine: isMedicine,
        ),
      ),
    );
  }

  void _navigateToInventory(String filterType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryScreenNew(),
      ),
    );
  }

  void _navigateToBiometricCheck(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BiometricCheckScreen(),
      ),
    );
  }

  
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToForm(context, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_bag, size: 32, color: Colors.green),
                          const SizedBox(height: 8),
                          Text('Add Product', style: TextStyle(color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToForm(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.medication, size: 32, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text('Add Medicine', style: TextStyle(color: Colors.blue.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScan(context, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text('Scan Product', style: TextStyle(color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScan(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Colors.purple),
                          const SizedBox(height: 8),
                          Text('Scan Medicine', style: TextStyle(color: Colors.purple.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Barcode scanning options
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToBarcodeScan(context, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner, size: 32, color: Colors.purple),
                          const SizedBox(height: 8),
                          Text('Scan Barcode', style: TextStyle(color: Colors.purple.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToBarcodeScan(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner, size: 32, color: Colors.indigo),
                          const SizedBox(height: 8),
                          Text('Scan Medicine\nBarcode', style: TextStyle(color: Colors.indigo.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
