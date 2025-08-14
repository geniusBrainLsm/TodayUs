import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CustomAnniversaryService {
  static const String _customAnniversariesKey = 'custom_anniversaries';

  /// Get all custom anniversaries
  static Future<List<Map<String, dynamic>>> getCustomAnniversaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_customAnniversariesKey);
      
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error getting custom anniversaries: $e');
      return [];
    }
  }

  /// Add a new custom anniversary
  static Future<bool> addCustomAnniversary({
    required String title,
    required DateTime date,
    required String description,
    String? emoji,
  }) async {
    try {
      final anniversaries = await getCustomAnniversaries();
      
      final newAnniversary = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'date': date.toIso8601String(),
        'description': description,
        'emoji': emoji ?? '🎉',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      anniversaries.add(newAnniversary);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customAnniversariesKey, json.encode(anniversaries));
      
      return true;
    } catch (e) {
      print('Error adding custom anniversary: $e');
      return false;
    }
  }

  /// Update an existing custom anniversary
  static Future<bool> updateCustomAnniversary({
    required String id,
    required String title,
    required DateTime date,
    required String description,
    String? emoji,
  }) async {
    try {
      final anniversaries = await getCustomAnniversaries();
      
      final index = anniversaries.indexWhere((a) => a['id'] == id);
      if (index == -1) return false;
      
      anniversaries[index] = {
        ...anniversaries[index],
        'title': title,
        'date': date.toIso8601String(),
        'description': description,
        'emoji': emoji ?? anniversaries[index]['emoji'] ?? '🎉',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customAnniversariesKey, json.encode(anniversaries));
      
      return true;
    } catch (e) {
      print('Error updating custom anniversary: $e');
      return false;
    }
  }

  /// Delete a custom anniversary
  static Future<bool> deleteCustomAnniversary(String id) async {
    try {
      final anniversaries = await getCustomAnniversaries();
      anniversaries.removeWhere((a) => a['id'] == id);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customAnniversariesKey, json.encode(anniversaries));
      
      return true;
    } catch (e) {
      print('Error deleting custom anniversary: $e');
      return false;
    }
  }

  /// Get today's custom anniversaries
  static Future<List<Map<String, dynamic>>> getTodaysCustomAnniversaries() async {
    try {
      final anniversaries = await getCustomAnniversaries();
      final today = DateTime.now();
      
      return anniversaries.where((anniversary) {
        final anniversaryDate = DateTime.parse(anniversary['date'] as String);
        return anniversaryDate.month == today.month && 
               anniversaryDate.day == today.day;
      }).toList();
    } catch (e) {
      print('Error getting today\'s custom anniversaries: $e');
      return [];
    }
  }

  /// Get upcoming custom anniversaries (next 30 days)
  static Future<List<Map<String, dynamic>>> getUpcomingCustomAnniversaries() async {
    try {
      final anniversaries = await getCustomAnniversaries();
      final now = DateTime.now();
      final upcoming = <Map<String, dynamic>>[];
      
      for (final anniversary in anniversaries) {
        final anniversaryDate = DateTime.parse(anniversary['date'] as String);
        
        // Calculate this year's occurrence
        final thisYear = DateTime(now.year, anniversaryDate.month, anniversaryDate.day);
        final nextYear = DateTime(now.year + 1, anniversaryDate.month, anniversaryDate.day);
        
        DateTime nextOccurrence;
        if (thisYear.isAfter(now) || _isSameDay(thisYear, now)) {
          nextOccurrence = thisYear;
        } else {
          nextOccurrence = nextYear;
        }
        
        final daysUntil = nextOccurrence.difference(now).inDays;
        
        if (daysUntil <= 30) {
          upcoming.add({
            ...anniversary,
            'nextOccurrence': nextOccurrence.toIso8601String(),
            'daysUntil': daysUntil,
            'isToday': daysUntil == 0,
            'yearsCount': nextOccurrence.year - anniversaryDate.year,
          });
        }
      }
      
      // Sort by days until
      upcoming.sort((a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));
      
      return upcoming;
    } catch (e) {
      print('Error getting upcoming custom anniversaries: $e');
      return [];
    }
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Get anniversary message for custom anniversary
  static String getCustomAnniversaryMessage(Map<String, dynamic> anniversary) {
    final title = anniversary['title'] as String;
    final yearsCount = anniversary['yearsCount'] as int? ?? 0;
    final emoji = anniversary['emoji'] as String? ?? '🎉';
    
    if (yearsCount > 0) {
      return '$emoji $title ${yearsCount}주년을 축하합니다!\n특별한 날을 함께 기념해요.';
    } else {
      return '$emoji $title을 축하합니다!\n오늘은 특별한 날이에요.';
    }
  }

  /// Format custom anniversary date
  static String formatCustomAnniversaryDate(DateTime date) {
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    
    return '${date.year}년 ${monthNames[date.month - 1]} ${date.day}일';
  }

  /// Get days until custom anniversary
  static String getCustomAnniversaryDaysUntil(int daysUntil) {
    if (daysUntil == 0) {
      return '오늘!';
    } else if (daysUntil == 1) {
      return '내일';
    } else {
      return '$daysUntil일 후';
    }
  }

  /// Clear all custom anniversaries (for logout or reset)
  static Future<bool> clearCustomAnniversaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customAnniversariesKey);
      return true;
    } catch (e) {
      print('Error clearing custom anniversaries: $e');
      return false;
    }
  }

  /// Get anniversary by ID
  static Future<Map<String, dynamic>?> getCustomAnniversaryById(String id) async {
    try {
      final anniversaries = await getCustomAnniversaries();
      return anniversaries.firstWhere(
        (a) => a['id'] == id,
        orElse: () => {},
      );
    } catch (e) {
      print('Error getting custom anniversary by ID: $e');
      return null;
    }
  }

  /// Validate anniversary data
  static Map<String, dynamic> validateAnniversaryData({
    required String title,
    required DateTime date,
    required String description,
  }) {
    if (title.trim().isEmpty) {
      return {
        'isValid': false,
        'error': '기념일 제목을 입력해주세요.',
      };
    }
    
    if (title.trim().length > 50) {
      return {
        'isValid': false,
        'error': '기념일 제목은 50자 이내로 입력해주세요.',
      };
    }
    
    if (description.trim().length > 200) {
      return {
        'isValid': false,
        'error': '설명은 200자 이내로 입력해주세요.',
      };
    }
    
    final now = DateTime.now();
    final oneHundredYearsAgo = DateTime(now.year - 100, now.month, now.day);
    
    if (date.isBefore(oneHundredYearsAgo)) {
      return {
        'isValid': false,
        'error': '너무 오래된 날짜입니다.',
      };
    }
    
    return {
      'isValid': true,
      'error': '',
    };
  }
}