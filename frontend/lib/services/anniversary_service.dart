import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../config/api_endpoints.dart';
import 'dart:convert';

class AnniversaryService {
  // Local storage keys for caching
  static const String _anniversaryKey = 'anniversary_date';
  static const String _hasSetAnniversaryKey = 'has_set_anniversary';

  /// Save anniversary date to backend and local cache
  static Future<bool> saveAnniversary(DateTime anniversaryDate) async {
    try {
      // Validate first
      final validation = validateAnniversaryDate(anniversaryDate);
      if (!validation['isValid']) {
        print('Anniversary validation failed: ${validation['error']}');
        return false;
      }
      
      final response = await ApiService.post(
        ApiEndpoints.anniversaries,
        {
          'anniversaryDate': anniversaryDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        },
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        // Cache the result locally
        await _cacheAnniversary(anniversaryDate);
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        // Fallback to local storage if server fails
        return await _saveAnniversaryLocally(anniversaryDate);
      }
    } catch (e) {
      print('Error saving anniversary to server: $e');
      // Fallback to local storage if server fails
      return await _saveAnniversaryLocally(anniversaryDate);
    }
  }

  /// Get anniversary date from backend or local cache
  static Future<Map<String, dynamic>?> getAnniversary() async {
    try {
      print('🔵 Fetching anniversary from server...');
      final response = await ApiService.get(ApiEndpoints.anniversaries);
      print('🔵 Server response status: ${response.statusCode}');
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        print('🔵 Server response data: $data');
        
        if (data != null) {
          if (data['anniversaryDate'] != null) {
            final anniversary = DateTime.parse(data['anniversaryDate']);
            print('🟢 Anniversary found on server: $anniversary');
            // Cache the result locally
            await _cacheAnniversary(anniversary);
            
            return {
              'anniversaryDate': anniversary,
              'canEdit': data['canEdit'] as bool? ?? true,
              'setterName': data['setterName'] as String?,
              'daysSince': data['daysSince'] as int?,
            };
          } else {
            print('🟡 Anniversary not set on server');
            // Clear local cache since server has no anniversary
            await clearAnniversary();
            
            return {
              'anniversaryDate': null,
              'canEdit': true,
              'setterName': null,
              'daysSince': null,
            };
          }
        }
      } else if (response.statusCode == 204) {
        print('🟡 Server returned 204 - Anniversary not set');
        // Clear local cache since server has no anniversary
        await clearAnniversary();
        
        return {
          'anniversaryDate': null,
          'canEdit': true,
          'setterName': null,
          'daysSince': null,
        };
      }
      
      print('🔴 Server request failed, checking local cache...');
      // Only use local storage as fallback if we explicitly can't reach the server
      final localDate = await _getAnniversaryLocally();
      print('🟡 Local cache anniversary: $localDate');
      
      // If we have local data but server is unreachable, warn user
      if (localDate != null) {
        print('⚠️ Using local cache data - server might be unreachable');
      }
      
      return {
        'anniversaryDate': localDate,
        'canEdit': true,
        'setterName': localDate != null ? 'Local Cache' : null,
        'daysSince': localDate != null ? calculateDaysSince(localDate) : null,
      };
    } catch (e) {
      print('🔴 Error getting anniversary from server: $e');
      // Only fallback to local storage in case of actual error
      final localDate = await _getAnniversaryLocally();
      print('🟡 Using local cache due to error: $localDate');
      
      return {
        'anniversaryDate': localDate,
        'canEdit': true,
        'setterName': localDate != null ? 'Local Cache' : null,
        'daysSince': localDate != null ? calculateDaysSince(localDate) : null,
      };
    }
  }

  /// Update anniversary date
  static Future<bool> updateAnniversary(DateTime anniversaryDate) async {
    try {
      // Validate first
      final validation = validateAnniversaryDate(anniversaryDate);
      if (!validation['isValid']) {
        print('Anniversary validation failed: ${validation['error']}');
        return false;
      }
      
      final response = await ApiService.put(
        ApiEndpoints.anniversaries,
        {
          'anniversaryDate': anniversaryDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        },
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        // Cache the result locally
        await _cacheAnniversary(anniversaryDate);
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (e) {
      print('Error updating anniversary on server: $e');
      return false;
    }
  }

  /// Check if user has set their anniversary
  static Future<bool> hasSetAnniversary() async {
    final anniversaryData = await getAnniversary();
    return anniversaryData != null && anniversaryData['anniversaryDate'] != null;
  }

  // Local storage fallback methods
  static Future<bool> _saveAnniversaryLocally(DateTime anniversaryDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_anniversaryKey, anniversaryDate.toIso8601String());
      await prefs.setBool(_hasSetAnniversaryKey, true);
      return true;
    } catch (e) {
      print('Error saving anniversary locally: $e');
      return false;
    }
  }

  static Future<DateTime?> _getAnniversaryLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anniversaryString = prefs.getString(_anniversaryKey);
      
      if (anniversaryString != null) {
        return DateTime.parse(anniversaryString);
      }
      
      return null;
    } catch (e) {
      print('Error getting anniversary locally: $e');
      return null;
    }
  }

  static Future<void> _cacheAnniversary(DateTime anniversaryDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_anniversaryKey, anniversaryDate.toIso8601String());
      await prefs.setBool(_hasSetAnniversaryKey, true);
    } catch (e) {
      print('Error caching anniversary: $e');
    }
  }

  /// Calculate days since anniversary
  static int calculateDaysSince(DateTime anniversaryDate) {
    final now = DateTime.now();
    final difference = now.difference(anniversaryDate);
    return difference.inDays + 1; // +1 to include the anniversary day itself
  }

  /// Get formatted anniversary display string
  static String getFormattedAnniversary(DateTime anniversaryDate) {
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    
    return '${anniversaryDate.year}년 ${monthNames[anniversaryDate.month - 1]} ${anniversaryDate.day}일';
  }

  /// Get days count display string (e.g., "D+123")
  static String getDaysCountDisplay(DateTime anniversaryDate) {
    final days = calculateDaysSince(anniversaryDate);
    return 'D+$days';
  }

  /// Delete anniversary from backend and clear local cache
  static Future<bool> deleteAnniversary() async {
    try {
      final response = await ApiService.delete(ApiEndpoints.anniversaries);
      
      if (ApiService.isSuccessful(response.statusCode)) {
        // Clear local cache
        await clearAnniversary();
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (e) {
      print('Error deleting anniversary from server: $e');
      return false;
    }
  }
  
  /// Clear anniversary data (for logout or reset)
  static Future<bool> clearAnniversary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_anniversaryKey);
      await prefs.remove(_hasSetAnniversaryKey);
      return true;
    } catch (e) {
      print('Error clearing anniversary: $e');
      return false;
    }
  }

  /// Validate anniversary date
  static Map<String, dynamic> validateAnniversaryDate(DateTime date) {
    final now = DateTime.now();
    
    // Check if date is in the future
    if (date.isAfter(now)) {
      return {
        'isValid': false,
        'error': '미래 날짜는 설정할 수 없습니다.',
      };
    }
    
    // Check if date is too far in the past (more than 50 years)
    final fiftyYearsAgo = DateTime(now.year - 50, now.month, now.day);
    if (date.isBefore(fiftyYearsAgo)) {
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

  /// Get special milestones (100 days, 200 days, 1 year, etc.)
  static List<Map<String, dynamic>> getUpcomingMilestones(DateTime anniversaryDate) {
    final daysSince = calculateDaysSince(anniversaryDate);
    final milestones = <Map<String, dynamic>>[];
    
    // Common milestones
    final targets = [100, 200, 300, 365, 500, 730, 1000, 1095, 1460, 1825];
    
    for (final target in targets) {
      if (target > daysSince) {
        final daysUntil = target - daysSince;
        final milestoneDate = DateTime.now().add(Duration(days: daysUntil));
        
        String title;
        if (target == 365) {
          title = '1년';
        } else if (target == 730) {
          title = '2년';
        } else if (target == 1095) {
          title = '3년';
        } else if (target == 1460) {
          title = '4년';
        } else if (target == 1825) {
          title = '5년';
        } else {
          title = '$target일';
        }
        
        milestones.add({
          'title': title,
          'days': target,
          'daysUntil': daysUntil,
          'date': milestoneDate,
        });
        
        // Only show next 3 milestones
        if (milestones.length >= 3) break;
      }
    }
    
    return milestones;
  }
}