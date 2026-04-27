import 'package:flutter/material.dart';
import '../product/product_form_screen_new.dart';
import '../inventory/enhanced_inventory_screen.dart';
import '../analytics/analytics_screen_new.dart';
import '../common/image_capture_screen_real_ocr.dart';

/// Clean WhatsApp-Style Home Screen
class HomeScreenClean extends StatelessWidget {
  const HomeScreenClean({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Expiry Tracker'),
        backgroundColor: const Color(0xFF075E54), // WhatsApp green
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'What would you like to manage?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075E54),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Medicines Section
              _buildCategoryCard(
                context,
                'Medicines',
                Icons.medication,
                [
                  _buildActionTile(
                    context,
                    'Manual Entry',
                    Icons.edit,
                    () => _navigateToForm(context, true),
                  ),
                  _buildActionTile(
                    context,
                    'Scan via Image',
                    Icons.camera_alt,
                    () => _navigateToImageCapture(context, true),
                  ),
                  _buildActionTile(
                    context,
                    'Scan via Barcode',
                    Icons.qr_code_scanner,
                    () => _showComingSoon(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Products Section
              _buildCategoryCard(
                context,
                'Products',
                Icons.inventory_2,
                [
                  _buildActionTile(
                    context,
                    'Manual Entry',
                    Icons.edit,
                    () => _navigateToForm(context, false),
                  ),
                  _buildActionTile(
                    context,
                    'Scan via Image',
                    Icons.camera_alt,
                    () => _navigateToImageCapture(context, false),
                  ),
                  _buildActionTile(
                    context,
                    'Scan via Barcode',
                    Icons.qr_code_scanner,
                    () => _showComingSoon(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Quick Actions
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> actions,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: icon == Icons.medication 
                        ? const Color(0xFF128C7E).withOpacity(0.1)
                        : const Color(0xFF34B7F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: icon == Icons.medication 
                        ? const Color(0xFF128C7E)
                        : const Color(0xFF34B7F1),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    context,
                    'View Inventory',
                    Icons.inventory_2_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnhancedInventoryScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    context,
                    'View Analytics',
                    Icons.analytics_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsScreenNew(),
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

  Widget _buildQuickActionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF075E54).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF075E54).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF075E54),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF075E54),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, bool isMedicine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreenNew(
          isMedicine: isMedicine,
        ),
      ),
    );
    
    // Reload if item was saved
    if (result == true && mounted) {
      setState(() {
        // Trigger rebuild to refresh any displayed data
      });
    }
  }

  void _navigateToImageCapture(BuildContext context, bool isMedicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreenRealOCR(
          isMedicine: isMedicine,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('This feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
