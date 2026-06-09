import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';

/// Timeline Calendar Widget showing products expiring in different periods
class ExpiryTimelineWidget extends StatelessWidget {
  final List<Product> products;
  final Function(String period)? onPeriodTap;

  const ExpiryTimelineWidget({
    super.key,
    required this.products,
    this.onPeriodTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeline = _categorizeProducts();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Expiry Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Timeline Cards
          _buildTimelineCard(
            context,
            period: '1 Day',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            count: timeline['today']!,
            description: 'Expiring today or tomorrow',
            onTap: () => onPeriodTap?.call('today'),
          ),
          const SizedBox(height: 12),
          
          _buildTimelineCard(
            context,
            period: '1 Week',
            icon: Icons.event_note,
            color: Colors.orange,
            count: timeline['week']!,
            description: 'Expiring within 7 days',
            onTap: () => onPeriodTap?.call('week'),
          ),
          const SizedBox(height: 12),
          
          _buildTimelineCard(
            context,
            period: '1 Month',
            icon: Icons.calendar_today,
            color: Colors.amber,
            count: timeline['month']!,
            description: 'Expiring within 30 days',
            onTap: () => onPeriodTap?.call('month'),
          ),
          const SizedBox(height: 12),
          
          _buildTimelineCard(
            context,
            period: 'Later',
            icon: Icons.schedule,
            color: Colors.green,
            count: timeline['later']!,
            description: 'Expiring after 30 days',
            onTap: () => onPeriodTap?.call('later'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context, {
    required String period,
    required IconData icon,
    required Color color,
    required int count,
    required String description,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with colored background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Map<String, int> _categorizeProducts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final oneWeek = today.add(const Duration(days: 7));
    final oneMonth = today.add(const Duration(days: 30));

    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int laterCount = 0;

    for (final product in products) {
      if (product.expiryDate == null) continue;

      final expiryDate = DateTime(
        product.expiryDate!.year,
        product.expiryDate!.month,
        product.expiryDate!.day,
      );

      if (expiryDate.isBefore(tomorrow) || expiryDate.isAtSameMomentAs(tomorrow)) {
        todayCount++;
      } else if (expiryDate.isBefore(oneWeek)) {
        weekCount++;
      } else if (expiryDate.isBefore(oneMonth)) {
        monthCount++;
      } else {
        laterCount++;
      }
    }

    return {
      'today': todayCount,
      'week': weekCount,
      'month': monthCount,
      'later': laterCount,
    };
  }
}
