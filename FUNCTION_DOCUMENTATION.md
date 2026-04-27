# Function Documentation - Expiry Tracker App

## Table of Contents
1. [Core Services Functions](#core-services-functions)
2. [UI Component Functions](#ui-component-functions)
3. [Data Processing Functions](#data-processing-functions)
4. [API Integration Functions](#api-integration-functions)
5. [Utility Functions](#utility-functions)

---

## Core Services Functions

### OCRService (`lib/core/services/ocr_service.dart`)

#### `extractTextFromImage(File image)`
**Purpose**: Extract text from a single image file
**Parameters**: 
- `image` (File): Image file to process
**Returns**: `Future<OCRResult>` - Text extraction result with confidence
**Tech Stack**: Google ML Kit, Tesseract OCR
**Example**:
```dart
final result = await OCRService.extractTextFromImage(imageFile);
print('Extracted: ${result.text}');
print('Confidence: ${result.confidence}');
```

#### `extractTextFromMultipleImages(List<File> images)`
**Purpose**: Extract text from multiple images and combine results
**Parameters**: 
- `images` (List<File>): List of image files
**Returns**: `Future<OCRResult>` - Combined extraction result
**Tech Stack**: Google ML Kit, Text aggregation
**Example**:
```dart
final result = await OCRService.extractTextFromMultipleImages(imageFiles);
print('Combined text: ${result.text}');
```

#### `extractTextOnline(String imageBase64)`
**Purpose**: Extract text using online OCR service
**Parameters**: 
- `imageBase64` (String): Base64 encoded image
**Returns**: `Future<OCRResult>` - Online extraction result
**Tech Stack**: OCR.space API, HTTP requests
**Example**:
```dart
final result = await OCRService.extractTextOnline(base64Image);
print('Online extraction: ${result.text}');
```

---

### LocalParserService (`lib/core/services/local_parser_service.dart`)

#### `parseOCRText(String text)`
**Purpose**: Parse OCR text into structured product data
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `Map<String, dynamic>` - Structured product data
**Tech Stack**: Dart, Regular Expressions, Heuristics
**Example**:
```dart
final parsed = await LocalParserService.parseOCRText(ocrText);
print('Product: ${parsed['name']}');
print('Brand: ${parsed['brand']}');
```

#### `_extractSimpleProductName(String text)`
**Purpose**: Extract product name from text using AI patterns
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `String` - Extracted product name
**Tech Stack**: Pattern matching, AI logic
**Example**:
```dart
final name = LocalParserService._extractSimpleProductName(text);
print('Product name: $name');
```

#### `_extractSimpleBrand(String text)`
**Purpose**: Extract brand/manufacturer from text
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `String` - Extracted brand name
**Tech Stack**: Company pattern recognition
**Example**:
```dart
final brand = LocalParserService._extractSimpleBrand(text);
print('Brand: $brand');
```

#### `_extractSimpleDate(String text, String dateType)`
**Purpose**: Extract dates (expiry/manufacturing) from text
**Parameters**: 
- `text` (String): Raw OCR text
- `dateType` (String): 'exp' or 'mfg'
**Returns**: `String` - Extracted date
**Tech Stack**: Date pattern recognition
**Example**:
```dart
final expiryDate = LocalParserService._extractSimpleDate(text, 'exp');
print('Expiry: $expiryDate');
```

#### `_extractSimpleBatch(String text)`
**Purpose**: Extract batch number from text
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `String` - Extracted batch number
**Tech Stack**: Alphanumeric pattern matching
**Example**:
```dart
final batch = LocalParserService._extractSimpleBatch(text);
print('Batch: $batch');
```

#### `_isMedicineContent(String text)`
**Purpose**: Classify if content is medicine-related
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `bool` - True if medicine detected
**Tech Stack**: Keyword detection, classification
**Example**:
```dart
final isMedicine = LocalParserService._isMedicineContent(text);
print('Is medicine: $isMedicine');
```

---

### ProductApiService (`lib/core/services/product_api_service.dart`)

#### `fetchFromOpenFoodFacts(String barcode)`
**Purpose**: Fetch product info from Open Food Facts API
**Parameters**: 
- `barcode` (String): Product barcode
**Returns**: `Future<Map<String, dynamic>>` - Product information
**Tech Stack**: HTTP, JSON, Open Food Facts API
**Example**:
```dart
final info = await ProductApiService.fetchFromOpenFoodFacts('8901063029415');
print('Product: ${info['name']}');
```

#### `fetchFromFDA(String searchTerm)`
**Purpose**: Fetch medicine info from FDA Database
**Parameters**: 
- `searchTerm` (String): Search term (NDC, brand, or generic name)
**Returns**: `Future<Map<String, dynamic>>` - Medicine information
**Tech Stack**: HTTP, JSON, FDA API
**Example**:
```dart
final info = await ProductApiService.fetchFromFDA('aspirin');
print('Medicine: ${info['name']}');
```

#### `fetchFromUPCItemDB(String barcode)`
**Purpose**: Fetch product info from UPCItemDB
**Parameters**: 
- `barcode` (String): Product barcode
**Returns**: `Future<Map<String, dynamic>>` - Product information
**Tech Stack**: HTTP, JSON, UPCItemDB API
**Example**:
```dart
final info = await ProductApiService.fetchFromUPCItemDB('8901063029415');
print('Product: ${info['name']}');
```

#### `smartProductLookup(String query)`
**Purpose**: Smart product lookup across multiple APIs
**Parameters**: 
- `query` (String): Barcode or product name
**Returns**: `Future<Map<String, dynamic>>` - Product information
**Tech Stack**: Multiple API integration
**Example**:
```dart
final info = await ProductApiService.smartProductLookup('8901063029415');
print('Product: ${info['name']}');
```

#### `enhanceOCRWithAPI(Map<String, dynamic> ocrResult, String? barcode)`
**Purpose**: Enhance OCR results with API data
**Parameters**: 
- `ocrResult` (Map): OCR extraction result
- `barcode` (String?): Optional barcode
**Returns**: `Future<Map<String, dynamic>>` - Enhanced result
**Tech Stack**: Data merging, API integration
**Example**:
```dart
final enhanced = await ProductApiService.enhanceOCRWithAPI(ocrData, barcode);
print('Enhanced data: ${enhanced['parsed_data']}');
```

---

### BarcodeService (`lib/core/services/barcode_service.dart`)

#### `scanBarcodeFromImage(String imagePath)`
**Purpose**: Scan barcode from image file
**Parameters**: 
- `imagePath` (String): Path to image file
**Returns**: `Future<String?>` - Barcode number or null
**Tech Stack**: Google ML Kit Barcode Scanning
**Example**:
```dart
final barcode = await BarcodeService.scanBarcodeFromImage(imagePath);
print('Barcode: $barcode');
```

#### `getProductInfo(String barcode)`
**Purpose**: Get product information from barcode
**Parameters**: 
- `barcode` (String): Barcode number
**Returns**: `Future<Map<String, dynamic>>` - Product information
**Tech Stack**: API integration, ProductApiService
**Example**:
```dart
final info = await BarcodeService.getProductInfo('8901063029415');
print('Product: ${info['name']}');
```

---

### DatabaseService (`lib/data/database/database_service.dart`)

#### `initDatabase()`
**Purpose**: Initialize SQLite database
**Parameters**: None
**Returns**: `Future<void>`
**Tech Stack**: SQLite, Dart
**Example**:
```dart
await DatabaseService.initDatabase();
print('Database initialized');
```

#### `insertProduct(Map<String, dynamic> product)`
**Purpose**: Insert new product into database
**Parameters**: 
- `product` (Map): Product data
**Returns**: `Future<int>` - Product ID
**Tech Stack**: SQLite, SQL
**Example**:
```dart
final id = await DatabaseService.insertProduct(productData);
print('Product ID: $id');
```

#### `getAllProducts()`
**Purpose**: Get all products from database
**Parameters**: None
**Returns**: `Future<List<Map<String, dynamic>>>` - Product list
**Tech Stack**: SQLite, SQL
**Example**:
```dart
final products = await DatabaseService.getAllProducts();
print('Found ${products.length} products');
```

#### `updateProduct(int id, Map<String, dynamic> product)`
**Purpose**: Update existing product
**Parameters**: 
- `id` (int): Product ID
- `product` (Map): Updated product data
**Returns**: `Future<void>`
**Tech Stack**: SQLite, SQL
**Example**:
```dart
await DatabaseService.updateProduct(productId, updatedData);
print('Product updated');
```

#### `deleteProduct(int id)`
**Purpose**: Delete product from database
**Parameters**: 
- `id` (int): Product ID
**Returns**: `Future<void>`
**Tech Stack**: SQLite, SQL
**Example**:
```dart
await DatabaseService.deleteProduct(productId);
print('Product deleted');
```

---

### LoggerService (`lib/core/services/logger_service.dart`)

#### `info(String tag, String message)`
**Purpose**: Log info message
**Parameters**: 
- `tag` (String): Log tag
- `message` (String): Log message
**Returns**: `void`
**Tech Stack**: Dart, Console output
**Example**:
```dart
LoggerService.info('OCR', 'Text extraction started');
```

#### `success(String tag, String message)`
**Purpose**: Log success message
**Parameters**: 
- `tag` (String): Log tag
- `message` (String): Log message
**Returns**: `void`
**Tech Stack**: Dart, Console output
**Example**:
```dart
LoggerService.success('API', 'Product data fetched successfully');
```

#### `error(String tag, String message)`
**Purpose**: Log error message
**Parameters**: 
- `tag` (String): Log tag
- `message` (String): Error message
**Returns**: `void`
**Tech Stack**: Dart, Console output
**Example**:
```dart
LoggerService.error('OCR', 'Text extraction failed: $e');
```

---

## UI Component Functions

### ImageCaptureScreenSimple (`lib/features/common/image_capture_screen_simple.dart`)

#### `_captureImage()`
**Purpose**: Capture image from device camera
**Parameters**: None
**Returns**: `Future<void>`
**Tech Stack**: Image Picker, Camera
**Example**:
```dart
await _captureImage(); // Opens camera
```

#### `_pickImage()`
**Purpose**: Pick image from device gallery
**Parameters**: None
**Returns**: `Future<void>`
**Tech Stack**: Image Picker, Gallery
**Example**:
```dart
await _pickImage(); // Opens gallery
```

#### `_scanBarcode()`
**Purpose**: Scan barcode using mobile scanner
**Parameters**: None
**Returns**: `Future<void>`
**Tech Stack**: Mobile Scanner, Camera
**Example**:
```dart
await _scanBarcode(); // Opens barcode scanner
```

#### `_processImages()`
**Purpose**: Process captured images for text extraction
**Parameters**: None
**Returns**: `Future<void>`
**Tech Stack**: MultiImageService, OCR
**Example**:
```dart
await _processImages(); // Extracts text from images
```

#### `_navigateToManualEntry()`
**Purpose**: Navigate to manual product entry screen
**Parameters**: None
**Returns**: `void`
**Tech Stack**: Flutter Navigation
**Example**:
```dart
_navigateToManualEntry(); // Opens manual entry screen
```

---

### ManualProductEntryScreen (`lib/features/product/manual_product_entry_screen.dart`)

#### `_populateFormFromAnalysisData()`
**Purpose**: Populate form with AI-extracted data
**Parameters**: None
**Returns**: `void`
**Tech Stack**: AI extraction, Form controllers
**Example**:
```dart
_populateFormFromAnalysisData(); // Fills form fields
```

#### `_aiExtractInformation(String rawText, Map<String, dynamic> parsedData)`
**Purpose**: AI-powered information extraction
**Parameters**: 
- `rawText` (String): Raw OCR text
- `parsedData` (Map): Parsed OCR data
**Returns**: `Map<String, dynamic>` - AI-extracted data
**Tech Stack**: AI patterns, Decision trees
**Example**:
```dart
final aiData = _aiExtractInformation(text, parsedData);
print('AI extracted: ${aiData['name']}');
```

#### `_saveProduct()`
**Purpose**: Save product to database
**Parameters**: None
**Returns**: `Future<void>`
**Tech Stack**: Form validation, Database
**Example**:
```dart
await _saveProduct(); // Saves to database
```

#### `_validateForm()`
**Purpose**: Validate form data
**Parameters**: None
**Returns**: `bool` - True if valid
**Tech Stack**: Form validation
**Example**:
```dart
final isValid = _validateForm();
if (isValid) await _saveProduct();
```

---

### DashboardScreen (`lib/features/dashboard/dashboard_screen.dart`)

#### `_refreshProducts()`
**Purpose**: Refresh product list
**Parameters**: None
**Returns**: `Future<void>`
**Tech Stack**: Database, State management
**Example**:
```dart
await _refreshProducts(); // Reloads products
```

#### `_navigateToAddProduct()`
**Purpose**: Navigate to add product screen
**Parameters**: None
**Returns**: `void`
**Tech Stack**: Flutter Navigation
**Example**:
```dart
_navigateToAddProduct(); // Opens add product screen
```

#### `_calculateExpiryStats()`
**Purpose**: Calculate expiry statistics
**Parameters**: None
**Returns**: `Map<String, int>` - Statistics
**Tech Stack**: Date calculations
**Example**:
```dart
final stats = _calculateExpiryStats();
print('Expired: ${stats['expired']}');
```

---

## Data Processing Functions

### MultiImageServiceSimple (`lib/services/multi_image_service_simple.dart`)

#### `processMultipleImages(List<File> images)`
**Purpose**: Process multiple images with robust pipeline
**Parameters**: 
- `images` (List<File>): Image files
**Returns**: `Future<Map<String, dynamic>>` - Processing result
**Tech Stack**: OCR, AI, API integration
**Example**:
```dart
final result = await MultiImageServiceSimple.processMultipleImages(images);
print('Success: ${result['success']}');
```

#### `captureMultipleImages()`
**Purpose**: Capture multiple images from camera
**Parameters**: None
**Returns**: `Future<List<File>>` - Captured images
**Tech Stack**: Image Picker, Camera
**Example**:
```dart
final images = await MultiImageServiceSimple.captureMultipleImages();
print('Captured ${images.length} images');
```

#### `_extractBarcodeFromText(String text)`
**Purpose**: Extract barcode from text
**Parameters**: 
- `text` (String): OCR text
**Returns**: `String?` - Barcode or null
**Tech Stack**: Regular expressions
**Example**:
```dart
final barcode = MultiImageServiceSimple._extractBarcodeFromText(text);
print('Barcode: $barcode');
```

---

### AIExtractionService (`lib/services/ai_extraction_service.dart`)

#### `extractInformation(String text)`
**Purpose**: AI-powered information extraction
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `Map<String, dynamic>` - Extracted information
**Tech Stack**: AI patterns, Machine learning
**Example**:
```dart
final info = await AIExtractionService.extractInformation(text);
print('Product: ${info['name']}');
```

#### `extractProductName(String text)`
**Purpose**: Smart product name extraction
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `String` - Product name
**Tech Stack**: AI pattern recognition
**Example**:
```dart
final name = AIExtractionService.extractProductName(text);
print('Name: $name');
```

#### `extractBrand(String text)`
**Purpose**: Intelligent brand detection
**Parameters**: 
- `text` (String): Raw OCR text
**Returns**: `String` - Brand name
**Tech Stack**: Company pattern AI
**Example**:
```dart
final brand = AIExtractionService.extractBrand(text);
print('Brand: $brand');
```

---

## API Integration Functions

### ProductRepository (`lib/data/repositories/product_repository.dart`)

#### `createProduct(Product product)`
**Purpose**: Create new product
**Parameters**: 
- `product` (Product): Product object
**Returns**: `Future<Product>` - Created product
**Tech Stack**: Repository pattern, Database
**Example**:
```dart
final created = await repository.createProduct(product);
print('Created: ${created.id}');
```

#### `getAllProducts()`
**Purpose**: Get all products
**Parameters**: None
**Returns**: `Future<List<Product>>` - Product list
**Tech Stack**: Repository pattern, Database
**Example**:
```dart
final products = await repository.getAllProducts();
print('Found ${products.length} products');
```

#### `searchProducts(String query)`
**Purpose**: Search products
**Parameters**: 
- `query` (String): Search query
**Returns**: `Future<List<Product>>` - Search results
**Tech Stack**: Repository pattern, Database
**Example**:
```dart
final results = await repository.searchProducts('medicine');
print('Found ${results.length} results');
```

---

## Utility Functions

### Date Parsing

#### `_parseDate(String dateString)`
**Purpose**: Parse date string to DateTime
**Parameters**: 
- `dateString` (String): Date string
**Returns**: `DateTime` - Parsed date
**Tech Stack**: Date parsing, Multiple formats
**Example**:
```dart
final date = _parseDate('12/2024');
print('Parsed: $date');
```

### Image Processing

#### `_preprocessImage(File image)`
**Purpose**: Preprocess image for OCR
**Parameters**: 
- `image` (File): Image file
**Returns**: `Future<File>` - Processed image
**Tech Stack**: Image processing, Compression
**Example**:
```dart
final processed = await _preprocessImage(imageFile);
print('Image processed');
```

### Validation

#### `_validateBarcode(String barcode)`
**Purpose**: Validate barcode format
**Parameters**: 
- `barcode` (String): Barcode string
**Returns**: `bool` - True if valid
**Tech Stack**: Regular expressions
**Example**:
```dart
final isValid = _validateBarcode('8901063029415');
print('Valid: $isValid');
```

#### `_validateEmail(String email)`
**Purpose**: Validate email format
**Parameters**: 
- `email` (String): Email string
**Returns**: `bool` - True if valid
**Tech Stack**: Regular expressions
**Example**:
```dart
final isValid = _validateEmail('user@example.com');
print('Valid: $isValid');
```

### File Operations

#### `_saveImageToStorage(File image)`
**Purpose**: Save image to local storage
**Parameters**: 
- `image` (File): Image file
**Returns**: `Future<String>` - File path
**Tech Stack**: File I/O, Path provider
**Example**:
```dart
final path = await _saveImageToStorage(imageFile);
print('Saved to: $path');
```

#### `_deleteImageFromStorage(String path)`
**Purpose**: Delete image from storage
**Parameters**: 
- `path` (String): File path
**Returns**: `Future<void>`
**Tech Stack**: File I/O
**Example**:
```dart
await _deleteImageFromStorage(imagePath);
print('Image deleted');
```

---

## Error Handling Functions

### `handleApiError(dynamic error)`
**Purpose**: Handle API errors gracefully
**Parameters**: 
- `error` (dynamic): Error object
**Returns**: `Map<String, dynamic>` - Error response
**Tech Stack**: Exception handling
**Example**:
```dart
final errorResponse = handleApiError(apiError);
print('Error: ${errorResponse['message']}');
```

### `createFallbackResult(String errorMessage)`
**Purpose**: Create fallback result on error
**Parameters**: 
- `errorMessage` (String): Error message
**Returns**: `Map<String, dynamic>` - Fallback result
**Tech Stack**: Error handling
**Example**:
```dart
final fallback = createFallbackResult('API failed');
print('Fallback: ${fallback['success']}');
```

---

## Performance Optimization Functions

### `compressImage(File image, {int quality = 80})`
**Purpose**: Compress image for better performance
**Parameters**: 
- `image` (File): Image file
- `quality` (int): Compression quality
**Returns**: `Future<File>` - Compressed image
**Tech Stack**: Image compression
**Example**:
```dart
final compressed = await compressImage(imageFile, quality: 70);
print('Image compressed');
```

### `cacheApiResponse(String key, dynamic data)`
**Purpose**: Cache API response
**Parameters**: 
- `key` (String): Cache key
- `data` (dynamic): Data to cache
**Returns**: `Future<void>`
**Tech Stack**: Caching, Memory management
**Example**:
```dart
await cacheApiResponse('product_123', productData);
print('Data cached');
```

---

This function documentation provides comprehensive details about all functions in the Expiry Tracker App, including their purposes, parameters, return types, tech stack usage, and practical examples.
