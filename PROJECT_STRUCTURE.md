# 📱 Expiry Tracker App - Complete Project Structure

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Project Architecture](#project-architecture)
4. [Directory Structure](#directory-structure)
5. [Core Components](#core-components)
6. [Features](#features)
7. [Data Layer](#data-layer)
8. [Services](#services)
9. [Platform Support](#platform-support)

---

## 🎯 Project Overview

**Name:** Expiry Tracker App  
**Version:** 1.0.0+8  
**Description:** AI-powered product and medicine expiry management system  
**Platform:** Flutter (Cross-platform)

### Key Features
- ✅ AI-powered OCR for automatic data extraction
- ✅ Barcode scanning with multiple API integrations
- ✅ Product and medicine tracking
- ✅ Local SQLite database with Drift ORM
- ✅ Biometric authentication
- ✅ Expiry notifications
- ✅ Analytics dashboard
- ✅ Multi-image processing
- ✅ Offline-first architecture

---

## 🛠 Technology Stack

### Frontend
- **Framework:** Flutter 3.x
- **Language:** Dart 3.8.0+
- **State Management:** flutter_bloc (BLoC pattern)
- **UI:** Material Design 3

### Database
- **ORM:** Drift 2.20.0
- **Engine:** SQLite3
- **Local Storage:** sqflite 2.3.3

### OCR & ML
- **Google ML Kit:** Text recognition & barcode scanning
- **Tesseract OCR:** Offline text extraction (fallback)
- **Mobile Scanner:** Real-time barcode detection

### APIs & Integrations
- **HTTP Client:** http 1.1.0
- **Image Processing:** image 4.1.3
- **Image Picker:** image_picker 1.0.7
- **Network Image Cache:** cached_network_image 3.2.0

### Security
- **Biometric Auth:** local_auth 2.1.8
- **Secure Storage:** shared_preferences 2.2.3

### Utilities
- **Date/Time:** intl 0.18.1
- **File Paths:** path_provider 2.1.2
- **Connectivity:** connectivity_plus 4.0.0
- **Notifications:** flutter_local_notifications 17.0.0
- **Background Tasks:** workmanager 0.9.0
- **CSV Export:** csv 6.0.0
- **Excel Export:** excel 4.0.1

---

## 🏗 Project Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Screens    │  │   Widgets    │  │  Navigation  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     BUSINESS LOGIC                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  BLoC/State  │  │   Services   │  │   Utilities  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                       DATA LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Repositories │  │   Database   │  │    Models    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  OCR APIs    │  │ Barcode APIs │  │  ML Models   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Directory Structure

### Root Level
```
expiry_tracker_app/
├── android/                    # Android platform code
├── ios/                        # iOS platform code
├── linux/                      # Linux platform code
├── macos/                      # macOS platform code
├── windows/                    # Windows platform code
├── web/                        # Web platform code
├── lib/                        # Main Flutter application code
├── test/                       # Unit and widget tests
├── assets/                     # Static assets (images, data files)
├── build/                      # Build output (generated)
├── .dart_tool/                 # Dart tooling cache
├── .git/                       # Git version control
├── pubspec.yaml                # Project dependencies
├── analysis_options.yaml       # Linter configuration
├── .gitignore                  # Git ignore rules
├── .metadata                   # Flutter metadata
├── API_DOCUMENTATION.md        # API documentation
├── ARCHITECTURE.md             # Architecture documentation
├── BIOMETRIC_AUTHENTICATION.md # Biometric auth guide
├── FILE_DOCUMENTATION.md       # File structure docs
└── FUNCTION_DOCUMENTATION.md   # Function reference
```

### Main Application Structure (lib/)
```
lib/
├── main.dart                   # Application entry point
├── core/                       # Core business logic
│   ├── services/              # Business services
│   └── utils/                 # Utility functions
├── data/                       # Data layer
│   ├── database/              # Database configuration
│   └── repositories/          # Data repositories
├── features/                   # Feature modules
│   ├── analytics/             # Analytics & statistics
│   ├── auth/                  # Authentication
│   ├── common/                # Shared components
│   ├── dashboard/             # Main dashboard
│   ├── expiry_timeline/       # Expiry timeline view
│   ├── home/                  # Home screen
│   ├── inventory/             # Inventory management
│   ├── medicine/              # Medicine tracking
│   ├── navigation/            # App navigation
│   ├── product/               # Product tracking
│   ├── security/              # Security features
│   └── settings/              # App settings
├── models/                     # Data models
└── services/                   # External services
```

---

## 🔧 Core Components

### 1. Main Entry Point
**File:** `lib/main.dart`
- Initializes Flutter app
- Sets up theme (light/dark mode)
- Configures authentication wrapper
- Handles app lifecycle

### 2. Core Services (`lib/core/services/`)

#### AI & OCR Services
| File | Purpose |
|------|---------|
| `ai_service.dart` | AI-powered data extraction using Oxlo.ai |
| `ai_extraction_service.dart` | Structured data extraction from OCR text |
| `robust_ocr_service.dart` | Multi-stage OCR pipeline (online/offline) |
| `simple_ocr_service.dart` | Simplified OCR interface |
| `local_parser_service.dart` | Regex-based text parsing |

#### Barcode Services
| File | Purpose |
|------|---------|
| `barcode_service.dart` | Barcode scanning and product lookup |
| `barcode_api_service.dart` | External barcode API integration |
| `product_api_service.dart` | Product information APIs (Open Food Facts, FDA) |

#### Database & Storage
| File | Purpose |
|------|---------|
| `database_service.dart` | Database initialization and management |
| `config_service.dart` | App configuration and API keys |

#### Security & Authentication
| File | Purpose |
|------|---------|
| `biometric_service.dart` | Biometric authentication (fingerprint, face ID) |

#### Utilities
| File | Purpose |
|------|---------|
| `logger_service.dart` | Application logging |
| `theme_service.dart` | Theme management (light/dark mode) |
| `notification_service.dart` | Push notifications |
| `connectivity_service.dart` | Network connectivity checks |
| `image_validation_service.dart` | Image quality validation |
| `image_enhancement_service.dart` | Image preprocessing |
| `simple_service_manager.dart` | Service initialization manager |

### 3. Core Utils (`lib/core/utils/`)
| File | Purpose |
|------|---------|
| `expiry_insights.dart` | Expiry date calculations and status |
| `ui_helpers.dart` | UI utility functions |

---

## 🎨 Features

### 1. Analytics (`lib/features/analytics/`)
```
analytics/
└── analytics_screen_new.dart   # Statistics and charts dashboard
```
**Features:**
- Total items count
- Expired items tracking
- Expiring soon alerts
- Category distribution charts
- Status overview

### 2. Authentication (`lib/features/auth/`)
```
auth/
└── lock_screen.dart            # Biometric lock screen
```
**Features:**
- Biometric authentication
- Password fallback
- Session timeout
- Re-authentication on app resume

### 3. Common Components (`lib/features/common/`)
```
common/
├── barcode_scanner_screen.dart         # Barcode scanning interface
├── image_capture_screen_real_ocr.dart  # Image capture with OCR
└── image_capture_screen_simple.dart    # Simple image capture
```
**Features:**
- Camera/gallery image selection
- Real-time barcode scanning
- Multi-image capture
- OCR processing

### 4. Dashboard (`lib/features/dashboard/`)
```
dashboard/
├── dashboard_screen.dart       # Main dashboard
└── expiry_summary_widget.dart  # Expiry summary cards
```
**Features:**
- Product overview
- Quick actions
- Expiry status indicators
- Search and filter
- Navigation hub

### 5. Expiry Timeline (`lib/features/expiry_timeline/`)
```
expiry_timeline/
└── expiry_timeline_screen.dart # Timeline view of expiring items
```
**Features:**
- Chronological expiry view
- Color-coded status
- Grouped by date
- Quick actions

### 6. Home (`lib/features/home/`)
```
home/
└── home_screen_clean.dart      # WhatsApp-style home screen
```
**Features:**
- Clean modern UI
- Quick add buttons
- Category shortcuts
- Navigation cards

### 7. Inventory (`lib/features/inventory/`)
```
inventory/
├── enhanced_inventory_screen.dart  # Enhanced inventory view
└── inventory_screen_new.dart       # Main inventory screen
```
**Features:**
- List all products/medicines
- Search and filter
- Sort by expiry date
- Edit/delete items
- Expiry color coding

### 8. Medicine (`lib/features/medicine/`)
```
medicine/
├── manual_medicine_entry_screen.dart   # Manual medicine entry
├── medicine_entry_method_screen.dart   # Entry method selection
├── medicine_entry_options_screen.dart  # Entry options
├── medicine_list_screen.dart           # Medicine list
├── medicine_screen.dart                # Medicine processing
└── preview_screen.dart                 # Preview before saving
```
**Features:**
- Medicine-specific fields (dosage, doctor, symptoms)
- Prescription image upload
- AI-powered data extraction
- Medicine database lookup
- Preview and edit before saving

### 9. Navigation (`lib/features/navigation/`)
```
navigation/
└── main_navigation_screen.dart # Bottom navigation bar
```
**Features:**
- Tab-based navigation
- Products, Medicines, Analytics tabs
- Persistent navigation state

### 10. Product (`lib/features/product/`)
```
product/
├── manual_product_entry_screen.dart    # Manual product entry
├── product_entry_method_screen.dart    # Entry method selection
├── product_entry_options_screen.dart   # Entry options
├── product_form_screen_new.dart        # Product form
├── product_list_screen.dart            # Product list
└── product_scanner_screen.dart         # Product scanner
```
**Features:**
- Product-specific fields
- Barcode scanning
- Image capture
- AI data extraction
- Category classification

### 11. Security (`lib/features/security/`)
```
security/
└── biometric_check_screen.dart # Biometric security check
```
**Features:**
- Biometric status check
- Security settings
- Authentication testing
- Device capability check

### 12. Settings (`lib/features/settings/`)
```
settings/
└── settings_screen.dart        # App settings
```
**Features:**
- Theme toggle (light/dark)
- Biometric authentication toggle
- Notification settings
- About app
- Clear data

---

## 💾 Data Layer

### Database (`lib/data/database/`)
```
database/
├── app_database.dart           # Main database configuration
├── app_database.g.dart         # Generated database code
├── database_service.dart       # Database service
└── tables/
    ├── inventory_table.dart    # Inventory table schema
    ├── medicines_table.dart    # Medicines table schema
    └── products_table.dart     # Products table schema
```

#### Database Schema

**Products Table:**
```dart
- id: INTEGER (Primary Key)
- name: TEXT
- brand: TEXT
- category: TEXT
- expiryDate: DATETIME
- manufacturingDate: DATETIME
- batchNumber: TEXT
- ingredients: TEXT
- notes: TEXT
- imagePath: TEXT
- isMedicine: BOOLEAN
- createdAt: DATETIME
- updatedAt: DATETIME
```

**Medicines Table:**
```dart
- id: INTEGER (Primary Key)
- name: TEXT
- manufacturer: TEXT
- dosage: TEXT
- expiryDate: DATETIME
- batchNumber: TEXT
- mrp: TEXT
- doctorName: TEXT
- symptoms: TEXT
- prescriptionImage: TEXT
- createdAt: DATETIME
- updatedAt: DATETIME
```

### Repositories (`lib/data/repositories/`)
```
repositories/
├── medicine_repository.dart    # Medicine data operations
└── product_repository.dart     # Product data operations
```

**Repository Pattern:**
- CRUD operations
- Data validation
- Business logic
- Error handling

---

## 🔌 Services

### External Services (`lib/services/`)
```
services/
├── ai_extraction_service.dart          # AI data extraction
├── google_ml_kit_ocr_service.dart      # Google ML Kit OCR
├── medicine_api_service.dart           # Medicine API integration
├── multi_image_service_simple.dart     # Multi-image processing
├── online_ocr_service.dart             # Online OCR APIs
├── product_api_service.dart            # Product API integration
└── tesseract_ocr_service.dart          # Tesseract OCR (fallback)
```

### API Integrations

#### 1. Open Food Facts API
- **Purpose:** Food product information
- **Endpoint:** `https://world.openfoodfacts.org/api/v0/product/`
- **Cost:** Free
- **Data:** Product name, brand, ingredients, nutrition

#### 2. FDA Drug Database
- **Purpose:** Medicine information
- **Endpoint:** `https://api.fda.gov/drug/label.json`
- **Cost:** Free
- **Data:** Drug name, manufacturer, dosage, warnings

#### 3. UPCItemDB
- **Purpose:** General product lookup
- **Endpoint:** `https://api.upcitemdb.com/prod/trial/lookup`
- **Cost:** Free trial
- **Data:** Product details, pricing

#### 4. Oxlo.ai (AI Vision)
- **Purpose:** AI-powered OCR and data extraction
- **Models:** Ministral-14b (vision), Mistral-7b (text)
- **Cost:** Paid
- **Features:** Structured data extraction, date parsing

---

## 📱 Models

### Data Models (`lib/models/`)
```
models/
├── product_info.dart           # Product/Medicine model
└── product_info.g.dart         # Generated JSON serialization
```

**ProductInfo Model:**
```dart
class ProductInfo {
  int? id;
  String name;
  String? brand;
  String? category;
  DateTime? expiryDate;
  DateTime? manufacturingDate;
  String? batchNumber;
  String? ingredients;
  String? notes;
  List<String>? imagePaths;
  bool isMedicine;
  String? dosage;
  String? doctorName;
  String? symptoms;
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

---

## 🌐 Platform Support

### Android (`android/`)
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14)
- **Build System:** Gradle (Kotlin DSL)
- **Features:** Camera, biometrics, notifications

### iOS (`ios/`)
- **Min Version:** iOS 12.0
- **Build System:** Xcode
- **Features:** Face ID, Touch ID, camera, notifications

### Web (`web/`)
- **Support:** Progressive Web App (PWA)
- **Features:** Camera access, local storage
- **Limitations:** No biometrics, limited notifications

### Desktop
- **Linux:** Full support
- **macOS:** Full support
- **Windows:** Full support
- **Features:** File system access, notifications

---

## 🧪 Testing

### Test Structure (`test/`)
```
test/
└── widget_test.dart            # Widget tests
```

**Test Coverage:**
- Widget tests for UI components
- Unit tests for business logic
- Integration tests for features

---

## 📦 Assets

### Assets Structure (`assets/`)
```
assets/
└── tessdata/
    └── eng.traineddata         # Tesseract English language data
```

---

## 🔄 Data Flow

### 1. Product Entry Flow
```
User Action (Scan/Capture/Manual)
    ↓
Image Capture / Barcode Scan
    ↓
OCR Processing (Multi-stage)
    ↓
AI Data Extraction
    ↓
Local Parser (Regex)
    ↓
API Enhancement (if barcode found)
    ↓
Preview Screen (User Review)
    ↓
Save to Database
    ↓
Update UI
```

### 2. OCR Pipeline
```
Image Input
    ↓
Image Validation
    ↓
Online OCR (Oxlo.ai) → Success? → Extract Data
    ↓ Fail
Offline OCR (ML Kit) → Success? → Extract Data
    ↓ Fail
Tesseract OCR → Success? → Extract Data
    ↓ Always
Local Parser (Regex) → Extract Dates/Patterns
    ↓
Merge Results
    ↓
Return Structured Data
```

### 3. Barcode Lookup Flow
```
Barcode Scanned
    ↓
Check Local Medicine Database
    ↓ Not Found
Open Food Facts API
    ↓ Not Found
FDA Drug Database
    ↓ Not Found
UPCItemDB
    ↓ Not Found
AI Lookup (Fallback)
    ↓
Return Product Info
```

---

## 🔐 Security Features

### 1. Biometric Authentication
- Fingerprint recognition
- Face ID / Touch ID
- Password fallback
- Session timeout (5 minutes)
- Failed attempt tracking
- Lockout protection

### 2. Data Security
- Local SQLite database
- No cloud storage by default
- Encrypted shared preferences
- Secure API key storage

### 3. Privacy
- No user tracking
- No analytics collection
- Local image processing
- User owns all data

---

## 🚀 Build & Deployment

### Development
```bash
# Get dependencies
flutter pub get

# Run on device
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Production Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 📊 Project Statistics

### Code Metrics
- **Total Dart Files:** 62
- **Core Services:** 18
- **Feature Screens:** 24
- **Data Models:** 2
- **Repositories:** 2
- **External Services:** 7

### Lines of Code (Estimated)
- **Total:** ~15,000 lines
- **Core Services:** ~4,000 lines
- **Features:** ~8,000 lines
- **Data Layer:** ~2,000 lines
- **Services:** ~1,000 lines

---

## 🔧 Configuration Files

### Key Configuration Files
- `pubspec.yaml` - Dependencies and assets
- `analysis_options.yaml` - Linter rules
- `.gitignore` - Git ignore patterns
- `android/build.gradle.kts` - Android build config
- `ios/Runner/Info.plist` - iOS configuration

---

## 📝 Documentation Files

- `API_DOCUMENTATION.md` - API reference
- `ARCHITECTURE.md` - Architecture details
- `BIOMETRIC_AUTHENTICATION.md` - Biometric auth guide
- `FILE_DOCUMENTATION.md` - File structure
- `FUNCTION_DOCUMENTATION.md` - Function reference
- `PROJECT_STRUCTURE.md` - This file

---

## 🎯 Future Enhancements

### Planned Features
1. Cloud sync (Firebase/Supabase)
2. Multi-language support
3. Barcode generation
4. PDF reports
5. Shopping list integration
6. Advanced analytics
7. Recipe suggestions based on expiring items
8. Sharing functionality
9. Backup/restore
10. Widget support

---

## 📞 Support & Contribution

### Getting Help
- Check documentation files
- Review code comments
- Run `flutter doctor` for setup issues

### Contributing
1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

---

**Last Updated:** 2024
**Version:** 1.0.0+8
**Flutter SDK:** >=3.8.0 <4.0.0
