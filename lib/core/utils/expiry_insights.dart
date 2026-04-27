import 'package:flutter/material.dart';

/// Expiry Insights Utility
/// Provides intelligent expiry calculations and status
class ExpiryInsights {
  /// Normalize a DateTime to date-only (midnight local)
  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Calculate days remaining until expiry (date-only comparison)
  static int getDaysRemaining(DateTime? expiryDate) {
    if (expiryDate == null) return 9999; // Far in the future/Safe
    
    final today = _normalize(DateTime.now());
    final expiry = _normalize(expiryDate);
    
    return expiry.difference(today).inDays;
  }

  /// Get expiry status with color coding
  static ExpiryStatus getExpiryStatus(DateTime? expiryDate) {
    if (expiryDate == null) return ExpiryStatus.safe;
    
    final daysRemaining = getDaysRemaining(expiryDate);
    
    if (daysRemaining < 0) {
      return ExpiryStatus.expired;
    } else if (daysRemaining <= 7) {
      return ExpiryStatus.expiringSoon;
    } else {
      return ExpiryStatus.safe;
    }
  }

  /// Get color based on expiry status
  static Color getStatusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return Colors.red;
      case ExpiryStatus.expiringSoon:
        return Colors.orange;
      case ExpiryStatus.safe:
        return Colors.green;
    }
  }

  /// Format expiry date for display
  static String formatExpiryDate(DateTime? expiryDate) {
    if (expiryDate == null) return 'No expiry date';
    
    final daysRemaining = getDaysRemaining(expiryDate);
    if (daysRemaining < 0) {
      return 'Expired ${daysRemaining.abs()} days ago';
    } else if (daysRemaining == 0) {
      return 'Expires today';
    } else if (daysRemaining == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in $daysRemaining days';
    }
  }
}

/// Expiry Status Enum
enum ExpiryStatus {
  expired,
  expiringSoon,
  safe,
}
