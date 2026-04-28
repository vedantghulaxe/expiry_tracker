# 📊 Analytics Screen - Location & Usage Guide

## 📍 Where is the Analytics Screen Located?

The **Analytics Screen** (`analytics_screen_new.dart`) is accessible from **2 main locations** in the app:

---

## 🎯 Location 1: Bottom Navigation Bar (Main Access)

### File: `lib/features/navigation/main_navigation_screen.dart`

The Analytics screen is the **3rd tab** in the bottom navigation bar.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│              MAIN NAVIGATION SCREEN                     │
│                                                         │
│                    [Content Area]                       │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│  [🛍️ Products]  [💊 Medicines]  [📊 Analytics] ← HERE  │
│      Tab 1          Tab 2           Tab 3              │
└─────────────────────────────────────────────────────────┘
```

### How to Access:
1. Open the app
2. Look at the **bottom navigation bar**
3. Tap on the **"Analytics"** tab (3rd icon from left)
4. Icon: 📊 `Icons.analytics_outlined`

### Code:
```dart
// lib/features/navigation/main_navigation_screen.dart

static final List<Widget> _pages = [
  const ProductListScreen(),      // Tab 1
  const MedicineListScreen(),     // Tab 2
  const AnalyticsScreenNew(),     // Tab 3 ← Analytics here!
];

BottomNavigationBarItem(
  icon: Icon(Icons.analytics_outlined),
  activeIcon: Icon(Icons.analytics),
  label: 'Analytics',  // ← This is what you see
),
```

---

## 🎯 Location 2: Home Screen Quick Action

### File: `lib/features/home/home_screen_clean.dart`

The Analytics screen is also accessible via a **quick action button** on the home screen.

```
┌─────────────────────────────────────────────────────────┐
│                  HOME SCREEN                            │
│                                                         │
│  ┌─────────────────────┐  ┌─────────────────────┐     │
│  │                     │  │                     │     │
│  │  View Inventory     │  │  View Analytics     │ ← HERE
│  │  📦                 │  │  📊                 │     │
│  │                     │  │                     │     │
│  └─────────────────────┘  └─────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### How to Access:
1. Open the app
2. Navigate to **Home Screen** (if not already there)
3. Look for the **"View Analytics"** button
4. Tap on it to open Analytics screen

### Code:
```dart
// lib/features/home/home_screen_clean.dart

_buildQuickActionTile(
  context,
  'View Analytics',              // ← Button label
  Icons.analytics_outlined,      // ← Icon
  () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AnalyticsScreenNew(),  // ← Opens this
    ),
  ),
),
```

---

## 📱 Complete UI Navigation Flow

### Method 1: Bottom Navigation (Persistent)
```
App Start
    ↓
Dashboard/Home Screen
    ↓
[Tap Bottom Nav: Analytics Tab]
    ↓
Analytics Screen ✅
```

### Method 2: Quick Action Button
```
App Start
    ↓
Home Screen
    ↓
[Tap "View Analytics" Button]
    ↓
Analytics Screen ✅
```

---

## 🎨 What Does the Analytics Screen Show?

### Screen Layout:
```
┌─────────────────────────────────────────────────────────┐
│  ← Analytics                                    🔄      │  ← App Bar
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐                   │
│  │ Total Items  │  │   Expired    │                   │  ← Stats Cards
│  │     42       │  │      5       │                   │
│  └──────────────┘  └──────────────┘                   │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐                   │
│  │Expiring Soon │  │ Safe Items   │                   │
│  │     12       │  │     25       │                   │
│  └──────────────┘  └──────────────┘                   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │        Category Distribution                    │  │  ← Chart 1
│  │                                                 │  │
│  │  [Medicines]  [Products]                       │  │
│  │      ▓▓▓          ▓▓▓▓▓                        │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │           Status Overview                       │  │  ← Chart 2
│  │                                                 │  │
│  │  [Safe]  [Expiring Soon]  [Expired]           │  │
│  │   ▓▓▓▓       ▓▓▓              ▓               │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Features Displayed:

1. **Statistics Cards** (Top Section)
   - Total Items count
   - Expired items count
   - Expiring Soon count
   - Safe items count

2. **Category Distribution Chart** (Middle)
   - Bar chart showing Medicines vs Products
   - Visual comparison of categories

3. **Status Overview Chart** (Bottom)
   - Bar chart showing Safe, Expiring Soon, Expired
   - Color-coded status visualization

4. **Pull to Refresh**
   - Swipe down to refresh data

---

## 🔍 File Location

```
📦 expiry_tracker_app/
└── 📂 lib/
    └── 📂 features/
        └── 📂 analytics/
            └── 📄 analytics_screen_new.dart  ← Analytics Screen
