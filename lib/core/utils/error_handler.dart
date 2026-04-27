import 'package:flutter/material.dart';
import 'logger_service.dart';

/// Generic Error Handler Utility
/// Provides consistent error handling across the app with user-friendly messages
class ErrorHandler {
  /// Show a generic error snackbar
  static void showError(BuildContext context, String message, {String? details}) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: details != null
            ? SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  _showErrorDialog(context, message, details);
                },
              )
            : null,
      ),
    );
  }

  /// Show a warning snackbar
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show an error dialog with details
  static void _showErrorDialog(BuildContext context, String message, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Handle async operations with try-catch and error display
  static Future<T?> handleAsync<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      LoggerService.error('ERROR_HANDLER', 'Async operation failed: $e');
      LoggerService.error('ERROR_HANDLER', 'Stack trace: $stackTrace');
      
      if (showError && context.mounted) {
        showError(
          context,
          errorMessage ?? 'An error occurred. Please try again.',
          details: e.toString(),
        );
      }
      return null;
    }
  }

  /// Get user-friendly error message from exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';
    
    final errorString = error.toString();
    
    // Common error patterns
    if (errorString.contains('Network') || errorString.contains('Socket')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorString.contains('Timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorString.contains('Permission')) {
      return 'Permission denied. Please grant the required permissions.';
    }
    if (errorString.contains('NotFound') || errorString.contains('404')) {
      return 'Resource not found.';
    }
    if (errorString.contains('Unauthorized') || errorString.contains('401')) {
      return 'Authentication failed. Please log in again.';
    }
    
    return errorString;
  }
}
