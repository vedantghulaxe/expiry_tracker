import '../../core/services/database_service.dart';

class DashboardStats {

  final db = DatabaseService().db;

  Future<int> totalProducts() async {

    final products = await db.select(db.inventory).get();

    return products.length;
  }

  Future<int> expiredProducts() async {

    final items = await db.select(db.inventory).get();

    final today = DateTime.now();

    int count = 0;

    for (var item in items) {

      if (item.expiryDate.isBefore(today)) {
        count++;
      }

    }

    return count;
  }

  Future<int> expiringSoon() async {

    final items = await db.select(db.inventory).get();

    final today = DateTime.now();

    int count = 0;

    for (var item in items) {

      final days =
          item.expiryDate.difference(today).inDays;

      if (days <= 7 && days >= 0) {
        count++;
      }

    }

    return count;
  }

  Future<int> totalMedicines() async {

    final meds = await db.select(db.medicines).get();

    return meds.length;
  }
}