```

**Full Path:** `lib/features/analytics/analytics_screen_new.dart`

---

## 🎯 Usage in Code

### Where it's imported:

1. **Main Navigation** (Primary)
   ```dart
   // lib/features/navigation/main_navigation_screen.dart
   import '../analytics/analytics_screen_new.dart';
   ```

2. **Home Screen** (Secondary)
   ```dart
   // lib/features/home/home_screen_clean.dart
   import '../analytics/analytics_screen_new.dart';
   ```

### How it's instantiated:

```dart
// As a tab in bottom navigation
const AnalyticsScreenNew()

// As a pushed route
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AnalyticsScreenNew(),
  ),
)
```

---

## 📊 Data Source

The Analytics screen gets its data from:

```dart
// lib/features/analytics/analytics_screen_new.dart

Future<void> _loadAnalytics() async {
  final db = DatabaseService().db;
  
  // Get all medicines
  final medicines = await MedicineRepository(db).getAllMedicines();
  
  // Get all products
  final products = await ProductRepository(db).getAllProducts();
  
  // Combine and calculate statistics
  final allItems = [...medicines, ...products];
  
  // Calculate expiry status using ExpiryInsights
  _expiredItems = allItems.where((item) => 
    ExpiryInsights.getExpiryStatus(item.expiryDate) == ExpiryStatus.expired
  ).length;
  
  _expiringSoonItems = allItems.where((item) => 
    ExpiryInsights.getExpiryStatus(item.expiryDate) == ExpiryStatus.expiringSoon
  ).length;
}
```

**Data comes from:**
- `MedicineRepository` - All medicines in database
- `ProductRepository` - All products in database
- `ExpiryInsights` - Expiry status calculations

---

## 🎨 Visual Appearance

### Colors Used:

| Element | Color | Purpose |
|---------|-------|---------|
| Total Items | Blue | General info |
| Expired | Red | Alert/danger |
| Expiring Soon | Orange | Warning |
| Safe Items | Green | Success/safe |
| Medicines | Red | Category 1 |
| Products | Blue | Category 2 |

### Icons Used:

- App Bar: `Icons.analytics_outlined`
- Navigation: `Icons.analytics` (active)
- Refresh: Pull-to-refresh gesture

---

## 🔄 User Interactions

### Available Actions:

1. **Pull to Refresh**
   - Swipe down from top
   - Reloads all statistics
   - Updates charts

2. **View Data**
   - Read-only display
   - No edit functionality
   - Real-time calculations

3. **Navigate Back**
   - Use back button (if pushed route)
   - Use bottom nav (if in tab)

---

## 🚀 Quick Access Summary

### To Open Analytics Screen:

**Option 1: Bottom Navigation (Recommended)**
```
1. Open app
2. Tap "Analytics" tab at bottom (3rd icon)
3. ✅ Analytics screen opens
```

**Option 2: Home Screen Button**
```
1. Open app
2. Go to Home screen
3. Tap "View Analytics" button
4. ✅ Analytics screen opens
```

---

## 📱 Screen Hierarchy

```
Main App
├── Dashboard Screen (Entry point)
│   └── Bottom Navigation
│       ├── Products Tab
│       ├── Medicines Tab
│       └── Analytics Tab ← Analytics Screen HERE
│
└── Home Screen (Alternative entry)
    └── Quick Actions
        └── View Analytics Button ← Analytics Screen HERE
```

---

## 🎯 Key Points

✅ **Primary Access:** Bottom Navigation Bar (3rd tab)  
✅ **Secondary Access:** Home Screen quick action button  
✅ **Icon:** 📊 Analytics icon  
✅ **Label:** "Analytics"  
✅ **File:** `lib/features/analytics/analytics_screen_new.dart`  
✅ **Purpose:** Display statistics and charts for all items  
✅ **Data:** Real-time from local database  

---

## 🔍 Testing the Analytics Screen

### To test if it's working:

1. **Add some products/medicines** to the database
2. **Navigate to Analytics** (using either method above)
3. **Verify you see:**
   - Total items count
   - Statistics cards
   - Category distribution chart
   - Status overview chart
4. **Pull down to refresh** - data should update

---

**File Location:** `lib/features/analytics/analytics_screen_new.dart`  
**Accessible From:** Bottom Navigation (Tab 3) + Home Screen (Quick Action)  
**Last Updated:** 2024
