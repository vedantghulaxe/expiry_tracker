# Notification Examples - Visual Guide

## How Notifications Will Appear

### 📱 Medicine Notifications (Red Theme)

#### 30 Days Before Expiry
```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ 30 Days Until Expiry                │
│ Crocin 500mg (GSK) will expire in   │
│ 30 days                             │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Low (Silent in notification tray)
```

#### 2 Weeks Before Expiry
```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ 2 Weeks Until Expiry                │
│ Dolo 650 (Micro Labs) will expire   │
│ in 14 days                          │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Default (Standard notification with sound)
```

#### 1 Week Before Expiry
```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ 1 Week Until Expiry                 │
│ Azithral 500 (Alembic) will expire  │
│ in 7 days                           │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: High (Heads-up notification, sound, vibration)
```

#### 3 Days Before Expiry
```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ 3 Days Until Expiry                 │
│ Combiflam (Sanofi) will expire in   │
│ 3 days                              │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: High (Heads-up notification, sound, vibration)
```

#### Expires Tomorrow
```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ ⚠️ Expires Tomorrow!                │
│ Augmentin 625 (GSK) will expire in  │
│ 1 day                               │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Max (Full-screen alert, loud sound, vibration)
```

#### Expires Today
```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ 🚨 Expires Today!                   │
│ Allegra 120mg (Sanofi) expires      │
│ today                               │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Max (Full-screen alert, loud sound, vibration)
```

---

### 📱 Product Notifications (Blue Theme)

#### 30 Days Before Expiry
```
┌─────────────────────────────────────┐
│ 🔵 Expiry Tracker                   │
│ 30 Days Until Expiry                │
│ Olive Oil (Figaro) will expire in   │
│ 30 days                             │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Low (Silent in notification tray)
```

#### 2 Weeks Before Expiry
```
┌─────────────────────────────────────┐
│ 🔵 Expiry Tracker                   │
│ 2 Weeks Until Expiry                │
│ Milk (Amul) will expire in 14 days  │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Default (Standard notification with sound)
```

#### 1 Week Before Expiry
```
┌─────────────────────────────────────┐
│ 🔵 Expiry Tracker                   │
│ 1 Week Until Expiry                 │
│ Bread (Britannia) will expire in    │
│ 7 days                              │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: High (Heads-up notification, sound, vibration)
```

#### 3 Days Before Expiry
```
┌─────────────────────────────────────┐
│ 🔵 Expiry Tracker                   │
│ 3 Days Until Expiry                 │
│ Yogurt (Nestle) will expire in      │
│ 3 days                              │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: High (Heads-up notification, sound, vibration)
```

#### Expires Tomorrow
```
┌─────────────────────────────────────┐
│ 🔵 Expiry Tracker                   │
│ ⚠️ Expires Tomorrow!                │
│ Cheese (Amul) will expire in 1 day  │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Max (Full-screen alert, loud sound, vibration)
```

#### Expires Today
```
┌─────────────────────────────────────┐
│ 🔵 Expiry Tracker                   │
│ 🚨 Expires Today!                   │
│ Juice (Real) expires today          │
│                                     │
│ 9:00 AM                             │
└─────────────────────────────────────┘
Priority: Max (Full-screen alert, loud sound, vibration)
```

---

## Notification Behavior by Priority

### 🔴 Max Priority (Same Day, 1 Day Before)
**Android:**
- Full-screen notification (if screen is off)
- Heads-up notification (if screen is on)
- Loud notification sound
- Strong vibration
- Stays at top of notification shade

**iOS:**
- Banner notification
- Sound and vibration
- Badge on app icon
- Appears even in Do Not Disturb (if configured)

**User Experience:**
- Impossible to miss
- Requires immediate attention
- Critical for medicines expiring soon

---

### 🟠 High Priority (3 Days, 7 Days Before)
**Android:**
- Heads-up notification (peeking from top)
- Notification sound
- Vibration
- Prominent in notification shade

**iOS:**
- Banner notification
- Sound and vibration
- Badge on app icon

**User Experience:**
- Gets user's attention
- Important but not critical
- Good for planning ahead

---

