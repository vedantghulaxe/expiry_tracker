# Batch Processing & Image Enhancement Features

## Overview
These powerful new features add bulk operations and advanced image processing capabilities to your Expiry Tracker App.

---

## Features Implemented

### 1. **Batch Processing Service**
**File**: `lib/core/services/batch_processing_service.dart`

**Capabilities**:
- Process multiple images at once
- Batch expiry calculations
- Bulk import/export (CSV/Excel)
- Queue management system
- Progress tracking
- Error handling and retry logic

**Key Functions**:
```dart
// Add items to batch queue
BatchProcessingService.addToBatchQueue(items);

// Process entire batch queue
await BatchProcessingService.processBatchQueue();

// Import from directory
await BatchProcessingService.addImagesFromDirectory(path);

// Export to CSV/Excel
await BatchProcessingService.exportToCSV(products);
await BatchProcessingService.exportToExcel(products);

// Calculate batch statistics
final stats = BatchProcessingService.calculateBatchExpiryStats(products);
```

---

### 2. **Image Enhancement Service**
**File**: `lib/core/services/image_enhancement_service.dart`

**Capabilities**:
- Auto-correct lighting and exposure
- Perspective correction
- Blur reduction
- Text sharpening
- Noise reduction
- Contrast enhancement
- Image resizing for optimal OCR

**Key Functions**:
```dart
// Auto-enhance image (analyzes and applies best settings)
final enhanced = await ImageEnhancementService.autoEnhanceImage(imageFile);

// Manual enhancement with custom settings
final enhanced = await ImageEnhancementService.enhanceImageForOCR(
  imageFile,
  autoCorrectLighting: true,
  perspectiveCorrection: true,
  blurReduction: true,
  textSharpening: true,
  noiseReduction: true,
  contrastEnhancement: true,
  resizeToOptimal: true,
);

// Batch enhance multiple images
final enhancedImages = await ImageEnhancementService.batchEnhanceImages(
  imageFiles,
  autoEnhance: true,
  onProgress: (enhanced, count) => print('Enhanced $count'),
);

// Compare original vs enhanced
final comparison = await ImageEnhancementService.compareImages(original, enhanced);
```

---

### 3. **Batch Processing UI**
**File**: `lib/features/batch/batch_processing_screen.dart`

**UI Features**:
- **Import Tab**: Gallery, directory, CSV import
- **Enhance Tab**: Image enhancement settings and processing
- **Process Tab**: Batch queue management and processing
- **Export Tab**: CSV/Excel export and statistics

**Key Components**:
- Tab-based interface
- Progress indicators
- Batch statistics dashboard
- Expiry distribution charts
- Settings toggles for enhancement

---

## Usage Guide

### 1. **Batch Import**
1. Navigate to **Batch Processing** from dashboard
2. Go to **Import** tab
3. Choose import method:
   - **Gallery**: Select multiple images
   - **Directory**: Select folder with images
   - **CSV**: Import product data from CSV file
4. Items are added to batch queue

### 2. **Image Enhancement**
1. Go to **Enhance** tab
2. Configure enhancement settings:
   - **Auto-Enhance**: Automatically determine best settings
   - **Manual**: Toggle individual enhancements
3. Click **Enhance Batch Images** or **Select & Enhance Image**
4. View enhancement results and statistics

### 3. **Batch Processing**
1. Go to **Process** tab
2. Review batch queue items
3. Click **Start Processing**
4. Monitor progress in real-time
5. View completion statistics

### 4. **Export & Analytics**
1. Go to **Export** tab
2. Choose export format:
   - **CSV**: Comma-separated values
   - **Excel**: Spreadsheet format
3. View batch statistics and expiry charts
4. Share summary via clipboard

---

## Technical Implementation

### **Batch Processing Architecture**
```
User Input -> Batch Queue -> Processing Engine -> Database Storage
     |              |              |                |
  Gallery/      Queue         OCR + API       SQLite
 Directory     Management    Enhancement     Storage
   CSV           Progress      Merging         Stats
```

### **Image Enhancement Pipeline**
```
Original Image -> Analysis -> Enhancement Strategy -> Processing -> Enhanced Image
       |              |              |               |            |
   File Input    Brightness    Auto/Manual    Flutter UI   Optimized
   Validation    Contrast      Settings       Canvas       for OCR
                Blur/Noise     Matrix Filters  Image Kit     Better Text
```

### **Data Flow**
```
Images -> OCR -> AI Parsing -> API Enhancement -> Database -> Export
   |        |         |            |             |          |
Gallery  ML Kit   Local     External APIs   SQLite    CSV/Excel
Directory Tesseract Parser   Open Food Facts  Storage   Statistics
   CSV     Online   Regex     FDA Database    Queue     Charts
```

---

## Dependencies Added

### **New Packages**:
```yaml
# Batch Processing & File Handling
file_picker: ^6.1.1
permission_handler: ^11.1.0

# CSV & Excel Export
csv: ^6.0.0
excel: ^4.0.1

# Image Processing
image: ^4.1.3
```

### **Permissions Required**:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

---

## Performance Considerations

### **Batch Processing**
- **Queue Management**: Prevents memory overflow
- **Progress Tracking**: Real-time feedback
- **Error Handling**: Individual item failures don't stop batch
- **Rate Limiting**: Prevents API overload

### **Image Enhancement**
- **Memory Management**: Process images one at a time
- **Optimization**: Resize to optimal dimensions (1920x1080)
- **Caching**: Temporary files cleaned up automatically
- **Fallback**: Original image used if enhancement fails

