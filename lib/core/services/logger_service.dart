import 'package:flutter/foundation.dart';

class LoggerService {
  static void log(String step, String status, String detail) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final message = '[$timestamp] [$step] [$status] $detail';
    
    if (kDebugMode) {
      print(message);
    }
  }
  
  static void success(String step, String detail) => log(step, 'SUCCESS', detail);
  static void warning(String step, String detail) => log(step, 'WARNING', detail);
  static void error(String step, String detail) => log(step, 'ERROR', detail);
  static void info(String step, String detail) => log(step, 'INFO', detail);
  static void debug(String step, String detail) => log(step, 'DEBUG', detail);
  static void start(String step, String detail) => log(step, 'START', detail);
  static void complete(String step, String detail) => log(step, 'COMPLETE', detail);
}
