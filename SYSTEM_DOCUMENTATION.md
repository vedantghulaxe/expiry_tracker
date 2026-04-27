# Expiry Tracker App - Complete System Documentation

## Table of Contents
1. [Tech Stack Overview](#tech-stack-overview)
2. [Architecture Overview](#architecture-overview)
3. [Core Services](#core-services)
4. [Features & Screens](#features--screens)
5. [API Integrations](#api-integrations)
6. [Database & Storage](#database--storage)
7. [AI & ML Components](#ai--ml-components)
8. [Development & Build](#development--build)

---

## Tech Stack Overview

### Frontend (Mobile App)
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **Platform Support**: Android, iOS, Web, Windows, macOS, Linux
- **State Management**: StatefulWidget + Provider pattern
- **Navigation**: Flutter Navigator 2.0

### Backend Services
- **Language**: Python 3.x
- **Framework**: FastAPI
- **Database**: SQLite (local), PostgreSQL (production optional)
- **API Documentation**: OpenAPI/Swagger

### External APIs & Services
- **OCR Services**: Google ML Kit, Tesseract, Online OCR APIs
- **Barcode APIs**: Open Food Facts, FDA Drug Database, UPCItemDB
- **Image Processing**: Mobile Scanner, Google ML Kit

### Development Tools
- **IDE**: VS Code, Android Studio
- **Version Control**: Git
- **Package Management**: Pub (Flutter), pip (Python)
- **Testing**: Flutter Test, Python pytest

---

## Architecture Overview

```
Expiry Tracker App
|
|-- lib/
|   |-- core/                    # Core business logic
|   |   |-- services/            # Business services
|   |   |-- utils/               # Utility functions
|   |-- data/                    # Data layer
|   |   |-- database/            # Database operations
|   |   |-- repositories/        # Data repositories
|   |-- domain/                  # Domain models
|   |-- features/                # Feature modules
|   |   |-- add/                 # Add product feature
|   |   |-- analytics/           # Analytics feature
|   |   |-- common/              # Shared components
|   |   |-- dashboard/           # Dashboard feature
|   |   |-- product/             # Product management
|   |-- main.dart                # App entry point
|
|-- backend/                     # Python backend
|   |-- main.py                  # FastAPI server
|   |-- requirements.txt         # Python dependencies
|   |-- expiry_management.db     # SQLite database
|
|-- assets/                      # Static assets
|   |-- tessdata/               # Tesseract OCR data
```

---

## Core Services

### 1. OCR Services

#### `OCRService` (`lib/core/services/ocr_service.dart`)
**Purpose**: Text extraction from images using multiple OCR engines

**Tech Stack**: Google ML Kit, Tesseract, HTTP APIs

**Key Functions**:
```dart
// Extract text from single image
static Future<OCRResult> extractTextFromImage(File image)

// Extract text from multiple images
static Future<OCRResult> extractTextFromMultipleImages(List<File> images)

// Online OCR using external API
static Future<OCRResult> extractTextOnline(String imageBase64)
```

**Features**:
- Multi-engine support (Google ML Kit, Tesseract, Online API)
- Confidence scoring
- Error handling and fallbacks
- Image preprocessing

---

#### `MultiImageServiceSimple` (`lib/services/multi_image_service_simple.dart`)
**Purpose**: Robust OCR pipeline with API enhancement

**Tech Stack**: Flutter, HTTP, Multiple OCR APIs

**Key Functions**:
```dart
// Process multiple images with robust pipeline
static Future<Map<String, dynamic>> processMultipleImages(List<File> images)

// Capture multiple images from camera
static Future<List<File>> captureMultipleImages()

// Get captured images count
static int getCapturedImagesCount()
```

**Pipeline Flow**:
1. Image validation and preprocessing
2. OCR extraction (offline first, online fallback)
3. Local parsing and data extraction
4. API enhancement (if barcode/product found)
5. Result aggregation and confidence scoring

---

### 2. Data Parsing Services

#### `LocalParserService` (`lib/core/services/local_parser_service.dart`)
**Purpose**: Extract structured information from OCR text

**Tech Stack**: Dart, Regular Expressions, Heuristics

**Key Functions**:
```dart
// Parse OCR text into structured data
static Map<String, dynamic> parseOCRText(String text)

// Extract product name with AI patterns
static String _extractSimpleProductName(String text)

// Extract brand/manufacturer
static String _extractSimpleBrand(String text)

// Extract dates (expiry, manufacturing)
static String _extractSimpleDate(String text, String dateType)

// Extract batch numbers
static String _extractSimpleBatch(String text)

// Classify if product is medicine
static bool _isMedicineContent(String text)
```

**Extraction Patterns**:
- Product name: Capitalized words, product keywords
- Brand: Company patterns, LLP/LTD, "Manufactured by"
- Dates: MM/YYYY, DD/MM/YYYY formats
- Batch: Alphanumeric codes, license numbers
- Category: Medicine vs product classification

---

#### `AIExtractionService` (`lib/services/ai_extraction_service.dart`)
**Purpose**: AI-powered intelligent data extraction

**Tech Stack**: Dart, Pattern Matching, Decision Trees

**Key Functions**:
```dart
// AI-powered information extraction
static Map<String, dynamic> extractInformation(String text)

// Smart product name extraction
static String extractProductName(String text)

// Intelligent brand detection
static String extractBrand(String text)

// Smart date parsing with context
static String extractDate(String text, String context)

// Batch number pattern recognition
static String extractBatchNumber(String text)
```

---

### 3. Barcode Services

#### `BarcodeService` (`lib/core/services/barcode_service.dart`)
**Purpose**: Barcode scanning and product information lookup

**Tech Stack**: Google ML Kit, HTTP APIs, JSON Parsing

**Key Functions**:
```dart
// Scan barcode from image
static Future<String?> scanBarcodeFromImage(String imagePath)

// Get product info from barcode
static Future<Map<String, dynamic>> getProductInfo(String barcode)

// Validate barcode format
static bool isValidBarcode(String barcode)
```

---

#### `ProductApiService` (`lib/core/services/product_api_service.dart`)
**Purpose**: API-powered product information lookup

**Tech Stack**: HTTP, JSON, Multiple External APIs

**Key Functions**:
```dart
// Open Food Facts API lookup
static Future<Map<String, dynamic>> fetchFromOpenFoodFacts(String barcode)

// FDA Drug Database lookup
static Future<Map<String, dynamic>> fetchFromFDA(String searchTerm)

// UPCItemDB lookup
static Future<Map<String, dynamic>> fetchFromUPCItemDB(String barcode)

// Smart product lookup (combines all APIs)
static Future<Map<String, dynamic>> smartProductLookup(String query)

// Enhance OCR with API data
static Future<Map<String, dynamic>> enhanceOCRWithAPI(Map<String, dynamic> ocrResult, String? barcode)
```

**APIs Used**:
- Open Food Facts (free, food products)
- FDA Drug Database (free, medicines)
- UPCItemDB (free trial, general products)
- Barcode Spider (paid, comprehensive)

---

### 4. Database Services

#### `DatabaseService` (`lib/data/database/database_service.dart`)
**Purpose**: SQLite database operations

**Tech Stack**: SQLite, Dart, SQL

**Key Functions**:
```dart
// Initialize database
static Future<void> initDatabase()

// Insert product
static Future<int> insertProduct(Map<String, dynamic> product)

// Get all products
static Future<List<Map<String, dynamic>>> getAllProducts()

// Get products by category
static Future<List<Map<String, dynamic>>> getProductsByCategory(String category)

// Update product
static Future<void> updateProduct(int id, Map<String, dynamic> product)

// Delete product
static Future<void> deleteProduct(int id)
```

**Database Schema**:
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    brand TEXT,
    category TEXT,
    expiry_date TEXT,
    manufacturing_date TEXT,
    batch_number TEXT,
    ingredients TEXT,
    notes TEXT,
    image_path TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

#### `ProductRepository` (`lib/data/repositories/product_repository.dart`)
**Purpose**: Repository pattern for product data access

**Tech Stack**: Dart, Repository Pattern, Database Service

**Key Functions**:
```dart
// Create product
Future<Product> createProduct(Product product)

// Get all products
Future<List<Product>> getAllProducts()

// Get product by ID
Future<Product?> getProductById(int id)

// Update product
Future<void> updateProduct(Product product)

// Delete product
Future<void> deleteProduct(int id)

// Search products
Future<List<Product>> searchProducts(String query)
```

---

### 5. Utility Services

#### `LoggerService` (`lib/core/services/logger_service.dart`)
**Purpose**: Application logging

**Tech Stack**: Dart, File I/O, Console Output

**Key Functions**:
```dart
// Log info message
static void info(String tag, String message)

// Log success message
static void success(String tag, String message)

// Log error message
static void error(String tag, String message)

// Log warning message
static void warning(String tag, String message)

// Log debug message
static void debug(String tag, String message)
```

---

## Features & Screens

### 1. Dashboard Screen

#### `DashboardScreen` (`lib/features/dashboard/dashboard_screen.dart`)
**Purpose**: Main app dashboard with product overview

**Tech Stack**: Flutter, State Management, Navigation

**Key Functions**:
```dart
// Build dashboard UI
Widget build(BuildContext context)

// Navigate to add product
void _navigateToAddProduct()

// Navigate to analytics
void _navigateToAnalytics()

// Refresh product list
Future<void> _refreshProducts()
```

**Features**:
- Product statistics
- Quick actions (Add, Scan, Analytics)
- Product list with expiry indicators
- Search and filter functionality

---

### 2. Image Capture Screen

#### `ImageCaptureScreenSimple` (`lib/features/common/image_capture_screen_simple.dart`)
**Purpose**: Multi-modal product data capture

**Tech Stack**: Flutter, Image Picker, Camera, Mobile Scanner

**Key Functions**:
```dart
// Capture image from camera
Future<void> _captureImage()

// Pick image from gallery
Future<void> _pickImage()

// Scan barcode
Future<void> _scanBarcode()

// Process captured images
Future<void> _processImages()

// Navigate to manual entry
void _navigateToManualEntry()
```

**Capture Modes**:
- Camera capture
- Gallery selection
- Barcode scanning
- Multi-image support

---

### 3. Manual Product Entry

#### `ManualProductEntryScreen` (`lib/features/product/manual_product_entry_screen.dart`)
**Purpose**: Manual product data entry with AI assistance

**Tech Stack**: Flutter, Forms, AI Integration, Date Pickers

**Key Functions**:
```dart
// AI-powered form population
void _populateFormFromAnalysisData()

// Extract information using AI
Map<String, dynamic> _aiExtractInformation(String rawText, Map<String, dynamic> parsedData)

// Save product
Future<void> _saveProduct()

// Validate form
bool _validateForm()
```

**AI Features**:
- Intelligent name extraction
- Brand detection
- Date parsing
- Category classification
- Medicine detection

---

### 4. Analytics Screen

#### `AnalyticsScreen` (`lib/features/analytics/analytics_screen.dart`)
**Purpose**: Product analytics and insights

**Tech Stack**: Flutter, Charts, Data Aggregation

**Key Functions**:
```dart
// Generate expiry statistics
Map<String, int> _calculateExpiryStats()

// Generate category breakdown
Map<String, int> _calculateCategoryStats()

// Build charts
Widget _buildExpiryChart()
Widget _buildCategoryChart()
```

---

## API Integrations

### 1. Open Food Facts API
**Purpose**: Food product information
**Base URL**: `https://world.openfoodfacts.org/api/v0/product/`
**Authentication**: None (free)
**Rate Limit**: None specified

**Usage**:
```dart
final response = await http.get(
  Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
  headers: {'User-Agent': 'ExpiryTrackerApp/1.0'},
);
```

**Data Returned**:
- Product name, brand, category
- Ingredients, nutrition info
- Packaging, quantity
- Images, labels

---

### 2. FDA Drug Database API
**Purpose**: Medicine information
**Base URL**: `https://api.fda.gov/drug/label.json`
**Authentication**: None (free)
**Rate Limit**: None specified

**Usage**:
```dart
final response = await http.get(
  Uri.parse('https://api.fda.gov/drug/label.json?search=openfda.product_ndc:$searchTerm'),
);
```

**Data Returned**:
- Drug name, manufacturer
- Dosage, administration
- Uses, indications
- Warnings, contraindications

---

### 3. UPCItemDB API
**Purpose**: General product information
**Base URL**: `https://api.upcitemdb.com/prod/trial/lookup`
**Authentication**: None (free trial)
**Rate Limit**: Limited for trial

**Usage**:
```dart
final response = await http.get(
  Uri.parse('https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode'),
  headers: {'User-Agent': 'ExpiryTrackerApp/1.0'},
);
```

---

### 4. Online OCR API
**Purpose**: Cloud-based text extraction
**Base URL**: Various (OCR.space, Google Vision, etc.)
**Authentication**: API Key required
**Rate Limit**: Depends on service

**Usage**:
```dart
final response = await http.post(
  Uri.parse('https://api.ocr.space/parse/image'),
  headers: {'apikey': 'YOUR_API_KEY'},
  body: {'base64Image': imageBase64},
);
```

---

## Database & Storage

### 1. SQLite Database
**Location**: `backend/expiry_management.db`
**Purpose**: Local data storage
**Tables**:
- `products` - Product information
- `categories` - Product categories
- `logs` - Application logs

### 2. File Storage
**Images**: Local device storage
**Cache**: Temporary image processing
**Backups**: Optional cloud backup

### 3. Data Models

#### Product Model
```dart
class Product {
  int? id;
  String name;
  String brand;
  String category;
  DateTime? expiryDate;
  DateTime? manufacturingDate;
  String batchNumber;
  String ingredients;
  String notes;
  List<String> imagePaths;
  DateTime createdAt;
  DateTime updatedAt;
}
```

---

## AI & ML Components

### 1. Google ML Kit
**Purpose**: On-device OCR and barcode scanning
**Features**:
- Text recognition
- Barcode scanning
- Image labeling

### 2. Custom AI Logic
**Pattern Recognition**:
- Product name patterns
- Brand detection algorithms
- Date extraction heuristics
- Category classification rules

### 3. Decision Trees
**Product Classification**:
- Medicine vs product detection
- Category assignment
- Confidence scoring

---

## Development & Build

### 1. Flutter Development
```bash
# Install dependencies
flutter pub get

# Run development server
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

### 2. Python Backend
```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
python main.py

# Run with uvicorn
uvicorn main:app --reload
```

### 3. Testing
```bash
# Flutter tests
flutter test

# Python tests
pytest
```

### 4. Deployment
**Android**: APK/AAB files
**iOS**: IPA files
**Web**: Build and deploy to web server
**Backend**: Docker container or cloud service

---

## Configuration

### Environment Variables
```env
# API Keys
OCR_API_KEY=your_ocr_api_key
BARCODE_SPIDER_API_KEY=your_barcode_api_key

# Database
DATABASE_URL=sqlite:///expiry_management.db

# Backend
BACKEND_URL=http://localhost:8000
```

### Dependencies
**Flutter** (`pubspec.yaml`):
- `http` - HTTP requests
- `image_picker` - Image selection
- `mobile_scanner` - Barcode scanning
- `google_ml_kit` - ML Kit integration
- `sqflite` - SQLite database
- `path_provider` - File paths

**Python** (`requirements.txt`):
- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `sqlite3` - Database
- `python-multipart` - File uploads

---

## Security Considerations

1. **API Keys**: Store in environment variables
2. **Data Privacy**: Local storage by default
3. **Network Security**: HTTPS for API calls
4. **Input Validation**: Sanitize all inputs
5. **Error Handling**: Don't expose sensitive info

---

## Performance Optimization

1. **Image Processing**: Resize and compress images
2. **Caching**: Cache API responses
3. **Lazy Loading**: Load data as needed
4. **Background Processing**: Use isolates for heavy tasks
5. **Memory Management**: Clear image cache

---

## Future Enhancements

1. **Cloud Sync**: Multi-device synchronization
2. **Notifications**: Expiry reminders
3. **Offline Mode**: Enhanced offline capabilities
4. **ML Models**: Custom trained models
5. **API Expansion**: More product databases

---

## Troubleshooting

### Common Issues
1. **OCR Accuracy**: Ensure good lighting and focus
2. **API Limits**: Implement rate limiting
3. **Memory Usage**: Optimize image sizes
4. **Database Locks**: Use proper transactions

### Debug Tools
1. **Flutter Inspector**: UI debugging
2. **Logger Service**: Application logs
3. **Network Logs**: API request/response tracking
4. **Database Browser**: SQLite inspection

---

This documentation provides a comprehensive overview of the Expiry Tracker App system, its architecture, technologies, and implementation details.