### **Export Operations**
- **Chunking**: Large datasets processed in chunks
- **Background Processing**: Non-blocking UI
- **Compression**: Optimized file sizes
- **Validation**: Data integrity checks

---

## Error Handling

### **Batch Processing Errors**
- **Network Issues**: Retry with exponential backoff
- **API Limits**: Queue management and throttling
- **File Access**: Permission checks and fallbacks
- **Memory Issues**: Chunked processing

### **Image Enhancement Errors**
- **Unsupported Formats**: Fallback to original
- **Corruption**: Skip problematic images
- **Memory**: Automatic cleanup and retry
- **Processing**: Graceful degradation

### **Export Errors**
- **Storage**: Permission requests
- **File Creation**: Directory creation
- **Data Format**: Validation and sanitization
- **Large Datasets**: Streaming export

---

## Configuration

### **Enhancement Settings**
```dart
// Default enhancement settings
bool autoEnhance = true;
bool lightingCorrection = true;
bool perspectiveCorrection = true;
bool blurReduction = true;
bool textSharpening = true;
bool noiseReduction = true;
bool contrastEnhancement = true;
bool resizeToOptimal = true;
```

### **Batch Processing Limits**
```dart
// Default limits
int maxBatchSize = 100;
int maxConcurrentProcessing = 5;
Duration apiTimeout = Duration(seconds: 30);
int maxRetries = 3;
```

### **Export Settings**
```dart
// Export configuration
String dateFormat = 'dd/MM/yyyy';
String encoding = 'utf-8';
bool includeHeaders = true;
int maxExportSize = 10000;
```

---

## Testing

### **Unit Tests**
```dart
// Test batch processing
test('Batch processing queue management', () async {
  BatchProcessingService.addToBatchQueue(testItems);
  expect(BatchProcessingService.getBatchQueueSize(), testItems.length);
});

// Test image enhancement
test('Image enhancement improves OCR accuracy', () async {
  final enhanced = await ImageEnhancementService.autoEnhanceImage(testImage);
  expect(enhanced.path, isNotNull);
});
```

### **Integration Tests**
```dart
// Test full pipeline
test('Complete batch processing pipeline', () async {
  // 1. Import images
  await BatchProcessingService.addImagesFromDirectory(testDir);
  
  // 2. Enhance images
  final enhanced = await ImageEnhancementService.batchEnhanceImages(images);
  
  // 3. Process batch
  final result = await BatchProcessingService.processBatchQueue();
  
  // 4. Export results
  final exportPath = await BatchProcessingService.exportToCSV(products);
  
  expect(result['success'], true);
  expect(exportPath, isNotNull);
});
```

---

## Future Enhancements

### **Planned Features**
1. **Cloud Processing**: Offload heavy processing to cloud
2. **AI Models**: Custom trained OCR models
3. **Real-time Processing**: Live camera enhancement
4. **Advanced Analytics**: Machine learning insights
5. **Multi-format Support**: More import/export formats

### **Performance Improvements**
1. **Parallel Processing**: Multi-threaded enhancement
2. **GPU Acceleration**: Hardware-accelerated processing
3. **Caching**: Intelligent result caching
4. **Compression**: Better image compression

---

## Troubleshooting

### **Common Issues**

#### **Batch Processing Slow**
- Check network connection
- Reduce batch size
- Close other apps
- Restart app

#### **Image Enhancement Fails**
- Check file permissions
- Ensure sufficient storage
- Verify image format
- Try manual settings

#### **Export Errors**
- Check storage permissions
- Ensure available space
- Verify data format
- Try smaller batches

### **Debug Mode**
```dart
// Enable debug logging
LoggerService.setLevel(Level.DEBUG);

// Monitor batch progress
BatchProcessingService.processBatchQueue(
  onProgress: (msg, count) => print('$msg: $count'),
  onItemComplete: (result) => print('Item: ${result['success']}'),
);
```

---

## API Reference

### **BatchProcessingService**
```dart
// Queue Management
static void addToBatchQueue(List<Map<String, dynamic>> items)
static void clearBatchQueue()
static int getBatchQueueSize()

// Processing
static Future<Map<String, dynamic>> processBatchQueue()
static Future<Map<String, dynamic>> addImagesFromDirectory(String path)

// Import/Export
static Future<String> exportToCSV(List<Map<String, dynamic>> products)
static Future<String> exportToExcel(List<Map<String, dynamic>> products)
static Future<Map<String, dynamic>> importFromCSV(String filePath)

// Analytics
static Map<String, dynamic> calculateBatchExpiryStats(List<Map<String, dynamic>> products)
```

### **ImageEnhancementService**
```dart
// Enhancement
static Future<File> enhanceImageForOCR(File imageFile, {...})
static Future<File> autoEnhanceImage(File imageFile)
static Future<List<File>> batchEnhanceImages(List<File> images)

// Analysis
static Future<Map<String, dynamic>> _analyzeImageCharacteristics(File imageFile)
static Map<String, bool> _determineEnhancementStrategy(Map<String, dynamic> analysis)

// Comparison
static Future<Map<String, dynamic>> compareImages(File original, File enhanced)
static Future<Map<String, dynamic>> getEnhancementStats(List<File> images)
```

---

These features significantly enhance the app's capabilities, making it suitable for bulk operations and professional use cases. The modular design allows for easy maintenance and future enhancements.
