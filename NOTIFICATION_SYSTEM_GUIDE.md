# Notification System Guide

## Overview
The Expiry Tracker app now has a **fully functional notification system** that alerts users about expiring products and medicines at strategic intervals.

---

## How Notifications Work

### Automatic Scheduling
When you add or edit a product/medicine with an expiry date, the app automatically schedules notifications at these intervals:

| Days Before Expiry | Notification Title | Priority | Time |
|-------------------|-------------------|----------|------|
| 30 days | "30 Days Until Expiry" | Low | 9:00 AM |
| 14 days | "2 Weeks Until Expiry" | Default | 9:00 AM |
| 7 days | "1 Week Until Expiry" | High | 9:00 AM |
| 3 days | "3 Days Until Expiry" | High | 9:00 AM |
| 1 day | "Expires Tomorrow!" | Max | 9:00 AM |
| 0 days (same day) | "Expires Today!" | Max | 9:00 AM |

### Notification Content
Each notification includes:
- **Title**: Time-based alert (e.g., "Expires Tomorrow!")
- **Body**: Product/medicine name, brand (if available), and days until expiry
- **Icon**: App icon
- **Color**: 
  - 🔴 Red for medicines
  - 🔵 Blue for products
- **Sound & Vibration**: Enabled for all notifications

### Example Notifications

#### Medicine Notification
```
Title: Expires Tomorrow!
Body: Crocin 500mg (GSK) will expire in 1 day
Color: Red
Priority: Max
```

#### Product Notification
```
Title: 1 Week Until Expiry
Body: Milk (Amul) will expire in 7 days
Color: Blue
Priority: High
```

---

## Notification Channels

The app uses two separate notification channels:

