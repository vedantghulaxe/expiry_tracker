import 'package:flutter/material.dart';

/// UI Helper utilities for consistent styling and expiry status
class UIHelpers {
  
  /// Get expiry status color based on date
  static Color getExpiryColor(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    if (difference.isNegative) {
      // Expired
      return Colors.red;
    } else if (difference.inDays <= 7) {
      // Expiring within 7 days
      return Colors.orange;
    } else {
      // Safe
      return Colors.green;
    }
  }
  
  /// Get expiry status text
  static String getExpiryStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays <= 7) {
      return 'Expiring Soon';
    } else {
      return 'Safe';
    }
  }
  
  /// Get expiry status icon
  static IconData getExpiryIcon(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    if (difference.isNegative) {
      return Icons.error;
    } else if (difference.inDays <= 7) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }
  
  /// Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medicine':
        return Icons.medication;
      case 'product':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }
  
  /// Format date for display
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Get days until expiry
  static String getDaysUntilExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    if (difference.isNegative) {
      return '${difference.inDays.abs()} days ago';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays} days';
    } else {
      return '${difference.inDays} days';
    }
  }
  
  /// Create consistent card with expiry indicator
  static Widget createExpiryCard({
    required Widget child,
    required DateTime expiryDate,
    required BuildContext context,
  }) {
    final color = getExpiryColor(expiryDate);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Colored side indicator
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          // Card content
          Expanded(child: child),
        ],
      ),
    );
  }
}
