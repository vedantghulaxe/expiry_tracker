import 'package:flutter/material.dart';

import '../../core/services/database_service.dart';
import '../../data/repositories/inventory_repository.dart';

class AddInventoryScreen extends StatefulWidget {

  final int productId;

  const AddInventoryScreen({super.key, required this.productId});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {

  DateTime? expiryDate;

  final quantityController = TextEditingController();

  late InventoryRepository repository;

  @override
  void initState() {
    super.initState();

    repository = InventoryRepository(DatabaseService().db);
  }

  Future<void> pickDate() async {

    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        expiryDate = picked;
      });
    }
  }

  Future<void> saveInventory() async {

    if (expiryDate == null) return;

    await repository.addInventory(
      widget.productId,
      expiryDate!,
      int.parse(quantityController.text),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Add Expiry Date"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: "Quantity",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickDate,
              child: const Text("Select Expiry Date"),
            ),

            const SizedBox(height: 20),

            Text(
              expiryDate == null
                  ? "No date selected"
                  : expiryDate.toString(),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveInventory,
              child: const Text("Save Inventory"),
            ),

          ],
        ),
      ),
    );
  }
}