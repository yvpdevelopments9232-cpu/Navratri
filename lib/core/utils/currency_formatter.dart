import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _indianCurrencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

  static String format(num? amount) {
    if (amount == null) return '₹ 0';
    return _indianCurrencyFormat.format(amount);
  }

  static String formatWithDecimals(num? amount) {
    if (amount == null) return '₹ 0.00';
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);
    return format.format(amount);
  }

  static String toWords(int number) {
    if (number == 0) return "Zero Rupees Only";
    final units = [
      "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
      "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    ];
    final tens = [
      "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    ];

    String convertChunk(int n) {
      String str = "";
      if (n >= 100) {
        str += "${units[n ~/ 100]} Hundred ";
        n %= 100;
      }
      if (n >= 20) {
        str += "${tens[n ~/ 10]} ";
        n %= 10;
      }
      if (n > 0) {
        str += "${units[n]} ";
      }
      return str.trim();
    }

    String result = "";
    int crores = number ~/ 10000000;
    number %= 10000000;
    int lakhs = number ~/ 100000;
    number %= 100000;
    int thousands = number ~/ 1000;
    number %= 1000;
    int remainder = number;

    if (crores > 0) result += "${convertChunk(crores)} Crore ";
    if (lakhs > 0) result += "${convertChunk(lakhs)} Lakh ";
    if (thousands > 0) result += "${convertChunk(thousands)} Thousand ";
    if (remainder > 0) result += convertChunk(remainder);

    return "${result.trim()} Rupees Only";
  }
}
