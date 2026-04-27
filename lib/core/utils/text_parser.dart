class TextParser {

  static String? extractMedicineName(String text) {
    final lines = text.split('\n');

    for (var line in lines) {
      line = line.trim();

      if (line.length > 3 &&
          !line.toLowerCase().contains("tablet") &&
          !line.toLowerCase().contains("mg") &&
          !line.toLowerCase().contains("take")) {
        return line;
      }
    }
    return null;
  }

  static String? extractDosage(String text) {
    final regex = RegExp(r'\b\d+\s?(mg|ml|g)\b', caseSensitive: false);
    return regex.firstMatch(text)?.group(0);
  }

  static DateTime? extractExpiry(String text) {
    final regex = RegExp(
      r'(exp|expiry)?\s*[:\-]?\s*(\d{1,2}[/\-]\d{2,4})',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match != null) {
      try {
        final parts = match.group(2)!.split(RegExp(r'[/\-]'));

        int month = int.parse(parts[0]);
        int year = int.parse(parts[1]);

        if (year < 100) year += 2000;

        return DateTime(year, month);
      } catch (_) {}
    }

    return null;
  }

  static String? extractDoctor(String text) {
    final regex = RegExp(r'(Dr\.?\s+[A-Za-z]+)', caseSensitive: false);
    return regex.firstMatch(text)?.group(0);
  }
}