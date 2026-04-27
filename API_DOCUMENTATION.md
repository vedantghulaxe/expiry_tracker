# API Documentation - Expiry Tracker App

## Table of Contents
1. [External APIs](#external-apis)
2. [Internal APIs](#internal-apis)
3. [API Integration Flow](#api-integration-flow)
4. [Error Handling](#error-handling)
5. [Rate Limiting](#rate-limiting)
6. [Authentication](#authentication)

---

## External APIs

### 1. Open Food Facts API

#### Overview
- **Purpose**: Food product database
- **Base URL**: `https://world.openfoodfacts.org/api/v0/product/`
- **Authentication**: None (free)
- **Rate Limit**: None specified
- **Format**: JSON

#### Endpoints

##### Get Product by Barcode
```http
GET /api/v0/product/{barcode}.json
```

**Parameters**:
- `barcode` (string): Product barcode (8-13 digits)

**Example Request**:
```bash
curl "https://world.openfoodfacts.org/api/v0/product/8901063029415.json"
```

**Example Response**:
```json
{
  "status": 1,
  "product": {
    "product_name": "Product Name",
    "brands": "Brand Name",
    "categories": "Food, Beverages",
    "ingredients_text": "Ingredients list",
    "quantity": "500g",
    "image_url": "https://images.openfoodfacts.org/...",
    "nutriments": {
      "energy_100g": 250,
      "proteins_100g": 10,
      "carbohydrates_100g": 30,
      "fat_100g": 5
    }
  }
}
```

**Usage in App**:
```dart
static Future<Map<String, dynamic>> fetchFromOpenFoodFacts(String barcode) async {
  final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';
  final response = await http.get(
    Uri.parse(url),
    headers: {'User-Agent': 'ExpiryTrackerApp/1.0'},
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == 1 && data['product'] != null) {
      return {
        'success': true,
        'name': data['product']['product_name'] ?? 'Unknown Product',
        'brand': data['product']['brands'] ?? '',
        'category': data['product']['categories'] ?? 'product',
        'ingredients': data['product']['ingredients_text'] ?? '',
        'quantity': data['product']['quantity'] ?? '',
        'source': 'Open Food Facts',
      };
    }
  }
  return {};
}
```

---

### 2. FDA Drug Database API

#### Overview
- **Purpose**: FDA drug information database
- **Base URL**: `https://api.fda.gov/drug/label.json`
- **Authentication**: None (free)
- **Rate Limit**: None specified
- **Format**: JSON

#### Endpoints

##### Search Drugs by NDC Code
```http
GET /drug/label.json?search=openfda.product_ndc:{ndc_code}
```

##### Search Drugs by Brand Name
```http
GET /drug/label.json?search=openfda.brand_name:{brand_name}
```

##### Search Drugs by Generic Name
```http
GET /drug/label.json?search=openfda.generic_name:{generic_name}
```

**Parameters**:
- `ndc_code` (string): National Drug Code
- `brand_name` (string): Drug brand name
- `generic_name` (string): Generic drug name

**Example Request**:
```bash
curl "https://api.fda.gov/drug/label.json?search=openfda.brand_name:aspirin"
```

**Example Response**:
```json
{
  "meta": {
    "results": {
      "total": 1,
      "skip": 0,
      "limit": 1
    }
  },
  "results": [
    {
      "openfda": {
        "brand_name": ["Aspirin"],
        "generic_name": ["Aspirin"],
        "manufacturer_name": ["Bayer HealthCare"],
        "product_ndc": ["00128-001"]
      },
      "purpose": ["Pain reliever"],
      "indications_and_usage": ["For temporary relief of minor aches and pains"],
      "dosage_and_administration": ["Take 1 tablet every 4-6 hours"],
      "warnings": ["Do not use if allergic to aspirin"]
    }
  ]
}
```

**Usage in App**:
```dart
static Future<Map<String, dynamic>> fetchFromFDA(String searchTerm) async {
  List<String> searchUrls = [
    'https://api.fda.gov/drug/label.json?search=openfda.product_ndc:$searchTerm',
    'https://api.fda.gov/drug/label.json?search=openfda.brand_name:$searchTerm',
    'https://api.fda.gov/drug/label.json?search=openfda.generic_name:$searchTerm',
  ];
  
  for (String url in searchUrls) {
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meta']['results']['total'] > 0 && data['results'] != null) {
        final drug = data['results'][0];
        
        return {
          'success': true,
          'name': drug['openfda']['brand_name']?[0] ?? 'Unknown Medicine',
          'brand': drug['openfda']['manufacturer_name']?[0] ?? '',
          'category': 'medicine',
          'ingredients': drug['purpose']?.join(', ') ?? '',
          'dosage': drug['dosage_and_administration'] ?? '',
          'uses': drug['indications_and_usage'] ?? '',
          'warnings': drug['warnings']?.join(', ') ?? '',
          'isMedicine': true,
          'source': 'FDA Drug Database',
        };
      }
    }
  }
  return {};
}
```

---

### 3. UPCItemDB API

#### Overview
- **Purpose**: Universal product database
- **Base URL**: `https://api.upcitemdb.com/prod/trial/lookup`
- **Authentication**: None (free trial)
- **Rate Limit**: Limited for trial
- **Format**: JSON

#### Endpoints

##### Lookup Product by UPC
```http
GET /prod/trial/lookup?upc={upc_code}
```

**Parameters**:
- `upc_code` (string): UPC barcode (8-13 digits)

**Example Request**:
```bash
curl "https://api.upcitemdb.com/prod/trial/lookup?upc=8901063029415"
```

**Example Response**:
```json
{
  "code": "OK",
  "total": 1,
  "offset": 0,
  "items": [
    {
      "upc": "8901063029415",
      "title": "Product Title",
      "brand": "Brand Name",
      "category": "Category",
      "description": "Product description",
      "image": "https://images.upcitemdb.com/...",
      "lowest_recorded_price": 9.99,
      "highest_recorded_price": 15.99
    }
  ]
}
```

**Usage in App**:
```dart
static Future<Map<String, dynamic>> fetchFromUPCItemDB(String barcode) async {
  final url = 'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode';
  final response = await http.get(
    Uri.parse(url),
    headers: {'User-Agent': 'ExpiryTrackerApp/1.0'},
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['items'] != null && data['items'].isNotEmpty) {
      final item = data['items'][0];
      
      return {
        'success': true,
        'name': item['title'] ?? 'Unknown Product',
        'brand': item['brand'] ?? '',
        'category': item['category'] ?? 'product',
        'ingredients': item['description'] ?? '',
        'source': 'UPCItemDB',
      };
    }
  }
  return {};
}
```

---

### 4. Online OCR API

#### Overview
- **Purpose**: Cloud-based text extraction
- **Base URL**: Various (OCR.space, Google Vision, etc.)
- **Authentication**: API Key required
- **Rate Limit**: Depends on service
- **Format**: JSON

#### OCR.space API

##### Extract Text from Image
```http
POST /parse/image
```

**Headers**:
- `apikey`: Your API key
- `Content-Type`: application/x-www-form-urlencoded

**Parameters**:
- `base64Image`: Base64 encoded image
- `language`: Language code (e.g., 'eng')
- `isOverlayRequired`: Boolean for overlay
- `detectOrientation`: Boolean for orientation detection

**Example Request**:
```bash
curl -X POST "https://api.ocr.space/parse/image" \
  -H "apikey: YOUR_API_KEY" \
  -d "base64Image=iVBORw0KGgoAAAANSUhEUgAA..." \
  -d "language=eng"
```

**Example Response**:
```json
{
  "OCRExitCode": 1,
  "IsErroredOnProcessing": false,
  "ErrorMessage": "",
  "ProcessingTimeInMilliseconds": 1234,
  "ParsedResults": [
    {
      "TextOverlay": "",
      "Text": "Extracted text content",
      "FileParseExitCode": 1,
      "ParsedText": "Clean extracted text",
      "ErrorMessage": "",
      "ErrorDetails": ""
    }
  ]
}
```

**Usage in App**:
```dart
static Future<OCRResult> extractTextOnline(String imageBase64) async {
  final response = await http.post(
    Uri.parse('https://api.ocr.space/parse/image'),
    headers: {'apikey': 'YOUR_API_KEY'},
    body: {
      'base64Image': imageBase64,
      'language': 'eng',
      'detectOrientation': 'true',
    },
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['OCRExitCode'] == 1 && data['ParsedResults'] != null) {
      final parsedResult = data['ParsedResults'][0];
      
      return OCRResult(
        text: parsedResult['ParsedText'] ?? '',
        confidence: 0.85, // OCR.space doesn't provide confidence
        method: 'online',
        warning: data['ErrorMessage'],
      );
    }
  }
  
  return OCRResult.empty();
}
```

---

## Internal APIs

### 1. Backend FastAPI

#### Overview
- **Purpose**: Backend data processing and storage
- **Base URL**: `http://localhost:8000`
- **Authentication**: None (local)
- **Format**: JSON

#### Endpoints

##### Health Check
```http
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

##### Upload Image for OCR
```http
POST /ocr/extract
```

**Headers**:
- `Content-Type`: multipart/form-data

**Parameters**:
- `file`: Image file

**Response**:
```json
{
  "success": true,
  "text": "Extracted text",
  "confidence": 0.92,
  "processing_time": 1.23
}
```

##### Save Product
```http
POST /products
```

**Headers**:
- `Content-Type`: application/json

**Body**:
```json
{
  "name": "Product Name",
  "brand": "Brand",
  "category": "product",
  "expiry_date": "2024-12-31",
  "manufacturing_date": "2024-01-01",
  "batch_number": "BATCH123",
  "ingredients": "Ingredients list",
  "notes": "Additional notes"
}
```

**Response**:
```json
{
  "success": true,
  "product_id": 123,
  "message": "Product saved successfully"
}
```

##### Get Products
```http
GET /products
```

**Query Parameters**:
- `category`: Filter by category
- `limit`: Number of results
- `offset`: Pagination offset

**Response**:
```json
{
  "success": true,
  "products": [
    {
      "id": 1,
      "name": "Product Name",
      "brand": "Brand",
      "category": "product",
      "expiry_date": "2024-12-31",
      "created_at": "2024-01-01T12:00:00Z"
    }
  ],
  "total": 1
}
```

---

## API Integration Flow

### 1. OCR Processing Flow
```
1. User captures image
2. Image preprocessing (resize, compress)
3. Local OCR (Google ML Kit) - First attempt
4. If confidence < 0.7, try online OCR
5. Parse extracted text with AI
6. Look for barcodes in text
7. If barcode found, fetch product info
8. Merge OCR + API data
9. Return enhanced result
```

### 2. Barcode Processing Flow
```
1. User scans barcode
2. Validate barcode format
3. Try Open Food Facts API
4. If not found, try UPCItemDB
5. If not found, try FDA Database
6. Return product information or fallback
```

### 3. Product Registration Flow
```
1. Extract data from image/barcode
2. Enhance with API data
3. User reviews and edits
4. Validate form data
5. Save to local database
6. Optional: Sync to backend
```

---

## Error Handling

### 1. HTTP Error Codes
- `200`: Success
- `400`: Bad Request
- `401`: Unauthorized
- `404`: Not Found
- `429`: Too Many Requests
- `500`: Internal Server Error

### 2. API Error Responses
```json
{
  "success": false,
  "error": "Error message",
  "error_code": "API_ERROR_CODE",
  "retry_after": 60
}
```

### 3. Fallback Strategies
- **API Failure**: Use local OCR only
- **OCR Failure**: Manual entry option
- **Network Error**: Offline mode
- **Rate Limit**: Queue requests

---

## Rate Limiting

### 1. Implementation
```dart
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final int maxRequests;
  final Duration window;
  
  bool canMakeRequest(String endpoint) {
    final now = DateTime.now();
    final requests = _requests[endpoint] ?? [];
    
    // Remove old requests
    requests.removeWhere((time) => now.difference(time) > window);
    
    return requests.length < maxRequests;
  }
  
  void recordRequest(String endpoint) {
    final requests = _requests[endpoint] ?? [];
    requests.add(DateTime.now());
    _requests[endpoint] = requests;
  }
}
```

### 2. API Limits
- **Open Food Facts**: No official limit
- **FDA Database**: No official limit
- **UPCItemDB**: Limited for trial
- **OCR APIs**: Varies by provider

### 3. Retry Logic
```dart
Future<T> withRetry<T>(
  Future<T> Function() operation,
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
) async {
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await operation();
    } catch (e) {
      if (attempt == maxRetries - 1) rethrow;
      
      await Future.delayed(delay * (attempt + 1));
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

---

## Authentication

### 1. API Keys
```dart
class ApiConfig {
  static const String ocrApiKey = String.fromEnvironment('OCR_API_KEY');
  static const String barcodeSpiderApiKey = String.fromEnvironment('BARCODE_SPIDER_API_KEY');
}
```

### 2. Headers
```dart
Map<String, String> getApiHeaders() {
  return {
    'Content-Type': 'application/json',
    'User-Agent': 'ExpiryTrackerApp/1.0',
    'Accept': 'application/json',
  };
}
```

### 3. Security
- Store API keys in environment variables
- Use HTTPS for all API calls
- Implement request signing if required
- Rotate API keys regularly

---

## Testing APIs

### 1. Mock Services
```dart
class MockApiService {
  static Future<Map<String, dynamic>> fetchProductInfo(String barcode) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network
    
    return {
      'success': true,
      'name': 'Mock Product',
      'brand': 'Mock Brand',
      'category': 'mock',
      'source': 'Mock API',
    };
  }
}
```

### 2. Test Data
```dart
const Map<String, Map<String, dynamic>> testProducts = {
  '8901063029415': {
    'name': 'Test Product',
    'brand': 'Test Brand',
    'category': 'test',
  },
  '1234567890123': {
    'name': 'Another Test',
    'brand': 'Another Brand',
    'category': 'test',
  },
};
```

### 3. Integration Tests
```dart
test('Open Food Facts API integration', () async {
  final result = await ProductApiService.fetchFromOpenFoodFacts('8901063029415');
  expect(result['success'], isTrue);
  expect(result['name'], isNotEmpty);
});
```

---

This API documentation provides comprehensive information about all external and internal APIs used in the Expiry Tracker App, including implementation details, error handling, and best practices.
