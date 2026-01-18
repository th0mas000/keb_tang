import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Thai Baht currency formatter
  static final NumberFormat thbFormatter = NumberFormat.currency(
    locale: 'th_TH',
    symbol: '฿',
    decimalDigits: 2,
  );

  // Format amount in Thai Baht
  static String formatTHB(double amount) {
    return thbFormatter.format(amount);
  }

  // Format amount in Thai Baht without symbol (for input fields)
  static String formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'th_TH').format(amount);
  }

  // Parse Thai Baht string to double
  static double? parseTHB(String value) {
    try {
      // Remove common Thai Baht symbols and text
      String cleaned = value
          .replaceAll('฿', '')
          .replaceAll('บาท', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();

      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
