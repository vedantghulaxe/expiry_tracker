# 🚀 Expiry Tracker App - Quick Reference Guide

## 📱 Project Info
- **Name:** Expiry Tracker App
- **Version:** 1.0.0+8
- **Flutter SDK:** >=3.8.0 <4.0.0
- **Platforms:** Android, iOS, Web, Windows, macOS, Linux

---

## 🎯 Quick Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d macos           # macOS

# Hot reload
r                              # In running app

# Hot restart
R                              # In running app
```

### Build
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated

# Clean build
flutter clean
```

### Code Generation
```bash
# Generate Drift database code
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch

# Clean and rebuild
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📂 File Locations Quick Reference

### Entry Point
```
lib/main.dart                  # App starts here
```

### Core Services
```
lib/core/services/
├── ai_service.dart            # AI data extraction
├── barcode_service.dart       # Barcode scanning
├── database_service.dart      # Database management
├── biometric_service.dart     # Biometric auth
└── logger_service.dart        # Logging
```

### Main Screens
```
lib/features/
├── dashboard/dashboard_screen.dart           # Main dashboard
├── product/product_form_screen_new.dart      # Add product
├── medicine/medicine_screen.dart             # Add medicine
├── inventory/inventory_screen_new.dart       # View inventory
├── analytics/analytics_screen_new.dart       # Analytics
└── settings/settings_screen.dart             # Settings
```

### Database
```
lib/data/database/
├── app_database.dart          # Database config
└── tables/
    ├── products_table.dart    # Products schema
    └── medicines_table.dart   # Medicines schema
```

### Models
```
lib/models/
└── product_info.dart          # Main data model
```

---

## 🔧 Key Configuration Files

### Dependencies
```
pubspec.yaml                   # Add/remove packages here
```

### Linter Rules
```
analysis_options.yaml          # Code quality rules
```

### Git
```
.gitignore                     # Files to ignore
```

### Platform Configs
```
android/app/build.gradle.kts   # Android config
ios/Runner/Info.plist          # iOS config
```

---

## 🎨 Common Tasks

### Add New Screen
1. Create file in `lib/features/[feature_name]/`
2. Import in navigation file
3. Add route in `main_navigation_screen.dart`

### Add New Service
1. Create file in `lib/core/services/`
2. Initialize in `simple_service_manager.dart`
3. Use in screens via import

### Add New Model
1. Create file in `lib/models/`
2. Add JSON serialization annotations
3. Run `flutter pub run build_runner build`

### Add Database Table
1. Create table in `lib/data/database/tables/`
2. Add to `app_database.dart`
3. Run `flutter pub run build_runner build`
4. Create repository in `lib/data/repositories/`

---

## 🔌 API Keys Configuration

### Location
```
lib/core/services/config_service.dart
```

### Required Keys
- Oxlo.ai API Key (for AI OCR)
- Other API keys as needed

### Setup
```dart
class ConfigService {
  static const String oxloApiKey = 'YOUR_API_KEY_HERE';
  static const String oxloBaseUrl = 'https://api.oxlo.ai/v1';
  // Add more keys as needed
}
```

---

## 📊 Database Schema Quick Reference

### Products Table
```dart
id              INTEGER PRIMARY KEY
name            TEXT NOT NULL
brand           TEXT
category        TEXT
expiryDate      DATETIME
batchNumber     TEXT
imagePath       TEXT
isMedicine      BOOLEAN
createdAt       DATETIME
updatedAt       DATETIME
```

### Medicines Table
```dart
id              INTEGER PRIMARY KEY
name            TEXT NOT NULL
manufacturer    TEXT
dosage          TEXT
expiryDate      DATETIME
batchNumber     TEXT
mrp             TEXT
doctorName      TEXT
symptoms        TEXT
prescriptionImage TEXT
createdAt       DATETIME
updatedAt       DATETIME
```

---

## 🎯 Feature Flags

### Enable/Disable Features
```dart
// In respective service files
static bool isEnabled = true;  // Change to false to disable
```

### Common Toggles
- Biometric authentication: `BiometricService`
- Notifications: `NotificationService`
- Online OCR: `RobustOCRService`

---

## 🐛 Debugging Tips

### Enable Logging
```dart
// In logger_service.dart
static bool isDebugMode = true;  // Set to true for detailed logs
```

### Common Issues

#### 1. Build Errors
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. Database Issues
```bash
# Delete app data and reinstall
flutter clean
flutter run
```

#### 3. Plugin Issues
```bash
flutter pub cache repair
flutter pub get
```

#### 4. iOS Build Issues
```bash
cd ios
pod install
cd ..
flutter run
```

---

## 📱 Testing on Devices

### Android
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Install APK
flutter install
```

### iOS
```bash
# Open Xcode
open ios/Runner.xcworkspace

# Run from Xcode or
flutter run -d <device-id>
```

