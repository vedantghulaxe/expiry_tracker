import 'package:workmanager/workmanager.dart';
import 'logger_service.dart';

// ✅ Define the missing constant here
const String expiryCheckTask = "com.expiry.checkTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // This is where the background logic happens
    LoggerService.info('BACKGROUND_TASK', 'Running: $task');
    return Future.value(true);
  });
}