import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/inventory_repository.dart';

class ExpiryChecker {

  final repo = InventoryRepository(DatabaseService().db);

  Future<void> checkExpiry() async {

    final items = await repo.getInventoryItems();

    final today = DateTime.now();

    for (var item in items) {

      final daysLeft =
          item.expiryDate.difference(today).inDays;

      if (daysLeft <= 3) {

        NotificationService().showNotification(
          "Expiry Alert",
          "${item.name} expires in $daysLeft days",
        );
      }
    }
  }
}