import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  static String formatStringDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return _dateFormat.format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDisplay(DateTime? date) {
    if (date == null) return '-';
    return _displayFormat.format(date);
  }

  static String formatTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '-';
    try {
      if (timeStr.length == 8) {
        final parts = timeStr.split(':');
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        return _timeFormat.format(dt);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }
}
