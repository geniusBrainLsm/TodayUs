import 'package:shared_preferences/shared_preferences.dart';

class DiaryLocalState {
  static const String _lastDiaryDateKey = 'last_diary_written_date';

  static Future<void> markDiaryWritten(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDiaryDateKey, _formatDate(timestamp));
  }

  static Future<bool> hasDiaryForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_lastDiaryDateKey);
    if (storedDate == null) {
      return false;
    }

    final today = _formatDate(DateTime.now());
    return storedDate == today;
  }

  static Future<DateTime?> getLastDiaryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_lastDiaryDateKey);
    if (storedDate == null) {
      return null;
    }
    try {
      final parts = storedDate.split('-');
      if (parts.length != 3) {
        return null;
      }
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearDiaryFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastDiaryDateKey);
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