### Web
```bash
flutter run -d chrome
# or
flutter run -d web-server --web-port=8080
```

---

## 🔐 Security Checklist

- [ ] API keys not committed to Git
- [ ] Biometric authentication tested
- [ ] Database encryption enabled (if needed)
- [ ] HTTPS for all API calls
- [ ] Input validation on all forms
- [ ] Error messages don't expose sensitive data

---

## 📦 Release Checklist

### Pre-Release
- [ ] All tests passing
- [ ] No console errors
- [ ] Version number updated in `pubspec.yaml`
- [ ] Changelog updated
- [ ] Documentation updated
- [ ] API keys configured
- [ ] Icons and splash screens set

### Android Release
- [ ] Signing key configured
- [ ] ProGuard rules set
- [ ] App bundle built
- [ ] Tested on multiple devices
- [ ] Play Store listing ready

### iOS Release
- [ ] Certificates configured
- [ ] Provisioning profiles set
- [ ] Archive created
- [ ] Tested on multiple devices
- [ ] App Store listing ready

---

## 🎨 UI Customization

### Theme Colors
```dart
// lib/core/services/theme_service.dart
static const primaryColor = Color(0xFF075E54);  // Change here
```

### App Name
```
android/app/src/main/AndroidManifest.xml
ios/Runner/Info.plist
```

### App Icon
```
# Use flutter_launcher_icons package
flutter pub run flutter_launcher_icons:main
```

---

## 📚 Important Classes

### Services
| Class | Purpose | Location |
|-------|---------|----------|
| `AIService` | AI data extraction | `lib/core/services/ai_service.dart` |
| `BarcodeService` | Barcode scanning | `lib/core/services/barcode_service.dart` |
| `DatabaseService` | Database operations | `lib/core/services/database_service.dart` |
| `BiometricService` | Authentication | `lib/core/services/biometric_service.dart` |
| `LoggerService` | Logging | `lib/core/services/logger_service.dart` |

### Repositories
| Class | Purpose | Location |
|-------|---------|----------|
| `ProductRepository` | Product CRUD | `lib/data/repositories/product_repository.dart` |
| `MedicineRepository` | Medicine CRUD | `lib/data/repositories/medicine_repository.dart` |

### Screens
| Class | Purpose | Location |
|-------|---------|----------|
| `DashboardScreen` | Main dashboard | `lib/features/dashboard/dashboard_screen.dart` |
| `ProductFormScreenNew` | Add/edit product | `lib/features/product/product_form_screen_new.dart` |
| `InventoryScreenNew` | View inventory | `lib/features/inventory/inventory_screen_new.dart` |
| `AnalyticsScreenNew` | Analytics | `lib/features/analytics/analytics_screen_new.dart` |

---

## 🔄 Data Flow Diagrams

### Add Product Flow
```
User → Image Capture → OCR → AI Extraction → Preview → Save → Database
```

### Barcode Scan Flow
```
User → Scan → Barcode Service → API Lookup → Form Pre-fill → Save
```

### Authentication Flow
```
App Start → Check Auth → Biometric Prompt → Success → Dashboard
```

---

## 📞 Getting Help

### Documentation
1. Check `PROJECT_STRUCTURE.md` for complete structure
2. Check `API_DOCUMENTATION.md` for API details
3. Check `ARCHITECTURE.md` for architecture info
4. Check `FUNCTION_DOCUMENTATION.md` for function reference

### Common Resources
- Flutter Docs: https://flutter.dev/docs
- Dart Docs: https://dart.dev/guides
- Drift Docs: https://drift.simonbinder.eu/docs/
- ML Kit Docs: https://developers.google.com/ml-kit

### Troubleshooting
```bash
# Check Flutter installation
flutter doctor

# Check for issues
flutter analyze

# Verbose output
flutter run -v
```

---

## 🎯 Performance Tips

### Optimize Images
- Compress images before saving
- Use appropriate image formats
- Implement lazy loading

### Database Optimization
- Use indexes on frequently queried columns
- Batch operations when possible
- Close database connections properly

### Memory Management
- Dispose controllers in `dispose()`
- Clear image cache when not needed
- Use `const` constructors where possible

---

## 🚀 Deployment

### Android (Google Play)
1. Build app bundle: `flutter build appbundle --release`
2. Sign with release key
3. Upload to Play Console
4. Fill store listing
5. Submit for review

### iOS (App Store)
1. Build archive: `flutter build ios --release`
2. Open Xcode and archive
3. Upload to App Store Connect
4. Fill store listing
5. Submit for review

### Web
1. Build: `flutter build web --release`
2. Deploy to hosting (Firebase, Netlify, etc.)
3. Configure domain
4. Enable HTTPS

---

**Quick Reference Version:** 1.0  
**Last Updated:** 2024  
**For:** Expiry Tracker App v1.0.0+8
