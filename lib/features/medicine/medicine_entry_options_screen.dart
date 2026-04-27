import 'package:flutter/material.dart';
import 'medicine_screen.dart';
import 'manual_medicine_entry_screen.dart';
import '../common/image_capture_screen_simple.dart';

/// Medicine Entry Options Screen
/// Shows dual entry options: AI Scan and Manual Entry
class MedicineEntryOptionsScreen extends StatelessWidget {
  const MedicineEntryOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Medicine',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medication,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How would you like to add medicine?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose between AI-powered scanning or manual entry',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Options
            Expanded(
              child: Column(
                children: [
                  // Multi-Image Scan Option
                  _buildOptionCard(
                    context,
                    title: 'Multi-Image Scan',
                    subtitle: 'Capture multiple photos for automatic medicine detection',
                    icon: Icons.photo_library_outlined,
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ImageCaptureScreenSimple(isMedicine: true)),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Camera Scan Option
                  _buildOptionCard(
                    context,
                    title: 'Camera Scan',
                    subtitle: 'Use camera to automatically extract medicine information',
                    icon: Icons.camera_alt,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicineScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Manual Entry Option
                  _buildOptionCard(
                    context,
                    title: 'Manual Entry',
                    subtitle: 'Manually enter medicine details',
                    icon: Icons.edit,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManualMedicineEntryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
