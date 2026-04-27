# Expiry Tracker App - Architecture Documentation

## Project Overview

The Expiry Tracker App is a Flutter mobile application that helps users track expiry dates of products and medicines. It uses AI-powered OCR (Optical Character Recognition) and barcode scanning to automatically extract product information from images and labels.

**Key Features:**
- Barcode scanning with multiple format support (EAN-13, EAN-8, UPC-A, UPC-E, Code 128, etc.)
- AI-powered image analysis using Oxlo.ai vision API
- Automatic expiry date extraction from product labels
- Local database for offline storage
- Expiry notifications
- Support for both food products and medicines

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Flutter)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Home Screen │  │ Barcode Scan │  │ Image Capture│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  Presentation Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Product Form │  │ Manual Entry │  │  List Views  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Service Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ AIService    │  │BarcodeService│  │ProductApiSvc │      │
│  │ (Oxlo.ai)    │  │              │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │RobustOCR     │  │LocalParser   │  │ConfigService │      │
│  │Service       │  │Service       │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Data Layer                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Drift DB    │  │  Repository  │  │  Local DB    │      │
│  │  (SQLite)    │  │  Pattern     │  │  File Storage│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  External APIs                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Oxlo.ai     │  │Open Food     │  │  FDA Drug    │      │
│  │  Vision API  │  │Facts API     │  │  Database    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. UI Layer (Flutter Widgets)

**Location:** `lib/features/`

- **`home_screen.dart`**: Main dashboard showing all products with expiry status
- **`barcode_scanner_screen.dart`**: Barcode scanning using mobile_scanner package
- **`image_capture_screen_real_ocr.dart`**: Image capture and OCR analysis
- **`product_entry_method_screen.dart`**: Selection screen for entry method (barcode/image/manual)
- **`manual_product_entry_screen.dart`**: Form for manual entry with AI auto-fill
- **`product_form_screen_new.dart`**: Product form with pre-filled data

### 2. Service Layer

**Location:** `lib/core/services/` and `lib/services/`

#### AIService (`lib/core/services/ai_service.dart`)
- **Purpose:** AI-powered vision analysis using Oxlo.ai API
- **Model:** `ministral-14b` for vision tasks
- **Features:**
  - Structured data extraction from images
  - Retry logic with exponential backoff (3 attempts)
  - Handles network errors gracefully
  - Extracts: name, brand, expiry, mfg_date, batch, ingredients

#### BarcodeService (`lib/core/services/barcode_service.dart`)
- **Purpose:** Barcode lookup and product information retrieval
- **Features:**
  - Local Indian medicine database (10 common medicines)
  - Public API lookup (Open Food Facts, FDA, UPCItemDB)
  - AI fallback for unknown barcodes
  - Retry logic for API calls
  - Supported formats: EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, etc.

#### RobustOCRService (`lib/core/services/robust_ocr_service.dart`)
- **Purpose:** Multi-stage OCR pipeline with fallback mechanisms
- **Pipeline:**
  1. Image validation
  2. Online OCR (Oxlo.ai AI vision)
  3. Offline OCR (ML Kit + Tesseract)
  4. Local parsing
- **Features:**
  - Automatic online/offline switching
  - Structured data extraction
  - Confidence scoring

#### ProductApiService (`lib/core/services/product_api_service.dart`)
- **Purpose:** Public API integration for product lookup
- **APIs:**
  - Open Food Facts (food products)
  - FDA Drug Database (US medicines)
  - UPCItemDB (general products)
- **Features:**
  - Smart lookup with multiple API fallback
  - Expiry date extraction
  - Medicine classification

#### LocalParserService (`lib/core/services/local_parser_service.dart`)
- **Purpose:** Regex-based text extraction
- **Features:**
  - Date pattern matching (DD/MM/YYYY, MM/YYYY, DDMMMYY)
  - Product name extraction
  - Batch number detection
  - Brand/manufacturer extraction

#### ConfigService (`lib/core/services/config_service.dart`)
- **Purpose:** Configuration management
- **Features:**
  - API key storage (Oxlo.ai)
  - App settings

### 3. Data Layer

**Location:** `lib/data/` and `lib/core/services/`

#### DatabaseService (`lib/core/services/database_service.dart`)
- **Purpose:** SQLite database management using Drift ORM
- **Features:**
  - Product CRUD operations
  - Query by expiry status
  - Batch operations

#### ProductRepository (`lib/data/repositories/product_repository.dart`)
- **Purpose:** Repository pattern for data access
- **Features:**
  - Abstraction over database
  - Business logic for data operations

#### AppDatabase (`lib/data/database/app_database.dart`)
- **Purpose:** Drift database schema definition
- **Tables:**
  - Products (id, name, brand, expiry_date, mfg_date, category, etc.)
  - Images (product_id, image_path)

---

## Data Flow

### Barcode Scanning Flow

