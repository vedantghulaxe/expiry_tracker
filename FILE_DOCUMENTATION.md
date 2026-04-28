# Expiry Tracker App - File Documentation

## Overview

This document provides detailed explanations of each file in the Expiry Tracker App project, including their purpose, key components, and how they work together.

---

## Table of Contents

1. [Core Services](#core-services)
2. [Core Utilities](#core-utilities)
3. [Data Layer](#data-layer)
4. [Features - Common](#features---common)
5. [Features - Auth](#features---auth)
6. [Features - Product](#features---product)
7. [Features - Medicine](#features---medicine)
8. [Features - Inventory](#features---inventory)
9. [Features - Batch](#features---batch)
10. [Features - Analytics](#features---analytics)
11. [Features - Dashboard](#features---dashboard)
12. [Features - Home](#features---home)
13. [Features - Expiry](#features---expiry)
14. [Services](#services)
15. [Models](#models)
16. [Widgets](#widgets)

---

## Core Services

### `lib/core/services/ai_service.dart`

**Purpose:** AI-powered vision and text extraction using Oxlo.ai API

**Key Components:**
- `AIService` class - Main service for AI operations
- `extractStructuredData()` - Extracts structured data from images using vision model
- `extractText()` - Extracts text using text model

**How it Works:**
1. Accepts image path and optional text/barcode hints
2. Converts image to base64
3. Sends request to Oxlo.ai API (`https://api.oxlo.ai/v1`)
4. Uses `ministral-14b` model for vision tasks
5. Uses `mistral-7b` model for text tasks
6. Parses JSON response with structured data (name, brand, expiry, mfg_date, batch, ingredients)
7. Implements retry logic with exponential backoff (3 attempts, 2s/4s/6s delays)
8. Handles network errors (SocketException, HttpException)

**API Key:** `sk_WEjud3_3D4_KrpFaqIKab8m2aHlWxnH3YGL-u-B8xz0`

---

### `lib/core/services/ai_extraction_service.dart`

**Purpose:** AI-based text extraction and parsing service

**Key Components:**
- `AIExtractionService` class
- `extractProductInfo()` - Extracts product information from text
- `extractDates()` - Extracts dates from text using AI

**How it Works:**
1. Accepts raw text input
2. Uses Oxlo.ai text model to parse and extract structured information
3. Returns parsed product data (name, brand, expiry, mfg_date, etc.)
4. Implements retry logic for network resilience
5. Fallback to regex parsing if AI fails

---

### `lib/core/services/barcode_service.dart`

**Purpose:** Barcode lookup and product information retrieval

**Key Components:**
- `BarcodeService` class
- Local Indian medicine database (10 common medicines)
- `getProductInfo()` - Main method for barcode lookup
- `_lookupBarcodeWithAI()` - AI fallback for unknown barcodes

**How it Works:**
1. **Step 1:** Checks local Indian medicine database for instant lookup
   - Crocin 500mg, Crocin 650mg, Dolo 650, Dolo 500, Combiflam, Allegra, Azithral, Augmentin
2. **Step 2:** If not found, queries ProductApiService for public API lookup
   - Open Food Facts (food products)
   - FDA Drug Database (US medicines)
   - UPCItemDB (general products)
3. **Step 3:** If APIs fail, uses Oxlo.ai AI lookup to identify product from barcode
4. **Step 4:** Returns basic fallback if all methods fail
5. Implements retry logic (3 attempts) for AI lookup

**Supported Barcode Formats:** EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93, ITF, Codabar, QR Code

---

### `lib/core/services/config_service.dart`

**Purpose:** Configuration management for the application

**Key Components:**
- `ConfigService` class
- `oxloApiKey` - Oxlo.ai API key
- Static methods for accessing configuration

**How it Works:**
1. Stores API keys and configuration values
2. Provides static access to Oxlo.ai API key
3. Used by AIService, AIExtractionService, and BarcodeService
4. Can be extended to store other configuration (app settings, preferences)

---

### `lib/core/services/connectivity_service.dart`

**Purpose:** Network connectivity monitoring

**Key Components:**
- `ConnectivityService` class
- Monitors network status using connectivity_plus
- Provides callbacks for connectivity changes

**How it Works:**
1. Listens to network connectivity changes
2. Emits status updates when connection changes
3. Used by services to determine if online operations are possible
4. Helps with offline/online mode switching

---

### `lib/core/services/database_service.dart`

**Purpose:** SQLite database management using Drift ORM

**Key Components:**
- `DatabaseService` class
- `database` getter - Returns Drift database instance
- CRUD operations for products

**How it Works:**
1. Initializes SQLite database using Drift
2. Provides methods for database operations
3. Manages database migrations
4. Abstracts database access from UI layer
5. Used by repositories for data persistence

---

### `lib/core/services/image_validation_service.dart`

**Purpose:** Validates images before OCR processing

**Key Components:**
- `ImageValidationService` class
- `validateProductLabel()` - Validates if image contains product label
- Returns confidence score and validation result

**How it Works:**
1. Analyzes image quality and content
2. Checks if image contains text/label
3. Returns confidence score (0.0 to 1.0)
4. Filters out low-quality images before OCR
5. Used by RobustOCRService to pre-validate images

---

### `lib/core/services/local_parser_service.dart`

**Purpose:** Regex-based text extraction and parsing

**Key Components:**
- `LocalParserService` class
- `parseText()` - Main parsing method
- Date pattern matching
- Product name extraction
- Batch number detection

**How it Works:**
1. Accepts raw text from OCR
2. Uses regex patterns to extract information:
   - Dates: DD/MM/YYYY, MM/YYYY, DDMMMYY (e.g., 03AUG26)
   - Product names: Capitalized words, common product terms
   - Batch numbers: After "BATCH", "B.No", "LOT"
   - Brand/manufacturer: Company names
3. Returns structured parsed data
4. Used as fallback when AI extraction fails

**Supported Date Formats:**
- DD/MM/YYYY (e.g., 28/04/2026)
- MM/YYYY (e.g., 04/2026)
- DDMMMYY (e.g., 28APR26)
- DD-MMM-YY (e.g., 28-APR-26)

---

### `lib/core/services/logger_service.dart`

**Purpose:** Logging service for debugging and monitoring

**Key Components:**
- `LoggerService` class
- `start()`, `success()`, `error()`, `warning()`, `info()` methods
- Structured logging with timestamps

**How it Works:**
1. Provides consistent logging interface across the app
2. Logs with different levels (info, warning, error, success)
3. Includes timestamps and context
4. Used by all services for debugging
5. Helps track data flow and identify issues

---

### `lib/core/services/notification_service.dart`

**Purpose:** Local notification management for expiry reminders

**Key Components:**
- `NotificationService` class
- `scheduleExpiryNotification()` - Schedules reminder for expiring products
- `cancelNotification()` - Cancels scheduled notifications

**How it Works:**
1. Uses flutter_local_notifications plugin
2. Schedules notifications based on expiry dates
3. Can schedule multiple notifications (1 week, 1 day before expiry)
4. Manages notification channels
5. Shows notification when product is expiring

---

### `lib/core/services/ocr_service.dart`

**Purpose:** OCR (Optical Character Recognition) service

**Key Components:**
- `OCRService` class
- `extractTextFromImage()` - Extracts text from images
- Uses Google ML Kit for on-device OCR

**How it Works:**
1. Accepts image file path
2. Uses Google ML Kit Text Recognition
3. Extracts all text from image
4. Returns raw text string
5. Used by RobustOCRService as part of the OCR pipeline

---

### `lib/core/services/offline_ocr_service.dart`

**Purpose:** Offline OCR service for when internet is unavailable

**Key Components:**
- `OfflineOCRService` class
- `extractText()` - Extracts text without internet
- Uses Tesseract OCR engine

**How it Works:**
1. Uses Tesseract OCR for offline text extraction
2. Works without internet connection
3. Lower accuracy than AI but works offline
4. Used as fallback in RobustOCRService

---

### `lib/core/services/product_api_service.dart`

**Purpose:** Public API integration for product lookup

**Key Components:**
- `ProductApiService` class
- `smartProductLookup()` - Smart lookup with multiple API fallback
- `fetchFromOpenFoodFacts()` - Open Food Facts API
- `fetchFromFDA()` - FDA Drug Database API
- `fetchFromUPCDatabase()` - UPCItemDB API

**How it Works:**
1. **Open Food Facts API:** Queries food product database
   - Endpoint: `https://world.openfoodfacts.org/api/v0/product/{barcode}.json`
   - Returns: name, brand, category, ingredients, quantity

2. **FDA Drug Database:** Queries US FDA approved medicines
   - Endpoint: `https://api.fda.gov/drug/label.json`
   - Returns: brand name, generic name, manufacturer, dosage

3. **UPCItemDB:** General product database
   - Endpoint: `https://api.upcdatabase.org/product/{barcode}`
   - Returns: product name, description

4. **Smart Lookup:** Tries all APIs in sequence until one succeeds

---

### `lib/core/services/robust_ocr_service.dart`

**Purpose:** Multi-stage OCR pipeline with fallback mechanisms

**Key Components:**
- `RobustOCRService` class
- `extractTextFromImages()` - Main OCR pipeline method
- `_extractStructuredDataWithGemini()` - AI vision extraction
- Online/offline switching

**How it Works:**
1. **Step 1: Image Validation**
   - Validates images using ImageValidationService
   - Filters low-quality images
   - Calculates confidence scores

2. **Step 2: Online OCR (Primary)**
   - Calls AIService with Oxlo.ai vision
   - Extracts structured data (name, brand, expiry, mfg_date, batch)
   - High accuracy, requires internet

3. **Step 3: Offline OCR (Fallback)**
   - If online fails, uses Google ML Kit
   - If ML Kit fails, uses Tesseract OCR
   - Lower accuracy but works offline

4. **Step 4: Local Parsing (Always runs)**
   - Uses LocalParserService for regex extraction
   - Merges results with AI/OCR data

5. **Returns:** OCRResult with text, confidence, method used

---

### `lib/core/services/simple_ocr_service.dart`

**Purpose:** Simplified OCR service for basic text extraction

**Key Components:**
- `SimpleOCRService` class
- Basic text extraction without complex pipeline

**How it Works:**
1. Simplified version of OCRService
2. Uses Google ML Kit for text extraction
3. Returns raw text without structured parsing
4. Used for simple OCR needs

---

### `lib/core/services/simple_service_manager.dart`

**Purpose:** Simple service manager for coordinating services

**Key Components:**
- `SimpleServiceManager` class
- Manages service lifecycle
- Coordinates between different services

**How it Works:**
1. Initializes and manages services
2. Coordinates service interactions
3. Handles service dependencies
4. Used in main.dart for service setup

---

### `lib/core/services/theme_service.dart`

**Purpose:** Theme management for the application

**Key Components:**
- `ThemeService` class
- Manages light/dark theme
- Theme persistence

**How it Works:**
1. Manages app theme (light/dark mode)
2. Persists theme preference
3. Provides theme to MaterialApp
4. Allows theme switching

---

### `lib/core/services/biometric_service.dart`

**Purpose:** Biometric authentication (fingerprint/face) support

**Key Components:**
- `BiometricService` class
- `authenticate()` - Biometric authentication
- `checkBiometricAvailability()` - Checks if biometrics available

**How it Works:**
1. Uses local_auth plugin for biometric authentication
2. Checks device biometric capabilities
3. Prompts user for fingerprint/face scan
4. Returns authentication result
5. Used by lock screen for security

---

### `lib/core/services/batch_processing_service.dart`

**Purpose:** Batch processing for multiple products

**Key Components:**
- `BatchProcessingService` class
- `processBatch()` - Processes multiple products
- Progress tracking

**How it Works:**
1. Accepts list of products/images
2. Processes them in batch
3. Tracks progress
4. Returns results for all items
5. Used by batch processing screens

---

### `lib/core/services/image_enhancement_service.dart`

**Purpose:** Image enhancement for better OCR accuracy

**Key Components:**
- `ImageEnhancementService` class
- `enhanceImage()` - Improves image quality
- Contrast adjustment, noise reduction

**How it Works:**
1. Accepts image file
2. Applies image enhancement:
   - Contrast adjustment
   - Brightness correction
   - Noise reduction
   - Sharpening
3. Returns enhanced image
4. Improves OCR accuracy

---

### `lib/core/services/api_service.dart`

**Purpose:** Generic API service for HTTP requests

**Key Components:**
- `ApiService` class
- Generic HTTP methods (GET, POST)
- Error handling

**How it Works:**
1. Provides generic HTTP request methods
2. Handles common errors
3. Adds headers (User-Agent, Content-Type)
4. Returns parsed JSON responses
5. Used by other API services

---

### `lib/core/services/barcode_api_service.dart`

**Purpose:** Barcode-specific API service

**Key Components:**
- `BarcodeApiService` class
- Barcode API integration
- Product lookup by barcode

**How it Works:**
1. Specialized API service for barcode lookup
2. Integrates with barcode databases
3. Returns product information
4. Used by BarcodeService

---

## Core Utilities

### `lib/core/utils/ui_helpers.dart`

**Purpose:** UI helper functions and widgets

**Key Components:**
- `showLoadingDialog()` - Shows loading dialog
- `showErrorDialog()` - Shows error dialog
- `showSuccessSnackBar()` - Shows success message
- Common UI utilities

**How it Works:**
1. Provides reusable UI helper methods
2. Standardizes dialogs and snackbars
3. Reduces code duplication
4. Used across all screens

---

### `lib/core/utils/error_handler.dart`

**Purpose:** Error handling and reporting

**Key Components:**
- `ErrorHandler` class
- `handleError()` - Centralized error handling
- Error logging and reporting

**How it Works:**
1. Catches and handles errors centrally
2. Logs errors using LoggerService
3. Shows user-friendly error messages
4. Used throughout the app for error handling

---

### `lib/core/utils/expiry_insights.dart`

**Purpose:** Expiry date analysis and insights

**Key Components:**
- `ExpiryInsights` class
- `getExpiryStatus()` - Determines expiry status
- `getDaysUntilExpiry()` - Calculates days remaining

**How it Works:**
1. Calculates days until expiry
2. Returns expiry status (expired, expiring soon, good)
3. Provides insights about expiry dates
4. Used for color coding and notifications

**Status Colors:**
- Red: Expired
- Orange: Expiring within 7 days
- Green: Good

---

## Data Layer

### `lib/data/database/app_database.dart`

**Purpose:** Drift database schema definition

**Key Components:**
- `AppDatabase` class - Drift database
- `Products` table - Product data
- `Medicines` table - Medicine data
- `Inventory` table - Inventory data
- Database migrations

**How it Works:**
1. Defines database schema using Drift ORM
2. Creates tables with columns
3. Sets up relationships
4. Handles migrations
5. Generated file: `app_database.g.dart` (auto-generated)

**Tables:**
- Products: id, name, brand, category, expiry_date, mfg_date, etc.
- Medicines: id, name, dosage, manufacturer, etc.
- Inventory: id, product_id, quantity, location, etc.

---

### `lib/data/database/database_service.dart`

**Purpose:** Database service for inventory management

**Key Components:**
- `DatabaseService` class (data layer)
- Inventory-specific database operations
- CRUD operations for inventory

**How it Works:**
1. Provides database access for inventory features
2. Manages inventory table operations
3. Queries for stock levels
4. Used by inventory screens

---

### `lib/data/database/tables/products_table.dart`

**Purpose:** Products table definition

**Key Components:**
- `Products` class - Table definition
- Column definitions

**How it Works:**
1. Defines products table schema
2. Columns: id, name, brand, category, expiry_date, mfg_date, notes, image_path, is_medicine, created_at, updated_at

---

### `lib/data/database/tables/medicines_table.dart`

**Purpose:** Medicines table definition

**Key Components:**
- `Medicines` class - Table definition
- Medicine-specific columns

**How it Works:**
1. Defines medicines table schema
2. Columns: id, name, dosage, manufacturer, composition, uses, warnings, expiry_date, batch_number

---

### `lib/data/database/tables/inventory_table.dart`

**Purpose:** Inventory table definition

**Key Components:**
- `Inventory` class - Table definition
- Inventory-specific columns

**How it Works:**
1. Defines inventory table schema
2. Columns: id, product_id, quantity, location, added_date, last_updated

---

### `lib/data/repositories/product_repository.dart`

**Purpose:** Repository for product data access

**Key Components:**
- `ProductRepository` class
- CRUD operations for products
- Query methods (by expiry, by category)

**How it Works:**
1. Abstracts database access
2. Provides business logic layer
3. Methods: add, update, delete, getAll, getById, getExpired, getExpiringSoon
4. Used by UI layer for data operations

---

### `lib/data/repositories/medicine_repository.dart`

**Purpose:** Repository for medicine data access

**Key Components:**
- `MedicineRepository` class
- Medicine-specific operations
- Search by name, dosage, manufacturer

**How it Works:**
1. Abstracts medicine database access
2. Provides medicine-specific queries
3. Methods: add, update, delete, search, getByManufacturer
4. Used by medicine screens

---

### `lib/data/repositories/inventory_repository.dart`

**Purpose:** Repository for inventory data access

**Key Components:**
- `InventoryRepository` class
- Inventory operations
- Stock level queries

**How it Works:**
1. Abstracts inventory database access
2. Provides inventory-specific operations
3. Methods: add, update, delete, getLowStock, getAll
4. Used by inventory screens

---

## Features - Common

### `lib/features/common/barcode_scanner_screen.dart`

**Purpose:** Barcode scanning screen using mobile_scanner

**Key Components:**
- `BarcodeScannerScreen` widget
- `MobileScannerController` - Camera controller
- Barcode format detection
- Manual barcode entry dialog

**How it Works:**
1. Opens camera using mobile_scanner package
2. Enables multiple barcode formats (EAN-13, EAN-8, UPC-A, UPC-E, Code 128, etc.)
3. Detects barcodes in real-time
4. Returns detected barcode to caller
5. Provides manual barcode entry as fallback
6. Visual overlay for scanning guidance

---

### `lib/features/common/image_capture_screen_real_ocr.dart`

**Purpose:** Image capture and OCR analysis screen

**Key Components:**
- `ImageCaptureScreenRealOCR` widget
- Camera/gallery integration
- OCR processing with RobustOCRService
- Analysis results display

**How it Works:**
1. User captures or selects image
2. Shows image preview
3. Calls MultiImageServiceSimple for OCR analysis
4. Displays extracted text and parsed data
5. Shows confidence scores
6. "Edit & Save" button to proceed to form
7. Auto-fills form with AI-extracted data

---

### `lib/features/common/image_capture_screen_simple.dart`

**Purpose:** Simplified image capture screen

**Key Components:**
- `ImageCaptureScreenSimple` widget
- Basic image capture
- Simple OCR processing

**How it Works:**
1. Simplified version of image capture
2. Basic camera/gallery integration
3. Simple OCR processing
4. Used for simple image capture needs

---

### `lib/features/common/image_capture_screen_fixed.dart`

**Purpose**: Fixed version of image capture screen

**Key Components:**
- `ImageCaptureScreenFixed` widget
- Bug fixes and improvements

**How it Works:**
1. Fixed version of image capture
2. Resolves issues from original version
3. Improved stability

---

## Features - Auth

### `lib/features/auth/lock_screen.dart`

**Purpose:** Lock screen with biometric authentication

**Key Components:**
- `LockScreen` widget
- Biometric authentication
- PIN entry (fallback)

**How it Works:**
1. Shows lock screen on app launch
2. Attempts biometric authentication first
3. Falls back to PIN if biometrics fail/unavailable
4. Unlocks app on successful authentication
5. Used for app security

---

## Features - Product

### `lib/features/product/product_entry_method_screen.dart`

**Purpose:** Selection screen for product entry method

**Key Components:**
- `ProductEntryMethodScreen` widget
- Options: Barcode scan, Image capture, Manual entry
- Navigation to respective screens

**How it Works:**
1. Shows 3 options for adding products:
   - Scan Barcode
   - Capture Image
   - Manual Entry
2. User selects method
3. Navigates to appropriate screen
4. Handles barcode lookup with fallback to image capture

---

### `lib/features/product/manual_product_entry_screen.dart`

**Purpose:** Manual product entry form with AI auto-fill

**Key Components:**
- `ManualProductEntryScreen` widget
- Form fields: name, brand, category, expiry, mfg, ingredients, notes
- AI-powered form population
- Image attachment

**How it Works:**
1. Accepts optional analysisData from OCR
2. Populates form with AI-extracted data
3. Prioritizes AI vision data over regex extraction
4. User can edit all fields
5. Date pickers for expiry and mfg dates
6. Saves to database via ProductRepository
7. Shows logs to track data source (AI vs regex)

---

### `lib/features/product/product_form_screen_new.dart`

**Purpose:** Product form with pre-filled data from barcode/OCR

**Key Components:**
- `ProductFormScreenNew` widget
- Pre-filled form from barcode lookup or OCR
- Form validation
- Save to database

**How it Works:**
1. Accepts pre-filled data from barcode/OCR
2. Shows form with data auto-populated
3. User reviews and edits
4. Validates form fields
5. Saves to database
6. Returns to home screen

---

### `lib/features/product/product_list_screen.dart`

**Purpose:** List all products with expiry status

**Key Components:**
- `ProductListScreen` widget
- Product list with color coding
- Filter and search
- Swipe actions (edit, delete)

**How it Works:**
1. Fetches all products from database
2. Displays in list with expiry status
3. Color coding: Red (expired), Orange (expiring soon), Green (good)
4. Search by name/brand
5. Filter by category
6. Swipe to edit/delete

---

### `lib/features/product/product_scanner_screen.dart`

**Purpose:** Product scanning screen with OCR

**Key Components:**
- `ProductScannerScreen` widget
- Camera integration
- Real-time OCR
- Product detection

**How it Works:**
1. Opens camera
2. Real-time OCR using ML Kit
3. Detects product labels
4. Extracts product information
5. Navigates to form with extracted data

---

### `lib/features/product/add_product_screen.dart`

**Purpose:** Add new product screen

**Key Components:**
- `AddProductScreen` widget
- Product entry form
- Save to database

**How it Works:**
1. Shows empty product form
2. User enters product details
3. Validates inputs
4. Saves to database
5. Returns to list

---

## Features - Medicine

### `lib/features/medicine/medicine_screen.dart`

**Purpose:** Medicine management screen

**Key Components:**
- `MedicineScreen` widget
- Medicine list
- Medicine-specific fields (dosage, composition, uses, warnings)

**How it Works:**
1. Fetches all medicines from database
2. Displays medicine list with expiry status
3. Shows medicine-specific information
4. Navigate to add/edit medicine

---

### `lib/features/medicine/medicine_list_screen.dart`

**Purpose:** List all medicines

**Key Components:**
- `MedicineListScreen` widget
- Medicine list view
- Filter and search

**How it Works:**
1. Fetches medicines from MedicineRepository
2. Displays in list view
3. Search by name/manufacturer
4. Filter by dosage
5. Tap to view details

---

### `lib/features/medicine/medicine_search_screen.dart`

**Purpose:** Search medicines

**Key Components:**
- `MedicineSearchScreen` widget
- Search functionality
- Search results

**How it Works:**
1. Search bar input
2. Queries medicine database
3. Displays matching results
4. Tap to view details

---

### `lib/features/medicine/manual_medicine_entry_screen.dart`

**Purpose:** Manual medicine entry form

**Key Components:**
- `ManualMedicineEntryScreen` widget
- Medicine-specific fields (dosage, composition, uses, warnings, batch number)
- Form validation

**How it Works:**
1. Shows medicine entry form
2. Fields: name, dosage, manufacturer, composition, uses, warnings, expiry, batch
3. Validates inputs
4. Saves to medicines table
5. Returns to medicine list

---

### `lib/features/medicine/preview_screen.dart`

**Purpose:** Preview medicine details before saving

**Key Components:**
- `PreviewScreen` widget
- Display extracted data
- Confirm or edit before save

**How it Works:**
1. Shows preview of medicine data
2. User reviews extracted information
3. Can edit if needed
4. Confirms to save or cancel

---

## Features - Inventory

### `lib/features/inventory/inventory_screen.dart`

**Purpose:** Inventory management screen

**Key Components:**
- `InventoryScreen` widget
- Inventory list
- Stock levels
- Add/edit inventory

**How it Works:**
1. Fetches inventory from database
2. Displays stock levels
3. Low stock indicators
4. Navigate to add/edit inventory

---

### `lib/features/inventory/add_inventory_screen.dart`

**Purpose:** Add inventory item

**Key Components:**
- `AddInventoryScreen` widget
- Inventory entry form
- Product selection
- Quantity input

**How it Works:**
1. Shows inventory entry form
2. Select product from list
3. Enter quantity and location
4. Saves to inventory table
5. Returns to inventory list

---

### `lib/features/inventory/enhanced_inventory_screen.dart`

**Purpose:** Enhanced inventory screen with more features

**Key Components:**
- `EnhancedInventoryScreen` widget
- Advanced inventory features
- Analytics and reports

**How it Works:**
1. Enhanced version of inventory screen
2. Additional features like:
   - Stock trends
   - Low stock alerts
   - Inventory analytics

---

### `lib/features/inventory/inventory_screen_new.dart`

**Purpose:** New version of inventory screen

**Key Components:**
- `InventoryScreenNew` widget
- Redesigned UI
- Improved functionality

**How it Works:**
1. New version with improved UI
2. Better organization
3. Enhanced features

---

## Features - Batch

### `lib/features/batch/batch_processing_screen.dart`

**Purpose:** Batch process multiple products/images

**Key Components:**
- `BatchProcessingScreen` widget
- Multi-image selection
- Progress tracking
- Results display

**How it Works:**
1. User selects multiple images/products
2. Processes them in batch
3. Shows progress for each item
4. Displays results when complete
5. Uses BatchProcessingService

---

### `lib/features/batch/batch_processing_screen_simple.dart`

**Purpose:** Simplified batch processing screen

**Key Components:**
- `BatchProcessingScreenSimple` widget
- Simplified batch processing
- Basic features

**How it Works:**
1. Simplified version of batch processing
2. Basic multi-image processing
3. Simple progress display

---

## Features - Analytics

### `lib/features/analytics/analytics_screen.dart`

**Purpose:** Analytics and insights screen

**Key Components:**
- `AnalyticsScreen` widget
- Charts and graphs
- Product statistics
- Expiry trends

**How it Works:**
1. Fetches analytics data
2. Displays charts:
   - Products by category
   - Expiry timeline
   - Monthly additions
3. Shows insights and trends

---

### `lib/features/analytics/analytics_screen_new.dart`

**Purpose:** New version of analytics screen

**Key Components:**
- `AnalyticsScreenNew` widget
- Improved analytics
- Better visualizations

**How it Works:**
1. New version with improved UI
2. Better charts
3. More insights

---

## Features - Dashboard

### `lib/features/dashboard/dashboard_screen.dart`

**Purpose:** Main dashboard screen

**Key Components:**
- `DashboardScreen` widget
- Overview cards
- Quick actions
- Recent products

**How it Works:**
1. Shows dashboard with:
   - Total products
   - Expired products
   - Expiring soon
   - Recent additions
2. Quick action buttons
3. Recent products list

---

### `lib/features/dashboard/dashboard_stats.dart`

**Purpose:** Dashboard statistics widget

**Key Components:**
- `DashboardStats` widget
- Statistics cards
- Data visualization

**How it Works:**
1. Calculates statistics
2. Displays in card format
3. Shows counts and percentages
4. Used by DashboardScreen

---

### `lib/features/dashboard/expiry_summary_widget.dart`

**Purpose:** Expiry summary widget

**Key Components:**
- `ExpirySummaryWidget` widget
- Expiry breakdown
- Visual summary

**How it Works:**
1. Shows expiry summary
2. Breakdown by status
3. Visual indicators
4. Used in dashboard

---

## Features - Home

### `lib/features/home/home_screen_clean.dart`

**Purpose:** Clean version of home screen

**Key Components:**
- `HomeScreenClean` widget
- Product list
- Clean UI design

**How it Works:**
1. Shows all products in clean list
2. Expiry status indicators
3. Search and filter
4. Add product button

---

## Features - Expiry

### `lib/features/expiry/expiry_checker.dart`

**Purpose:** Check expiry dates and calculate status

**Key Components:**
- `ExpiryChecker` class
- `checkExpiry()` - Check expiry status
- `getDaysRemaining()` - Calculate days remaining

**How it Works:**
1. Accepts expiry date
2. Calculates days until expiry
3. Returns status (expired, expiring soon, good)
4. Used for color coding and notifications

---

## Features - Expiry Timeline

### `lib/features/expiry_timeline/expiry_timeline_screen.dart`

**Purpose:** Timeline view of expiry dates

**Key Components:**
- `ExpiryTimelineScreen` widget
- Timeline visualization
- Expiry events

**How it Works:**
1. Shows timeline of expiry dates
2. Visual representation
3. Navigate to product details
4. Filter by date range

---

## Services

### `lib/services/multi_image_service_simple.dart`

**Purpose:** Multi-image processing service

**Key Components:**
- `MultiImageServiceSimple` class
- `processMultipleImages()` - Process multiple images
- Robust OCR pipeline integration

**How it Works:**
1. Accepts list of images
2. Validates each image
3. Processes through RobustOCRService
4. Merges results from multiple images
5. Returns combined analysis
6. Used by ImageCaptureScreenRealOCR

---

## Models

### `lib/models/product_info.dart`

**Purpose:** Product model/data class

**Key Components:**
- `ProductInfo` class
- Product fields and properties
- Serialization methods

**How it Works:**
1. Defines product data structure
2. Fields: name, brand, category, expiry, mfg, ingredients, notes
3. JSON serialization
4. Used throughout app for product data

---

## Widgets

### `lib/widgets/biometric_protected_widget.dart`

**Purpose:** Widget that requires biometric authentication

**Key Components:**
- `BiometricProtectedWidget` widget
- Biometric check before access
- Child widget protection

**How it Works:**
1. Wraps child widget
2. Requires biometric authentication
3. Shows child only after auth
4. Used for sensitive screens

---

## Main Entry Point

### `lib/main.dart`

**Purpose:** Application entry point

**Key Components:**
- `main()` function
- `MyApp` widget
- Service initialization
- Route configuration

**How it Works:**
1. Initializes services (SimpleServiceManager)
2. Sets up theme
3. Configures routes
4. Runs the app
5. Sets up error handling

---

## Configuration Files

### `pubspec.yaml`

**Purpose:** Flutter project dependencies and configuration

**Key Dependencies:**
- `drift` - Database ORM
- `mobile_scanner` - Barcode scanning
- `google_mlkit_text_recognition` - OCR
- `image_picker` - Image capture
- `flutter_local_notifications` - Notifications
- `http` - HTTP requests
- `local_auth` - Biometric authentication

---

## Summary

The Expiry Tracker App is organized into:
- **Core Services:** AI, OCR, barcode, database, configuration
- **Core Utilities:** UI helpers, error handling, expiry insights
- **Data Layer:** Database schema, repositories
- **Features:** Organized by functionality (product, medicine, inventory, etc.)
- **Services:** Multi-image processing
- **Models:** Data classes
- **Widgets:** Reusable UI components

The app follows a layered architecture with clear separation of concerns, making it maintainable and scalable.
