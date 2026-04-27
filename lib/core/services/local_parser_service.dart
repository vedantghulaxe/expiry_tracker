import 'dart:math';

/// Enhanced Local Parser Service with AI-powered field recognition
class LocalParserService {
  static Map<String, dynamic> parseText(String rawText) {
    print('=== LOCAL PARSER SERVICE START ===');
    print('Input text length: ${rawText.length}');

    // Keep a cleaned variant for pattern matching, but preserve raw text for line-based parsing.
    final cleanedText = _cleanText(rawText);
    print('Cleaned text: "$cleanedText"');

    // Try regex-based parsing first
    final regexResult = _parseWithRegex(cleanedText);
    if (regexResult['success']) {
      final validatedResult = _validateParsedData(regexResult);
      print('=== REGEX PARSING SUCCESS ===');
      return {
        'success': true,
        'parsed_data': validatedResult,
        'method': 'regex',
        'confidence': 0.7,
      };
    }

    // Fallback to simple parsing
    final simpleResult = _parseSimple(rawText);
    final validatedSimpleResult = _validateParsedData(simpleResult);
    print('=== SIMPLE PARSING SUCCESS ===');
    return {
      'success': true,
      'parsed_data': validatedSimpleResult,
      'method': 'simple',
      'confidence': 0.6,
    };
  }

  /// Validate and clean parsed data
  static Map<String, dynamic> _validateParsedData(Map<String, dynamic> data) {
    print('=== VALIDATING PARSED DATA ===');
    print('Before validation: $data');

    final validatedData = Map<String, dynamic>.from(data);

    // Validate and clean each field
    validatedData['name'] = _cleanField(data['name']?.toString());
    validatedData['brand'] = _cleanField(data['brand']?.toString());
    validatedData['category'] = _cleanField(data['category']?.toString());
    validatedData['expiryDate'] = _validateDate(data['expiryDate']?.toString());
    validatedData['mfgDate'] = _validateDate(data['mfgDate']?.toString());
    validatedData['batchNumber'] = _cleanField(data['batchNumber']?.toString());
    validatedData['dosage'] = _cleanField(data['dosage']?.toString());
    validatedData['uses'] = _cleanField(data['uses']?.toString());
    validatedData['warnings'] = _cleanField(data['warnings']?.toString());
    validatedData['ingredients'] = _cleanField(data['ingredients']?.toString());
    validatedData['quantity'] = _cleanField(data['quantity']?.toString());

    print('After validation: $validatedData');
    return validatedData;
  }

  /// Clean individual field — only trims whitespace, does NOT mangle characters
  static String _cleanField(String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return '';
    }
    // Only trim surrounding whitespace and normalize internal spaces
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validate date format — only cleans whitespace, does NOT mangle characters
  static String _validateDate(String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return '';
    }

    final cleaned = value.trim();

    // Accept MM/YYYY or MM/YY formats
    if (RegExp(r'^\d{2}[/]\d{2,4}$').hasMatch(cleaned)) {
      return cleaned;
    }

    // Accept DD/MM/YYYY format
    if (RegExp(r'^\d{1,2}[/]\d{1,2}[/]\d{2,4}$').hasMatch(cleaned)) {
      return cleaned;
    }

