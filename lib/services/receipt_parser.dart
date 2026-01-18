class ReceiptParser {
  // Parse receipt text and extract relevant information
  static Map<String, dynamic> parseReceipt(String text) {
    final result = <String, dynamic>{
      'amount': null,
      'merchantName': null,
      'date': null,
    };

    // Extract amount
    result['amount'] = _extractAmount(text);

    // Extract merchant name (usually the first line or prominent text)
    result['merchantName'] = _extractMerchantName(text);

    // Extract date if available
    result['date'] = _extractDate(text);

    return result;
  }

  // Extract amount from receipt text (supports Thai and English)
  static double? _extractAmount(String text) {
    // Common Thai receipt patterns:
    // ยอดรวม: ฿450.00
    // รวมทั้งสิ้น 1,234.56 บาท
    // Total: ฿1,250.00
    // ทั้งหมด ๑,๒๓๔.๕๖ บาท
    // 450.00 ฿
    // ฿450.00

    final patterns = [
      // Thai patterns
      RegExp(r'(?:ยอดรวม|รวม|ทั้งหมด|รวมทั้งสิ้น)[:\s]*฿?\s*([\d,]+\.?\d*)',
          caseSensitive: false),
      RegExp(r'฿\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'([\d,]+\.?\d*)\s*฿', caseSensitive: false),
      RegExp(r'([\d,]+\.?\d*)\s*บาท', caseSensitive: false),

      // English patterns
      RegExp(r'(?:total|amount|grand total|sum)[:\s]*฿?\s*([\d,]+\.?\d*)',
          caseSensitive: false),

      // Generic number pattern (last resort)
      RegExp(r'([\d,]+\.\d{2})', caseSensitive: false),
    ];

    // Try each pattern
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        // Get all potential amounts
        final amounts = matches
            .map((match) {
              final amountStr =
                  match.group(1)?.replaceAll(',', '').replaceAll(' ', '');
              return double.tryParse(amountStr ?? '');
            })
            .where((amount) => amount != null && amount > 0)
            .toList();

        if (amounts.isNotEmpty) {
          // Return the largest amount (likely the total)
          amounts.sort((a, b) => (b ?? 0).compareTo(a ?? 0));
          return amounts.first;
        }
      }
    }

    return null;
  }

  // Extract merchant/store name from receipt
  static String? _extractMerchantName(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();

    // Remove empty lines
    lines.removeWhere((line) => line.isEmpty);

    if (lines.isEmpty) return null;

    // Usually the merchant name is in the first few lines
    // Try to find a line that looks like a business name
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];

      // Skip lines that look like addresses, phone numbers, or amounts
      if (_looksLikeBusinessName(line)) {
        return line;
      }
    }

    // Fallback: return the first non-empty line
    return lines.isNotEmpty ? lines.first : null;
  }

  // Check if a line looks like a business name
  static bool _looksLikeBusinessName(String line) {
    // Skip if it's mostly numbers
    final digitCount = line.replaceAll(RegExp(r'[^\d]'), '').length;
    if (digitCount > line.length * 0.5) return false;

    // Skip if it contains amount patterns
    if (line.contains('฿') ||
        line.contains('บาท') ||
        line.toLowerCase().contains('total') ||
        line.contains('ยอด') ||
        line.contains('รวม')) {
      return false;
    }

    // Skip very short lines (likely not a business name)
    if (line.length < 3) return false;

    return true;
  }

  // Extract date from receipt (basic implementation)
  static DateTime? _extractDate(String text) {
    // Common date patterns
    final patterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          // Try to parse the date
          final groups = [
            match.group(1),
            match.group(2),
            match.group(3),
          ];

          if (groups.every((g) => g != null)) {
            int year, month, day;

            // Determine if it's DD/MM/YYYY or YYYY/MM/DD format
            if (int.parse(groups[0]!) > 1000) {
              // YYYY-MM-DD format
              year = int.parse(groups[0]!);
              month = int.parse(groups[1]!);
              day = int.parse(groups[2]!);
            } else {
              // DD/MM/YYYY format
              day = int.parse(groups[0]!);
              month = int.parse(groups[1]!);
              year = int.parse(groups[2]!);
            }

            return DateTime(year, month, day);
          }
        } catch (e) {
          // Invalid date, continue to next pattern
          continue;
        }
      }
    }

    // If no date found, return today's date
    return DateTime.now();
  }
}