```
User scans barcode
        ↓
BarcodeScannerScreen captures barcode
        ↓
BarcodeService.getProductInfo(barcode)
        ↓
1. Check local Indian medicine database
2. If not found, query public APIs (Open Food Facts, FDA, UPCItemDB)
3. If still not found, query Oxlo.ai AI lookup
        ↓
Return product data to form
        ↓
ProductFormScreenNew with pre-filled data
        ↓
User reviews and saves
        ↓
ProductRepository.save()
```

### Image Capture Flow

```
User captures image
        ↓
ImageCaptureScreenRealOCR
        ↓
MultiImageServiceSimple.processMultipleImages()
        ↓
RobustOCRService.extractTextFromImages()
        ↓
1. Image validation
2. Online OCR: AIService.extractStructuredData() (Oxlo.ai vision)
3. If fails, offline OCR: ML Kit + Tesseract
        ↓
LocalParserService.parseText() (regex extraction)
        ↓
Merge AI vision data + local parsing
        ↓
Return analysis result to form
        ↓
ManualProductEntryScreen._populateFormFromAnalysisData()
        ↓
Prioritize AI vision data over regex
        ↓
Form fields auto-populated
        ↓
User reviews and saves
        ↓
ProductRepository.save()
```

---

## Services Deep Dive

### AIService (Oxlo.ai Integration)

**API Endpoint:** `https://api.oxlo.ai/v1`
**Vision Model:** `ministral-14b`
**Text Model:** `mistral-7b`

**Key Methods:**

```dart
// Extract structured data from image
Future<Map<String, dynamic>> extractStructuredData({
  required String imagePath,
  String? rawText,
  String? barcode,
})
```

**Prompt Engineering:**
- System prompt specifies exact extraction rules
- Handles multiple date formats (DD/MM/YYYY, MM/YYYY, DDMMMYY)
- Extracts: name, brand, manufacturer, batch, expiry, mfg_date, ingredients

**Retry Logic:**
- 3 attempts with exponential backoff
- Delays: 2s, 4s, 6s
- Handles: SocketException, HttpException
- User-Agent header for compatibility

### BarcodeService

**Local Database:**
```dart
static const Map<String, Map<String, dynamic>> _indianMedicineDatabase = {
  '8901033010285': {'name': 'Crocin 500mg', 'brand': 'GSK', ...},
  '8901144000113': {'name': 'Dolo 650', 'brand': 'Micro Labs', ...},
  // ... 10 common Indian medicines
}
```

**Lookup Priority:**
1. Local Indian medicine database (instant)
2. Open Food Facts API (food products)
3. FDA Drug Database (US medicines)
4. UPCItemDB API (general products)
5. Oxlo.ai AI lookup (fallback)

### RobustOCRService

**OCR Pipeline:**

```dart
1. Image Validation
   - Check if image contains product label
   - Quality assessment
   - Confidence scoring

2. Online OCR (Primary)
   - Call AIService with Oxlo.ai vision
   - Extract structured data
   - High accuracy

3. Offline OCR (Fallback)
   - Google ML Kit (on-device)
   - Tesseract OCR (offline)
   - Lower accuracy but works offline

4. Local Parsing (Always runs)
   - Regex-based extraction
   - Date pattern matching
   - Brand detection
```

---

## Database Schema

### Products Table

```dart
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get category => text()();
  TextColumn get ingredients => text().nullable()();
  DateTimeColumn get expiryDate => dateTime()();
  DateTimeColumn get manufacturingDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isMedicine => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

---

## Configuration

### API Keys

**Oxlo.ai API Key:** `sk_WEjud3_3D4_KrpFaqIKab8m2aHlWxnH3YGL-u-B8xz0`
- Stored in ConfigService
- Used for AI vision and text extraction
- Supports both vision (ministral-14b) and text (mistral-7b) models

### Supported Barcode Formats

- EAN-13 (most common for products)
- EAN-8
- UPC-A
- UPC-E
- Code 128
- Code 39
- Code 93
- ITF
- Codabar
- QR Code

---

## Error Handling

### Network Errors
- Retry logic with exponential backoff
- Fallback to offline methods
- User-friendly error messages

### OCR Failures
- Multiple OCR engines (ML Kit + Tesseract)
- Local regex parsing as fallback
- Manual entry option

### Barcode Not Found
- Suggest image capture
- AI lookup fallback
- Manual entry option

---

## Performance Optimizations

1. **Local Database:** Instant lookup for common Indian medicines
2. **Caching:** Product data cached locally
3. **Lazy Loading:** Images loaded on demand
4. **Batch Operations:** Multiple images processed together
5. **Offline Support:** Works without internet (with reduced accuracy)

---

## Dependencies

### Key Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Database
  drift: ^2.31.0
  sqlite3_flutter_libs: ^3.1.0
  
  # OCR & Vision
  mobile_scanner: ^3.5.6
  google_mlkit_text_recognition: ^0.11.0
  tesseract_ocr: ^0.4.0
  
  # Image Handling
  image_picker: ^1.0.7
  
  # State Management
  flutter_bloc: ^8.1.6
  
  # HTTP
  http: ^1.1.0
  
  # Utilities
  intl: ^0.18.1
  path_provider: ^2.1.1
```