### 🟡 Default Priority (14 Days Before)
**Android:**
- Standard notification in shade
- Notification sound
- Light vibration

**iOS:**
- Banner notification
- Sound
- Badge on app icon

**User Experience:**
- Normal notification
- User can check when convenient
- Good for advance planning

---

### 🟢 Low Priority (30 Days Before)
**Android:**
- Silent notification in shade
- No sound or vibration
- Collapsed by default

**iOS:**
- Silent notification
- Badge on app icon only

**User Experience:**
- Informational only
- Doesn't interrupt user
- Good for early awareness

---

## Notification Grouping (Android)

When multiple items expire on the same day:

```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ 3 medicines expiring soon           │
│                                     │
│ ▼ Tap to expand                     │
└─────────────────────────────────────┘

Expanded:
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ 3 medicines expiring soon           │
│                                     │
│ • Crocin 500mg expires tomorrow     │
│ • Dolo 650 expires tomorrow         │
│ • Combiflam expires tomorrow        │
└─────────────────────────────────────┘
```

---

## Notification Actions (Future Enhancement)

Potential quick actions:

```
┌─────────────────────────────────────┐
│ 🔴 Expiry Tracker                   │
│ Expires Tomorrow!                   │
│ Crocin 500mg (GSK) will expire in   │
│ 1 day                               │
│                                     │
│ [View Details] [Mark as Used]       │
└─────────────────────────────────────┘
```

---

## Notification Settings

Users can customize in system settings:

### Android
**Settings → Apps → Expiry Tracker → Notifications**

```
Medicine Expiry Alerts          [ON]
├─ Sound                        [Default]
├─ Vibration                    [ON]
├─ Show on lock screen          [ON]
└─ Override Do Not Disturb      [OFF]

Product Expiry Alerts           [ON]
├─ Sound                        [Default]
├─ Vibration                    [ON]
├─ Show on lock screen          [ON]
└─ Override Do Not Disturb      [OFF]
```

### iOS
**Settings → Notifications → Expiry Tracker**

```
Allow Notifications             [ON]
├─ Lock Screen                  [ON]
├─ Notification Center          [ON]
├─ Banners                      [ON]
├─ Sounds                       [ON]
└─ Badges                       [ON]

Banner Style: Temporary
Show Previews: Always
```

---

## Testing Notifications

### Quick Test (Immediate Notification)
Add this code temporarily to test:

```dart
// In any screen, add a button:
ElevatedButton(
  onPressed: () async {
    await NotificationService().showNotification(
      title: 'Test Notification',
      body: 'This is a test notification',
      isMedicine: true,
    );
  },
  child: Text('Test Notification'),
)
```

Result: Notification appears immediately

### Real Test (Scheduled Notification)
1. Add medicine with expiry = tomorrow
2. Check console: "Scheduled 5 notifications"
3. Wait until 9:00 AM tomorrow
4. Notification appears: "Expires Today!"

---

## Troubleshooting

### "Notifications not appearing"

**Check 1: Permissions**
```
Settings → Apps → Expiry Tracker → Permissions
✅ Notifications: Allowed
```

**Check 2: Battery Optimization**
```
Settings → Battery → Battery Optimization
✅ Expiry Tracker: Not optimized
```

**Check 3: Do Not Disturb**
```
Settings → Sound → Do Not Disturb
⚠️ If enabled, only Max priority notifications appear
```

**Check 4: Notification Channels**
```
Settings → Apps → Expiry Tracker → Notifications
✅ Medicine Expiry Alerts: ON
✅ Product Expiry Alerts: ON
```

---

## Summary

✅ **6 notification intervals** for comprehensive coverage  
✅ **Priority-based alerts** ensure urgent items get attention  
✅ **Separate channels** for medicines (red) and products (blue)  
✅ **Smart scheduling** only for future dates  
✅ **Consistent timing** at 9:00 AM daily  
✅ **Rich content** with item name, brand, and days until expiry  
✅ **Sound & vibration** for important alerts  
✅ **User control** via system settings  

The notification system is designed to be **helpful without being annoying**, with smart priority levels that escalate as expiry dates approach.