    print('Invalid date format: $value');
    return '';
  }

  static Map<String, dynamic> _parseWithRegex(String text) {
    // TO DO: implement regex-based parsing
    return {'success': false};
  }

  static Map<String, dynamic> _parseSimple(String text) {
    if (text.trim().isEmpty) {
      return _createEmptyResult();
    }

    final result = _createEmptyResult();

    try {
      // Extract product name (simple approach)
      result['name'] = _extractSimpleProductName(text);

      // Extract dates (simple patterns)
      result['expiryDate'] = _extractSimpleDate(text, 'exp');
      result['mfgDate'] = _extractSimpleDate(text, 'mfg');

      // Extract brand (simple approach)
      result['brand'] = _extractSimpleBrand(text);

      // Extract batch number
      result['batchNumber'] = _extractSimpleBatch(text);
      result['ingredients'] = _extractSimpleIngredients(text);

      // Detect if medicine
      final isMedicine = result['isMedicine'] = _isMedicineContent(text);
      result['category'] = isMedicine ? 'medicine' : 'product';

      // Extract dosage if medicine
      if (isMedicine) {
        result['dosage'] = _extractSimpleDosage(text);
      }

      // Calculate confidence
      result['confidence'] = _calculateSimpleConfidence(result, text);

      // Ensure name is not too long
      if (result['name'] != null && result['name'].toString().length > 50) {
        result['name'] = text.substring(0, text.length > 50 ? 50 : text.length);
      }
    } catch (e) {
      print('=== PARSING ERROR: $e ===');
      // Return basic result with raw text
      result['name'] = text.substring(0, text.length > 50 ? 50 : text.length);
      result['confidence'] = 0.3;
    }

    return result;
  }

  /// Simple product name extraction (no complex regex)
  static String _extractSimpleProductName(String text) {
    print('=== EXTRACTING PRODUCT NAME FROM ===');
    print(text);

    // For the specific format we're seeing, look for product indicators
    final lines = text.split('\n');
    List<String> possibleNames = [];

    for (final line in lines) {
      final cleanLine = line.trim();
      print('Checking line: "$cleanLine"');

      // Skip common non-product lines
      if (cleanLine.length < 2 ||
          cleanLine.toLowerCase().contains('batch') ||
          cleanLine.toLowerCase().contains('mfg') ||
          cleanLine.toLowerCase().contains('exp') ||
          cleanLine.toLowerCase().contains('date') ||
          cleanLine.toLowerCase().contains('mrpe') ||
          cleanLine.toLowerCase().contains('price') ||
          cleanLine.toLowerCase().contains('sale') ||
          cleanLine.toLowerCase().contains('net wt') ||
          cleanLine.toLowerCase().contains('stored at') ||
          cleanLine.toLowerCase().contains('made in') ||
          cleanLine.toLowerCase().contains('unt sale') ||
          cleanLine.toLowerCase().contains('ml no') ||
          cleanLine.toLowerCase().contains('tax') ||
          cleanLine.toLowerCase().contains('inclusive') ||
          cleanLine.toLowerCase().contains('gst') ||
          cleanLine.toLowerCase().contains('rs.') ||
          cleanLine.toLowerCase().contains('mrp') ||
          cleanLine.toLowerCase().contains('m.r.p') ||
          cleanLine.toLowerCase().contains('rupee') ||
          cleanLine.toLowerCase().contains('www.') ||
          cleanLine.toLowerCase().contains('.com') ||
          cleanLine.toLowerCase().contains('dist.') ||
          cleanLine.toLowerCase().contains('marketed by') ||
          cleanLine.toLowerCase().contains('manufactured by') ||
          cleanLine.contains(RegExp(r'\d{2}[/]\d{4}')) ||
          cleanLine.contains(RegExp(r'\d{2}[/]\d{2}')) ||
          cleanLine.contains(RegExp(r'^\d+')) ||
          cleanLine.contains(RegExp(r'^[A-Z]{2,}\s+/\s+\d+')) ||
          cleanLine.contains(RegExp(r'^[A-Z]{2,}\s+\d+'))) {
        continue;
      }

      // Add as possible name if it looks like a product
      if (cleanLine.length > 2 && cleanLine.length < 50) {
        // Check if it contains product-like words
        if (_isProductLike(cleanLine)) {
          possibleNames.add(cleanLine);
          print('Added possible name: "$cleanLine"');
        }
      }
    }

    // Return the first possible name, or create one from context
    if (possibleNames.isNotEmpty) {
      final name = possibleNames.first;
      print('Selected product name: "$name"');
      return name;
    }

    // Fallback: Look for product-like patterns
    final patterns = [
      RegExp(r'([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z]+)?)'),
      RegExp(r'([A-Z]{3,})'),
      RegExp(
        r'([A-Z][a-z]+\s+(?:Serum|Cream|Lotion|Oil|Gel|Tablet|Capsule|Medicine|Ointment|Syrup))',
      ),
      RegExp(r'([A-Z][a-z]+\s+[A-Z][a-z]+\s+(?:Serum|Cream|Lotion|Oil|Gel))'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)!;
        // Skip if it's a common non-product term
        if (_isProductLike(name)) {
          print('Found pattern match: "$name"');
          return name;
        }
      }
    }

    // Ultimate fallback: create a descriptive name
    print('Using fallback product name');
    return 'Product';
  }

  /// Check if text looks like a product name
  static bool _isProductLike(String text) {
    final productWords = [
      'serum',
      'cream',
      'lotion',
      'oil',
      'gel',
      'tablet',
      'capsule',
      'medicine',
      'ointment',
      'syrup',
      'powder',
      'shampoo',
      'conditioner',
      'soap',
      'toothpaste',
      'deodorant',
      'perfume',
      'cologne',
      'makeup',
      'foundation',
      'lipstick',
      'mascara',
      'eyeliner',
      'moisturizer',
      'cleanser',
      'toner',
      'sunscreen',
      'exfoliator',
      'mask',
      'peel',
      'treatment',
    ];

    final lowerText = text.toLowerCase();

    // Check if it contains product words
    for (final word in productWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }

    // Check if it's a brand-like name (capitalized, no numbers)
    if (RegExp(r'^[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?$').hasMatch(text) &&
        !text.contains(RegExp(r'\d'))) {
      return true;
    }

    return false;
  }

  /// Simple date extraction
  static String _extractSimpleDate(String text, String type) {
    print('=== EXTRACTING $type DATE FROM ===');
    print(text);

    // Look for "Use Before" pattern for expiry
    if (type == 'exp') {
      final useBeforePattern = RegExp(
        r'Use Before\s*[:\-]?\s*(\d{2}[/]\d{4})',
        caseSensitive: false,
      );
      final useBeforeMatch = useBeforePattern.firstMatch(text);
      if (useBeforeMatch != null) {
        final date = useBeforeMatch.group(1)!;
        print('Found use before date: "$date"');
        return date;
      }

      // Look for "EXP" or "Expiry" patterns
      final expPattern = RegExp(
        r'(?:EXP|Expiry|Exp\.?)\s*[:\-]?\s*(\d{2}[/]\d{4})',
        caseSensitive: false,
      );
      final expMatch = expPattern.firstMatch(text);
      if (expMatch != null) {
        final date = expMatch.group(1)!;
        print('Found exp date: "$date"');
        return date;
      }
    }

    // Look for "Mfg" pattern for manufacturing
    if (type == 'mfg') {
      final mfgPattern = RegExp(
        r'(?:MFG|Mfg|Manufacturing|Manuf\.?)\s*[:\-]?\s*(\d{2}[/]\d{4})',
        caseSensitive: false,
      );
      final mfgMatch = mfgPattern.firstMatch(text);
      if (mfgMatch != null) {
        final date = mfgMatch.group(1)!;
        print('Found mfg date: "$date"');
        return date;
      }
    }

    // Look for MM/YY patterns (like 10/25, 09/28) and convert to MM/YYYY
    final shortDatePattern = RegExp(r'(\d{1,2})[/\-](\d{2})');
    final shortMatches = shortDatePattern.allMatches(text).toList();

    if (shortMatches.isNotEmpty) {
      print('Found ${shortMatches.length} short date patterns');

      // Convert MM/YY to MM/YYYY (assuming 20YY for years < 50, 19YY for years >= 50)
      List<String> fullDates = [];
      for (final match in shortMatches) {
        final month = match.group(1)!;
        final year = match.group(2)!;
        int fullYear = int.parse(year);

        // Convert 2-digit year to 4-digit year
        if (fullYear < 50) {
          fullYear += 2000;
        } else {
          fullYear += 1900;
        }

        final fullDate = '$month/$fullYear';
        fullDates.add(fullDate);
        print('Converted ${match.group(0)!} to $fullDate');
      }

      if (type == 'exp') {
        // For expiry, take the last date (usually later)
        final date = fullDates.last;
        print('Selected expiry date: "$date"');
        return date;
      } else {
        // For mfg, take the first date
        final date = fullDates.first;
        print('Selected mfg date: "$date"');
        return date;
      }
    }

    // Fallback: Look for any MM/YYYY patterns
    final fullDatePattern = RegExp(r'\d{1,2}[/\-]\d{4}');
    final fullMatches = fullDatePattern.allMatches(text).toList();

    if (fullMatches.isEmpty) {
      // Last fallback: DD/MM/YYYY or YYYY-MM-DD style values
      final longDatePattern = RegExp(
        r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}|\d{4}[/\-]\d{1,2}[/\-]\d{1,2})',
      );
      final longMatches = longDatePattern.allMatches(text).toList();
      if (longMatches.isNotEmpty) {
        final date = type == 'exp'
            ? longMatches.last.group(0)!
            : longMatches.first.group(0)!;
        print('Found long date pattern: "$date"');
        return date;
      }
      print('No date found');
      return '';
    }

    if (type == 'exp') {
      // For expiry, take the last date (usually expiry is later)
      final date = fullMatches.last.group(0)!;
      print('Found fallback expiry date: "$date"');
      return date;
    } else {
      // For mfg, take the first date
      final date = fullMatches.first.group(0)!;
      print('Found fallback mfg date: "$date"');
      return date;
    }
  }

  static String _extractSimpleIngredients(String text) {
    // Use caseSensitive: false instead of  inline flag (not supported in Dart)
    final patterns = [
      RegExp(
        r'(?:ingredients|ingredient|composition)[:\s]+([^\n]+)',
        caseSensitive: false,
      ),
      RegExp(r'(?:contains)[:\s]+([^\n]+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return _cleanField(match.group(1));
      }
    }
    return '';
  }

  /// Simple brand extraction
  static String _extractSimpleBrand(String text) {
    print('=== EXTRACTING BRAND FROM ===');
    print(text);

    // Look for "manufactured by" or "marketed by"
    if (text.toLowerCase().contains('manufactured by')) {
      final index = text.toLowerCase().indexOf('manufactured by');
      final after = text.substring(index + 15);
      final lines = after.split('\n');
      if (lines.isNotEmpty) {
        final brand = lines.first.trim().substring(
          0,
          lines.first.trim().length > 50 ? 50 : lines.first.trim().length,
        );
        print('Found manufactured by brand: "$brand"');
        return brand;
      }
    }

    if (text.toLowerCase().contains('marketed by')) {
      final index = text.toLowerCase().indexOf('marketed by');
      final after = text.substring(index + 11);
      final lines = after.split('\n');
      if (lines.isNotEmpty) {
        final brand = lines.first.trim().substring(
          0,
          lines.first.trim().length > 50 ? 50 : lines.first.trim().length,
        );
        print('Found marketed by brand: "$brand"');
        return brand;
      }
    }

    // Look for "Marketed by:" pattern
    final marketedPattern = RegExp(
      r'Marketed by:\s*([^\n]+)',
      caseSensitive: false,
    );
    final marketedMatch = marketedPattern.firstMatch(text);
    if (marketedMatch != null) {
      final brand = marketedMatch.group(1)!.trim();
      print('Found marketed by pattern: "$brand"');
      return brand.substring(0, brand.length > 50 ? 50 : brand.length);
    }

    // Look for "Manufactured by:" pattern
    final mfgPattern = RegExp(
      r'Manufactured by:\s*([^\n]+)',
      caseSensitive: false,
    );
    final mfgMatch = mfgPattern.firstMatch(text);
    if (mfgMatch != null) {
      final brand = mfgMatch.group(1)!.trim();
      print('Found manufactured by pattern: "$brand"');
      return brand.substring(0, brand.length > 50 ? 50 : brand.length);
    }

    print('No brand found');
    return '';
  }

  /// Simple batch number extraction
  static String _extractSimpleBatch(String text) {
    print('=== EXTRACTING BATCH FROM ===');
    print(text);

    // Look for "Batch No" pattern
    final batchPattern = RegExp(
      r'Batch No\s*[:\-]?\s*([^\s\n]+)',
      caseSensitive: false,
    );
    final batchMatch = batchPattern.firstMatch(text);
    if (batchMatch != null) {
      final batch = batchMatch.group(1)!.trim();
      print('Found batch pattern: "$batch"');
      return batch;
    }

    // Look for "Batch" followed by alphanumeric code
    final batchNumPattern = RegExp(
      r'Batch\s*([A-Z0-9/]+)',
      caseSensitive: false,
    );
    final batchNumMatch = batchNumPattern.firstMatch(text);
    if (batchNumMatch != null) {
      final batch = batchNumMatch.group(1)!.trim();
      print('Found batch number: "$batch"');
      return batch;
    }

    // Look for patterns like "GC/ 1301" or "004J25" after batch line
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.toLowerCase().contains('batch')) {
        // Check next few lines for batch codes
        for (int j = i + 1; j < min(i + 4, lines.length); j++) {
          final nextLine = lines[j].trim();

          // Look for GC/ pattern
          final gcPattern = RegExp(r'GC[/]\s*(\d+)', caseSensitive: false);
          final gcMatch = gcPattern.firstMatch(nextLine);
          if (gcMatch != null) {
            final batch = 'GC/' + gcMatch.group(1)!;
            print('Found GC pattern: "$batch"');
            return batch;
          }

          // Look for alphanumeric codes like 004J25
          final codePattern = RegExp(r'^[A-Z0-9]{5,}$');
          if (codePattern.hasMatch(nextLine) && nextLine.length > 3) {
            print('Found alphanumeric batch code: "$nextLine"');
            return nextLine;
          }
        }
        break;
      }
    }

    // Look for mh/ pattern
    final mhPattern = RegExp(r'MH[/]\d+', caseSensitive: false);
    final mhMatch = mhPattern.firstMatch(text);
    if (mhMatch != null) {
      final batch = mhMatch.group(0)!;
      print('Found MH pattern: "$batch"');
      return batch;
    }

    // Look for any MH/ pattern in text
    final anyMhPattern = RegExp(r'MH[/:\s]*([A-Z0-9]+)', caseSensitive: false);
    final anyMhMatch = anyMhPattern.firstMatch(text);
    if (anyMhMatch != null) {
      final batch = 'MH/' + anyMhMatch.group(1)!;
      print('Found any MH pattern: "$batch"');
      return batch;
    }

    print('No batch found');
    return '';
  }

  /// Simple dosage extraction
  static String _extractSimpleDosage(String text) {
    // Look for patterns like "529.00" or "17.63" followed by units
    final dosagePattern = RegExp(r'\d+\.\d+\s*(?:mg|ml|g|mcg)');
    final match = dosagePattern.firstMatch(text);
    if (match != null) {
      return match.group(0)!;
    }

    return '';
  }

  /// Simple confidence calculation
  static double _calculateSimpleConfidence(
    Map<String, dynamic> result,
    String text,
  ) {
    double confidence = 0.0;

    // Base confidence for having text
    if (text.isNotEmpty) confidence += 0.3;

    // Add confidence for each extracted field
    if (result['name']?.isNotEmpty == true) confidence += 0.2;
    if (result['expiryDate']?.isNotEmpty == true) confidence += 0.2;
    if (result['brand']?.isNotEmpty == true) confidence += 0.1;
    if (result['batchNumber']?.isNotEmpty == true) confidence += 0.1;
    if (result['dosage']?.isNotEmpty == true) confidence += 0.1;

    return confidence > 1.0 ? 1.0 : confidence;
  }

  /// AI-powered product name extraction (deprecated)
  static String _extractProductName(String text) {
    // Product name patterns
    final productPatterns = [
      RegExp(r'(?:product|name|item)[:\s]+([^\n]+)'),
      RegExp(
        r'^(.+?)(?:\s+(?:tablet|capsule|syrup|cream|lotion|oil|powder|tablets|capsules))',
      ),
      RegExp(r'^([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)'),
      RegExp(r'^([A-Za-z\s]+?)(?:\s+\d+(?:mg|ml|g|kg))'),
    ];

    for (final pattern in productPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String name = match.group(1)!.trim();
        // Clean up common suffixes
        name = name.replaceAll(
          RegExp(
            r'(?:tablet|capsule|syrup|cream|lotion|oil|powder|tablets|capsules)$',
          ),
          '',
        );
        return _cleanExtractedText(name);
      }
    }

    // Fallback: first line or first meaningful phrase
    final lines = text.split('\n');
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.length > 3 &&
          !RegExp(r'^\d+[/]\d+[/]\d+$').hasMatch(cleanLine)) {
        return _cleanExtractedText(cleanLine);
      }
    }

    return '';
  }

  /// AI-powered brand extraction
  static String _extractBrand(String text) {
    final brandPatterns = [
      RegExp(r'(?:brand|by|manufacturer|made by|from)[:\s]+([^\n]+)'),
      RegExp(
        r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)(?:\s+(?:Ltd|Inc|Corp|Limited|Pvt|Group))',
      ),
      RegExp(r'^([A-Z][a-z]+\s+[A-Z][a-z]+)\s+'),
    ];

    for (final pattern in brandPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered expiry date extraction
  static String _extractExpiryDate(String text) {
    final expiryPatterns = [
      // Standard label patterns: EXP: MM/YYYY, EXP: DD/MM/YYYY, etc.
      RegExp(
        r'(?:exp|expiry|expires|best before|use by|exp date|exp\.|expir[y]? date)[:\s]*(\d{1,2}[/]\d{1,2}[/]\d{2,4}|\d{1,2}[/]\d{4})',
        caseSensitive: false,
      ),
      // Short format: EXP MM/YYYY
      RegExp(
        r'(?:exp|expiry|expires|best before|use by)[:\s]*(\d{1,2}[/]\d{4})',
        caseSensitive: false,
      ),
      // Text month format: EXP January 15, 2025
      RegExp(
        r'(?:exp|expiry|expires|best before|use by)[:\s]*([A-Za-z]+\s+\d{1,2},?\s+\d{4})',
        caseSensitive: false,
      ),
      // Dash format: EXP DD-MM-YYYY
      RegExp(
        r'(?:exp|expiry|expires|best before|use by)[:\s]*(\d{1,2}[-]\d{1,2}[-]\d{2,4})',
        caseSensitive: false,
      ),
      // Indian format: EXP DD.MM.YYYY
      RegExp(
        r'(?:exp|expiry|expires|best before|use by)[:\s]*(\d{1,2}[.]\d{1,2}[.]\d{2,4})',
        caseSensitive: false,
      ),
      // Standalone date near EXP keyword: EXP 09/2026
      RegExp(
        r'(?:^|\n)\s*(?:exp|expiry)[:\s]*(\d{1,2}[/]\d{2,4})',
        caseSensitive: false,
      ),
      // Date with label: "Expiry Date:" or "Exp. Date:"
      RegExp(
        r'(?:expir[y]?\s*date|exp\s*date|date\s*of\s*exp)[:\s]*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}|\d{1,2}[/\-\.]\d{4})',
        caseSensitive: false,
      ),
      // Batch + expiry pattern: "B.No: XXX EXP: MM/YYYY"
      RegExp(
        r'(?:b\.?\s*no\.?|batch)[:\s]*\S+\s+(?:exp|expiry)[:\s]*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}|\d{1,2}[/\-\.]\d{4})',
        caseSensitive: false,
      ),
      // Mfg + Exp pair pattern: "MFG: XX/XXXX EXP: XX/XXXX"
      RegExp(
        r'(?:mfg|manufactured)[:\s]*\S+\s+(?:exp|expiry)[:\s]*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}|\d{1,2}[/\-\.]\d{4})',
        caseSensitive: false,
      ),
      // COMPACT INDIAN FORMAT: 03AUG26 (DDMMMYY) - very common on Indian products
      RegExp(
        r'(?:exp|expiry|expires|best before|use by|exp\.|exp date)[:\s]*(\d{1,2}[A-Za-z]{3,}\d{2,4})',
        caseSensitive: false,
      ),
      // Compact format without label (just the date after EXP): 03AUG26
      RegExp(
        r'(?:^|\n)\s*(?:exp|expiry)[:\s]*(\d{1,2}[A-Za-z]{3}\d{2})',
        caseSensitive: false,
      ),
      // Generic compact date pattern for expiry
      RegExp(
        r'(?:expiry|exp|expires|best before)[:\s]*(\d{2}[A-Za-z]{3}\d{2,4})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in expiryPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String dateStr = match.group(1)!;
        return _normalizeDate(dateStr);
      }
    }

    return '';
  }

  /// AI-powered manufacturing date extraction
  static String _extractMfgDate(String text) {
    final mfgPatterns = [
      RegExp(
        r'(?:mfg|manufactured|produced|made|packed|date of manufacture|mfg date|mfg\.)[:\s]*(\d{1,2}[/]\d{1,2}[/]\d{2,4}|\d{1,2}[/]\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:mfg|manufactured|produced|made|packed)[:\s]*(\d{1,2}[/]\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:mfg|manufactured|produced|made|packed)[:\s]*([A-Za-z]+\s+\d{1,2},?\s+\d{4})',
        caseSensitive: false,
      ),
      // Indian format: MFG DD.MM.YYYY
      RegExp(
        r'(?:mfg|manufactured|produced|made|packed)[:\s]*(\d{1,2}[.]\d{1,2}[.]\d{2,4})',
        caseSensitive: false,
      ),
      // Dash format: MFG DD-MM-YYYY
      RegExp(
        r'(?:mfg|manufactured|produced|made|packed)[:\s]*(\d{1,2}[-]\d{1,2}[-]\d{2,4})',
        caseSensitive: false,
      ),
      // "Date of Mfg:" or "Mfg. Date:"
      RegExp(
        r'(?:date\s*of\s*mfg|mfg\s*date|manufacturing\s*date)[:\s]*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}|\d{1,2}[/\-\.]\d{4})',
        caseSensitive: false,
      ),
      // COMPACT INDIAN FORMAT for MFG/PKD: 04APR26 (DDMMMYY) - PKD means Packed Date
      RegExp(
        r'(?:mfg|manufactured|produced|made|packed|pkd)[:\s]*(\d{1,2}[A-Za-z]{3,}\d{2,4})',
        caseSensitive: false,
      ),
      // Generic compact date after PKD (common on Indian products)
      RegExp(
        r'(?:pkd|packed)[:\s]*(\d{2}[A-Za-z]{3}\d{2,4})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in mfgPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String dateStr = match.group(1)!;
        return _normalizeDate(dateStr);
      }
    }

    return '';
  }

  /// AI-powered dosage extraction
  static String _extractDosage(String text) {
    final dosagePatterns = [
      RegExp(
        r'(?:dosage|strength|potency|concentration)[:\s]*(\d+(?:\.\d+)?\s*(?:mg|ml|g|mcg|iu|units?))',
      ),
      RegExp(
        r'(\d+(?:\.\d+)?\s*(?:mg|ml|g|mcg|iu|units?)\s*(?:tablet|capsule|syrup|injection|suppository))',
      ),
      RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|ml|g|mcg|iu|units?))'),
    ];

    for (final pattern in dosagePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered ingredients extraction
  static String _extractIngredients(String text) {
    final ingredientsPatterns = [
      RegExp(r'(?:ingredients|contains|composition)[:\s]+([^\n]+)'),
      RegExp(r'(?:ingredients|contains|composition)[:\s]+([^.]+\.)'),
    ];

    for (final pattern in ingredientsPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered nutrition info extraction
  static String _extractNutritionInfo(String text) {
    final nutritionPatterns = [
      RegExp(
        r'(?:nutrition|nutritional|calories|protein|carbohydrate|fat|vitamins|minerals)[:\s]+([^\n]+)',
      ),
      RegExp(
        r'(?:nutrition|nutritional|calories|protein|carbohydrate|fat|vitamins|minerals)[:\s]+([^.]+\.)',
      ),
    ];

    for (final pattern in nutritionPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered storage info extraction
  static String _extractStorageInfo(String text) {
    final storagePatterns = [
      RegExp(r'(?:storage|store|keep|preserve)[:\s]+([^\n]+)'),
      RegExp(r'(?:storage|store|keep|preserve)[:\s]+([^.]+\.)'),
    ];

    for (final pattern in storagePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered uses extraction
  static String _extractUses(String text) {
    final usesPatterns = [
      RegExp(
        r'(?:uses|indications|for|used for|treats|relieves)[:\s]+([^\n]+)',
      ),
      RegExp(
        r'(?:uses|indications|for|used for|treats|relieves)[:\s]+([^.]+\.)',
      ),
    ];

    for (final pattern in usesPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered warnings extraction
  static String _extractWarnings(String text) {
    final warningPatterns = [
      RegExp(
        r'(?:warning|caution|side effects|adverse reactions|precautions?)[:\s]+([^\n]+)',
      ),
      RegExp(
        r'(?:warning|caution|side effects|adverse reactions)[:\s]+([^.]+\.)',
      ),
    ];

    for (final pattern in warningPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered batch number extraction
  static String _extractBatchNumber(String text) {
    final batchPatterns = [
      RegExp(r'(?:batch|lot|batch no|lot no|batch number)[:\s]*([A-Za-z0-9]+)'),
      RegExp(r'(?:batch|lot)(?:\s+no)?[:\s]*([A-Za-z0-9]+)'),
    ];

    for (final pattern in batchPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _cleanExtractedText(match.group(1)!);
      }
    }

    return '';
  }

  /// AI-powered category detection
  static String _detectCategory(String text) {
    final medicineKeywords = [
      'tablet',
      'capsule',
      'syrup',
      'injection',
      'medicine',
      'drug',
      'pharmaceutical',
      'dosage',
      'prescription',
      'side effects',
      'indication',
      'contraindication',
      'pharmacy',
      'medical',
      'treatment',
      'therapy',
      'cure',
      'remedy',
    ];

    final productKeywords = [
      'food',
      'beverage',
      'cosmetic',
      'cream',
      'lotion',
      'shampoo',
      'soap',
      'ingredients',
      'nutrition',
      'calories',
      'protein',
      'carbohydrate',
      'fat',
      'vitamin',
      'mineral',
      'supplement',
      'organic',
      'natural',
    ];

    final lowerText = text.toLowerCase();

    int medicineScore = _countKeywords(lowerText, medicineKeywords);
    int productScore = _countKeywords(lowerText, productKeywords);

    if (medicineScore > productScore) {
      return 'Medicine';
    } else if (productScore > medicineScore) {
      return 'Product';
    }

    return 'Unknown';
  }

  /// AI-powered content type detection
  static bool _isMedicineContent(String text) {
    return _detectCategory(text) == 'Medicine';
  }

  /// Clean extracted text
  static String _cleanExtractedText(String text) {
    return text
        .replaceAll(
          RegExp(r'[^\w\s\-\.,]'),
          '',
        ) // Keep only letters, numbers, spaces, hyphens, dots, commas
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  /// Count keyword matches
  static int _countKeywords(String text, List<String> keywords) {
    int count = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        count++;
      }
    }
    return count;
  }

  /// Clean and normalize text
  static String _cleanText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-\./\d]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Normalize date format
  static String _normalizeDate(String dateStr) {
    // Handle various date formats and convert to DD/MM/YYYY
    dateStr = dateStr.trim();

    // Handle COMPACT INDIAN FORMAT: 03AUG26 or 03AUG2026 (DDMMMYY or DDMMMYYYY)
    final compactMatch = RegExp(
      r'^(\d{1,2})([A-Za-z]{3,})(\d{2,4})$',
      caseSensitive: false,
    ).firstMatch(dateStr);

    if (compactMatch != null) {
      final day = compactMatch.group(1)!;
      final monthStr = compactMatch.group(2)!.toUpperCase();
      var year = compactMatch.group(3)!;

      // Convert 2-digit year to 4-digit
      if (year.length == 2) {
        final yearInt = int.tryParse(year) ?? 0;
        // Assume years 50+ are 1900s, below 50 are 2000s
        if (yearInt >= 50) {
          year = '19$year';
        } else {
          year = '20$year';
        }
      }

      // Convert month name to number
      final monthMap = {
        'JAN': '1', 'JANUARY': '1',
        'FEB': '2', 'FEBRUARY': '2',
        'MAR': '3', 'MARCH': '3',
        'APR': '4', 'APRIL': '4',
        'MAY': '5',
        'JUN': '6', 'JUNE': '6',
        'JUL': '7', 'JULY': '7',
        'AUG': '8', 'AUGUST': '8',
        'SEP': '9', 'SEPT': '9', 'SEPTEMBER': '9',
        'OCT': '10', 'OCTOBER': '10',
        'NOV': '11', 'NOVEMBER': '11',
        'DEC': '12', 'DECEMBER': '12',
      };

      final month = monthMap[monthStr] ?? '1';
      return '$day/$month/$year';
    }

    // Replace common separators
    dateStr = dateStr.replaceAll(RegExp(r'[-]'), '/');

    final parts = dateStr.split('/');
    if (parts.length == 2) {
      // MM/YYYY format
      return dateStr; // Keep as is
    } else if (parts.length == 3) {
      // DD/MM/YYYY or MM/DD/YYYY format
      final day = int.tryParse(parts[0]) ?? 1;
      final month = int.tryParse(parts[1]) ?? 1;
      final year = int.tryParse(parts[2]) ?? 2024;

      // Validate day and month ranges
      if (day <= 31 && month <= 12) {
        return '$day/$month/$year';
      }
    }

    return dateStr;
  }

  /// Calculate confidence score
  static double _calculateConfidence(
    Map<String, dynamic> result,
    String cleanedText,
  ) {
    double score = 0;

    // Name (most important)
    if (result['name']?.isNotEmpty == true) score += 30;

    // Expiry date (very important)
    if (result['expiryDate']?.isNotEmpty == true) score += 25;

    // Brand (important)
    if (result['brand']?.isNotEmpty == true) score += 15;

    // Category detection
    if (result['category']?.isNotEmpty == true &&
        result['category'] != 'Unknown')
      score += 10;

    // Type-specific fields
    final isMedicine = result['isMedicine'] == true;
    if (isMedicine) {
      if (result['dosage']?.isNotEmpty == true) score += 10;
      if (result['uses']?.isNotEmpty == true) score += 5;
      if (result['warnings']?.isNotEmpty == true) score += 5;
    } else {
      if (result['ingredients']?.isNotEmpty == true) score += 10;
      if (result['nutritionInfo']?.isNotEmpty == true) score += 5;
      if (result['storageInfo']?.isNotEmpty == true) score += 5;
    }

    return min(score, 100);
  }

  /// Create empty result structure
  static Map<String, dynamic> _createEmptyResult() {
    return {
      'name': '',
      'brand': '',
      'category': '',
      'expiryDate': '',
      'mfgDate': '',
      'dosage': '',
      'uses': '',
      'warnings': '',
      'ingredients': '',
      'nutritionInfo': '',
      'storageInfo': '',
      'batchNumber': '',
      'confidence': 0.0,
      'isMedicine': false,
    };
  }

  /// Check if result is valid
  static bool isValidResult(Map<String, dynamic> result) {
    return result['confidence'] >= 50 && result['name']?.isNotEmpty == true;
  }
}
