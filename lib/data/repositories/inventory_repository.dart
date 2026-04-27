import 'package:drift/drift.dart';
import '../database/app_database.dart';

class InventoryItem {

  final String name;
  final DateTime expiryDate;
  final int quantity;

  InventoryItem({
    required this.name,
    required this.expiryDate,
    required this.quantity,
  });
}

class InventoryRepository {

  final AppDatabase db;

  InventoryRepository(this.db);

  Future<void> addInventory(
      int productId,
      DateTime expiryDate,
      int quantity,
      ) async {

    await db.into(db.inventory).insert(
      InventoryCompanion.insert(
        productId: productId,
        expiryDate: expiryDate,
        quantity: Value(quantity),
      ),
    );
  }

  Future<List<InventoryItem>> getInventoryItems() async {

    final query = db.select(db.inventory).join([
      innerJoin(
        db.products,
        db.products.id.equalsExp(db.inventory.productId),
      ),
    ]);

    final rows = await query.get();

    return rows.map((row) {

      final product = row.readTable(db.products);
      final inventory = row.readTable(db.inventory);

      return InventoryItem(
        name: product.name,
        expiryDate: inventory.expiryDate,
        quantity: inventory.quantity,
      );

    }).toList();
  }
}