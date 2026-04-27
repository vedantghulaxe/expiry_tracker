import 'package:flutter/material.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../core/services/database_service.dart';
import '../../models/product_info.dart';
import '../../core/services/logger_service.dart';
import '../medicine/medicine_entry_options_screen.dart';

class MedicineListScreen extends StatelessWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = MedicineRepository(DatabaseService().db);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductInfo>>(
        stream: repository.watchAllMedicines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final medicines = snapshot.data ?? [];
          
          if (medicines.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No medicines found', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: medicine.imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(medicine.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, 
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                      )
                    : const CircleAvatar(child: Icon(Icons.medication)),
                  title: Text(medicine.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (medicine.brand != null) Text(medicine.brand!),
                      const SizedBox(height: 4),
                      Text(
                        'Expires: ${medicine.expiryDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                        style: TextStyle(
                          color: _getExpiryColor(medicine.expiryDate),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Details
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        label: const Text('Add Medicine'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const MedicineEntryOptionsScreen(),
    );
  }

  Color _getExpiryColor(DateTime? expiryDate) {
    if (expiryDate == null) return Colors.grey;
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < 0) return Colors.red;
    if (difference <= 7) return Colors.orange;
    return Colors.green;
  }
}