### 1. Medicine Expiry Alerts
- **Channel ID**: `medicine_expiry`
- **Name**: Medicine Expiry Alerts
- **Description**: Notifications for expiring medicines
- **Color**: Red (#FF5252)
- **Importance**: Varies by urgency

### 2. Product Expiry Alerts
- **Channel ID**: `product_expiry`
- **Name**: Product Expiry Alerts
- **Description**: Notifications for expiring products
- **Color**: Blue (#2196F3)
- **Importance**: Varies by urgency

---

## When Notifications Are Scheduled

### On Add
When you add a new product/medicine:
1. Form is filled and saved
2. System checks if expiry date exists
3. Calculates days until expiry
4. Schedules up to 6 notifications (only future dates)
5. Logs scheduled notifications in console

### On Edit
When you edit an existing product/medicine:
1. Old notifications are cancelled
2. New notifications are scheduled based on updated expiry date
3. Prevents duplicate notifications

### On Delete
When you delete a product/medicine:
- All associated notifications are automatically cancelled

---

## Notification Behavior

### Smart Scheduling
- Only schedules notifications for **future dates**
- If a product expires in 5 days, only schedules: 3-day, 1-day, and same-day notifications
- Skips past notification dates automatically

### Time of Day
- All notifications are scheduled for **9:00 AM** local time
- Ensures notifications arrive at a convenient time
- Can be customized in the code if needed

### Priority Levels
Notifications use Android's priority system:

| Priority | When Used | Behavior |
|----------|-----------|----------|
| **Max** | Same day, 1 day before | Full-screen alert, sound, vibration |
| **High** | 3 days, 7 days before | Heads-up notification, sound |
| **Default** | 14 days before | Standard notification |
| **Low** | 30 days before | Silent notification in tray |

---

## Permissions

### Android
- **Android 13+**: Requires explicit notification permission
- Permission is requested automatically on first launch
- Users can manage permissions in Settings → Apps → Expiry Tracker → Notifications

### iOS
- Requires permission for alerts, badges, and sounds
- Permission dialog appears on first notification attempt
- Users can manage in Settings → Notifications → Expiry Tracker

---

## Testing Notifications

### Method 1: Add Test Item
1. Add a product/medicine with expiry date = tomorrow
2. Check console logs for "NOTIFICATIONS SCHEDULED"
3. Wait until 9:00 AM next day
4. Notification should appear

### Method 2: Check Pending Notifications
```dart
// In your code:
final pending = await NotificationService().getPendingNotifications();
print('Pending notifications: ${pending.length}');
for (final notification in pending) {
  print('ID: ${notification.id}, Title: ${notification.title}');
}
```

### Method 3: Show Immediate Test Notification
```dart
// Add this to test notifications immediately:
await NotificationService().showNotification(
  title: 'Test Notification',
  body: 'This is a test notification',
  isMedicine: true,
);
```

---

## Console Logs

When notifications are scheduled, you'll see logs like:

```
=== SAVING ITEM DEBUG ===
Name: Crocin 500mg
Expiry: 2026-05-15
========================

=== NOTIFICATIONS SCHEDULED ===
Scheduled notifications for: Crocin 500mg

[NOTIFICATION] Scheduling notifications for Crocin 500mg
[NOTIFICATION] Expiry date: 2026-05-15 00:00:00.000
[NOTIFICATION] Days until expiry: 17
[NOTIFICATION] Scheduled: 2 Weeks Until Expiry for 2026-05-01 09:00:00.000
[NOTIFICATION] Scheduled: 1 Week Until Expiry for 2026-05-08 09:00:00.000
[NOTIFICATION] Scheduled: 3 Days Until Expiry for 2026-05-12 09:00:00.000
[NOTIFICATION] Scheduled: Expires Tomorrow! for 2026-05-14 09:00:00.000
[NOTIFICATION] Scheduled: Expires Today! for 2026-05-15 09:00:00.000
[NOTIFICATION] Scheduled 5 notifications for Crocin 500mg
```

---

## Notification Management

### View Pending Notifications
Users can see all scheduled notifications in:
- Android: Settings → Apps → Expiry Tracker → Notifications
- iOS: Settings → Notifications → Expiry Tracker

### Cancel Notifications
Notifications are automatically cancelled when:
- Item is deleted
- Item is edited (old notifications cancelled, new ones scheduled)
- User manually cancels in system settings

### Cancel All Notifications
```dart
await NotificationService().cancelAllNotifications();
```

---

## Customization Options

### Change Notification Time
Edit `_scheduleNotification()` in `notification_service.dart`:
```dart
final notificationTime = DateTime(
  scheduledDate.year,
  scheduledDate.month,
  scheduledDate.day,
  9, // Change this to desired hour (0-23)
  0, // Change this to desired minute (0-59)
);
```

### Add More Notification Intervals
Edit `scheduleExpiryNotifications()` in `notification_service.dart`:
```dart
final notificationSchedule = [
  {'days': 60, 'title': '2 Months Until Expiry', 'priority': 'low'},
  {'days': 30, 'title': '30 Days Until Expiry', 'priority': 'low'},
  // ... add more intervals
];
```

### Change Notification Sound
Add custom sound file to:
- Android: `android/app/src/main/res/raw/notification_sound.mp3`
- iOS: Add to Xcode project

Then update notification details:
```dart
final androidDetails = AndroidNotificationDetails(
  // ... other settings
  sound: RawResourceAndroidNotificationSound('notification_sound'),
);
```

---

## Troubleshooting

### Notifications Not Appearing

**Check 1: Permissions**
- Go to Settings → Apps → Expiry Tracker → Notifications
- Ensure notifications are enabled

**Check 2: Battery Optimization**
- Some devices kill background tasks
- Go to Settings → Battery → Battery Optimization
- Set Expiry Tracker to "Not optimized"

**Check 3: Do Not Disturb**
- Check if Do Not Disturb mode is enabled
- High priority notifications should still appear

**Check 4: Console Logs**
- Look for "NOTIFICATIONS SCHEDULED" in logs
- Check for any error messages

### Notifications Appearing at Wrong Time

**Solution**: Check device timezone settings
- Notifications use device's local timezone
- Ensure device time is set correctly

### Duplicate Notifications

**Solution**: This shouldn't happen as old notifications are cancelled on edit
- If it does, call `cancelAllNotifications()` and re-add items

---

## Technical Details

### Notification ID Generation
Each notification gets a unique ID:
```dart
ID = (itemId × 100) + daysBeforeExpiry
```

Example:
- Item ID: 5, 7 days before = ID 507
- Item ID: 5, 1 day before = ID 501

This ensures:
- Each item can have multiple notifications
- Notifications can be individually cancelled
- No ID conflicts between items

### Timezone Handling
- Uses `timezone` package for accurate scheduling
- Converts local DateTime to TZDateTime
- Handles daylight saving time automatically

### Platform Differences

| Feature | Android | iOS |
|---------|---------|-----|
| Scheduled Notifications | ✅ Full support | ✅ Full support |
| Custom Sounds | ✅ Supported | ✅ Supported |
| Priority Levels | ✅ 5 levels | ⚠️ Limited |
| Notification Channels | ✅ Supported | ❌ Not applicable |
| Exact Timing | ✅ exactAllowWhileIdle | ✅ Supported |

---

## Future Enhancements

Potential improvements:
1. **Custom notification times** - Let users choose when to receive notifications
2. **Snooze functionality** - Postpone notifications
3. **Notification history** - View past notifications
4. **Batch notifications** - Group multiple expiring items
5. **Weekly summary** - Summary of items expiring this week
6. **Custom sounds** - Different sounds for medicines vs products
7. **Notification actions** - Quick actions like "Mark as used" or "View details"

---

## Dependencies

Required packages in `pubspec.yaml`:
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.2
```

---

## Summary

✅ **Notifications are now fully functional**  
✅ **Automatic scheduling on add/edit**  
✅ **Smart interval-based alerts**  
✅ **Separate channels for medicines and products**  
✅ **Priority-based notification levels**  
✅ **Timezone-aware scheduling**  
✅ **Automatic cancellation on delete/edit**  

The notification system is production-ready and will help users stay on top of expiring items!
