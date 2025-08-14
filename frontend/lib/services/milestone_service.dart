import 'package:shared_preferences/shared_preferences.dart';
import 'anniversary_service.dart';

class MilestoneService {
  static const String _lastCheckedKey = 'last_milestone_check';

  /// Get all milestones (anniversaries and day counts)
  static Future<List<Map<String, dynamic>>> getAllMilestones() async {
    final anniversaryData = await AnniversaryService.getAnniversary();
    final milestones = <Map<String, dynamic>>[];
    
    if (anniversaryData != null && anniversaryData['anniversaryDate'] != null) {
      final anniversaryDate = anniversaryData['anniversaryDate'] as DateTime;
      final daysSince = AnniversaryService.calculateDaysSince(anniversaryDate);
      
      // Add anniversary milestones (yearly)
      for (int year = 1; year <= 10; year++) {
        final targetDays = year * 365;
        final milestoneDate = anniversaryDate.add(Duration(days: targetDays - 1));
        
        milestones.add({
          'type': 'anniversary',
          'title': '${year}주년',
          'days': targetDays,
          'date': milestoneDate,
          'isPassed': daysSince >= targetDays,
          'isToday': daysSince == targetDays,
          'daysUntil': targetDays - daysSince,
        });
      }
      
      // Add day count milestones
      final dayMilestones = [100, 200, 300, 500, 1000, 1500, 2000, 3000, 5000];
      for (final targetDays in dayMilestones) {
        if (targetDays <= 3650) { // Only show milestones within 10 years
          final milestoneDate = anniversaryDate.add(Duration(days: targetDays - 1));
          
          milestones.add({
            'type': 'day_count',
            'title': 'D+$targetDays',
            'days': targetDays,
            'date': milestoneDate,
            'isPassed': daysSince >= targetDays,
            'isToday': daysSince == targetDays,
            'daysUntil': targetDays - daysSince,
          });
        }
      }
      
      // Sort by days
      milestones.sort((a, b) => a['days'].compareTo(b['days']));
    }
    
    return milestones;
  }

  /// Get upcoming milestones (next 5)
  static Future<List<Map<String, dynamic>>> getUpcomingMilestones() async {
    final allMilestones = await getAllMilestones();
    return allMilestones
        .where((milestone) => !milestone['isPassed'])
        .take(5)
        .toList();
  }

  /// Get today's milestone if any
  static Future<Map<String, dynamic>?> getTodaysMilestone() async {
    final allMilestones = await getAllMilestones();
    try {
      return allMilestones.firstWhere((milestone) => milestone['isToday']);
    } catch (e) {
      return null;
    }
  }

  /// Check if today is a milestone and we haven't shown notification yet
  static Future<bool> shouldShowMilestoneNotification() async {
    final todaysMilestone = await getTodaysMilestone();
    if (todaysMilestone == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final lastChecked = prefs.getString(_lastCheckedKey);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastChecked != today) {
      await prefs.setString(_lastCheckedKey, today);
      return true;
    }
    
    return false;
  }

  /// Get milestone celebration message
  static String getMilestoneMessage(Map<String, dynamic> milestone) {
    final title = milestone['title'] as String;
    final type = milestone['type'] as String;
    
    if (type == 'anniversary') {
      return '$title을 축하합니다! 🎉\n사랑이 더욱 깊어지는 특별한 날이에요.';
    } else {
      return '$title 달성을 축하합니다! 🎊\n함께한 소중한 시간들이 쌓여가고 있어요.';
    }
  }

  /// Get milestone icon
  static String getMilestoneIcon(Map<String, dynamic> milestone) {
    final type = milestone['type'] as String;
    
    if (type == 'anniversary') {
      return '💝';
    } else {
      return '🎯';
    }
  }

  /// Format date for display
  static String formatMilestoneDate(DateTime date) {
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    
    return '${date.year}년 ${monthNames[date.month - 1]} ${date.day}일';
  }

  /// Get days until milestone as string
  static String getDaysUntilString(int daysUntil) {
    if (daysUntil == 0) {
      return '오늘!';
    } else if (daysUntil == 1) {
      return '내일';
    } else if (daysUntil < 0) {
      return '지난 기념일';
    } else {
      return '$daysUntil일 후';
    }
  }

  /// Clear milestone notification flag (for testing)
  static Future<void> clearNotificationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCheckedKey);
  }
}