import 'package:flutter/material.dart';
import '../inventory/add_inventory_screen.dart';
import '../../core/services/database_service.dart';
import '../../data/repositories/product_repository.dart';
import '../../models/product_info.dart';

class AddProductScreen extends StatefulWidget {


  final String barcode;
  final String? productName;

  const AddProductScreen({
    super.key,
    required this.barcode,
    this.productName,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  final TextEditingController nameController = TextEditingController();

  late ProductRepository repository;

  @override
  void initState() {
    super.initState();

    repository = ProductRepository(DatabaseService().db);
    if (widget.productName != null) {
      nameController.text = widget.productName!;
    }
  }

  void saveProduct() async {
    await repository.addProduct(
      ProductInfo(
        name: nameController.text,
        barcode: widget.barcode,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddInventoryScreen(productId: 0),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Add Product"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Product Name",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveProduct,
              child: const Text("Save Product"),
            ),

          ],
        ),
      ),
    );
  }
}