---

## Security Considerations

1. **API Keys:** Stored in ConfigService (not hardcoded in UI)
2. **Data Privacy:** Local database storage
3. **Image Processing:** Images processed locally when possible
4. **Network:** HTTPS for all API calls

---

## Future Enhancements

1. **Cloud Sync:** Backup data to cloud
2. **Multi-language Support:** Support for labels in different languages
3. **Barcode Generation:** Generate QR codes for products
4. **Export/Import:** CSV export of product list
5. **Shopping List:** Create shopping lists from expiring items
6. **Notifications:** Push notifications for expiring products

---

## File Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── ai_service.dart              # Oxlo.ai integration
│   │   ├── barcode_service.dart         # Barcode lookup
│   │   ├── robust_ocr_service.dart      # OCR pipeline
│   │   ├── product_api_service.dart     # Public APIs
│   │   ├── local_parser_service.dart    # Regex parsing
│   │   ├── config_service.dart          # Configuration
│   │   ├── database_service.dart        # DB management
│   │   └── logger_service.dart          # Logging
│   └── utils/
│       └── ui_helpers.dart              # UI utilities
├── data/
│   ├── database/
│   │   └── app_database.dart            # Drift schema
│   └── repositories/
│       └── product_repository.dart      # Repository pattern
├── features/
│   ├── common/
│   │   ├── barcode_scanner_screen.dart
│   │   └── image_capture_screen_real_ocr.dart
│   └── product/
│       ├── product_entry_method_screen.dart
│       ├── manual_product_entry_screen.dart
│       └── product_form_screen_new.dart
├── models/
│   └── product_info.dart                # Product model
└── services/
    └── multi_image_service_simple.dart  # Multi-image processing
```

---

## How It Works - Step by Step

### Adding a Product via Barcode

1. **User Action:** User taps "Scan Barcode" on home screen
2. **Camera Opens:** BarcodeScannerScreen opens camera with mobile_scanner
3. **Barcode Detection:** Camera detects barcode (supports multiple formats)
4. **Manual Entry Option:** If scan fails, user can manually enter barcode
5. **Product Lookup:** BarcodeService.getProductInfo() is called
6. **Database Check:** First checks local Indian medicine database
7. **API Lookup:** If not found, queries public APIs
8. **AI Fallback:** If APIs fail, uses Oxlo.ai AI lookup
9. **Form Population:** ProductFormScreenNew with pre-filled data
10. **User Review:** User reviews and edits if needed
11. **Save:** Product saved to local database via ProductRepository

### Adding a Product via Image

1. **User Action:** User taps "Capture Image" on home screen
2. **Camera/Gallery:** ImageCaptureScreenRealOCR opens
3. **Image Capture:** User captures product label image
4. **OCR Analysis:** MultiImageServiceSimple processes image
5. **AI Vision:** RobustOCRService calls AIService (Oxlo.ai)
6. **Structured Extraction:** AI extracts name, brand, expiry, etc.
7. **Fallback:** If AI fails, uses ML Kit + Tesseract
8. **Form Population:** ManualProductEntryScreen auto-fills with AI data
9. **Data Priority:** AI vision data prioritized over regex extraction
10. **User Review:** User reviews and edits if needed
11. **Save:** Product saved to local database

### Viewing Products

1. **Home Screen:** Shows all products sorted by expiry date
2. **Color Coding:** 
   - Red: Expired
   - Orange: Expiring soon (within 7 days)
   - Green: Good
3. **Filtering:** Filter by category (medicine/food)
4. **Search:** Search by name or brand
5. **Details:** Tap product to view details

---

## Troubleshooting

### Barcode Not Working
- Check if barcode format is supported
- Try manual barcode entry
- Use image capture as fallback

### OCR Not Extracting Correctly
- Ensure good lighting
- Hold camera steady
- Use flat surface for label
- Check logs to see if AI or regex is being used

### Network Errors
- App works offline with reduced accuracy
- Retry logic handles transient errors
- Local database provides instant lookup for known products

---

## Conclusion

The Expiry Tracker App uses a sophisticated multi-layered architecture combining:
- **AI Vision** (Oxlo.ai) for accurate data extraction
- **Multiple OCR engines** for reliability
- **Public APIs** for product information
- **Local database** for offline support
- **Retry logic** for network resilience

The app prioritizes AI vision data over regex extraction for accuracy, with comprehensive fallback mechanisms to ensure it works in various conditions.
