import 'dart:convert';
import 'api_service.dart';
import '../config/api_endpoints.dart';

class WeeklyFeedbackService {
  static final WeeklyFeedbackService _instance = WeeklyFeedbackService._internal();
  factory WeeklyFeedbackService() => _instance;
  WeeklyFeedbackService._internal();

  /// 현재 시간이 피드백 작성 가능한지 확인
  Future<Map<String, dynamic>> checkAvailability() async {
    try {
      final response = await ApiService.get('${ApiEndpoints.baseUrl}/api/weekly-feedback/availability');

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response) ?? {};
      } else {
        ApiService.handleErrorResponse(response);
        return {};
      }
    } catch (e) {
      print('Error checking feedback availability: $e');
      return {};
    }
  }

  /// 주간 피드백 작성
  Future<Map<String, dynamic>?> createFeedback(String message) async {
    try {
      final response = await ApiService.post(
        '${ApiEndpoints.baseUrl}/api/weekly-feedback',
        {'message': message},
      );

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error creating weekly feedback: $e');
      rethrow;
    }
  }

  /// 읽지 않은 피드백 목록 조회
  Future<List<Map<String, dynamic>>> getUnreadFeedbacks() async {
    try {
      final response = await ApiService.get('${ApiEndpoints.baseUrl}/api/weekly-feedback/unread');

      if (ApiService.isSuccessful(response.statusCode)) {
        if (response.body.isEmpty) {
          return [];
        }
        
        final dynamic jsonData = json.decode(response.body);
        if (jsonData is List) {
          return List<Map<String, dynamic>>.from(jsonData);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting unread feedbacks: $e');
      return [];
    }
  }

  /// 피드백 히스토리 조회
  Future<Map<String, dynamic>> getFeedbackHistory({int page = 0, int size = 10}) async {
    try {
      final endpoint = '${ApiEndpoints.baseUrl}/api/weekly-feedback/history?page=$page&size=$size';
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response) ?? {};
      } else {
        return {
          'content': [],
          'totalElements': 0,
          'totalPages': 0,
          'size': size,
          'number': page,
        };
      }
    } catch (e) {
      print('Error getting feedback history: $e');
      return {
        'content': [],
        'totalElements': 0,
        'totalPages': 0,
        'size': size,
        'number': page,
      };
    }
  }

  /// 특정 피드백 상세 조회
  Future<Map<String, dynamic>?> getFeedback(int feedbackId) async {
    try {
      final response = await ApiService.get('${ApiEndpoints.baseUrl}/api/weekly-feedback/$feedbackId');

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error getting feedback detail: $e');
      return null;
    }
  }

  /// 피드백 가능 여부를 문자열로 반환
  String getAvailabilityMessage(Map<String, dynamic> availability) {
    final canWrite = availability['canWrite'] as bool? ?? false;
    final message = availability['message'] as String? ?? '';
    final alreadyWritten = availability['alreadyWritten'] as bool? ?? false;
    
    if (canWrite) {
      return '이번 주 서운했던 점을 작성할 수 있습니다.';
    } else if (alreadyWritten) {
      return '이번 주에 이미 피드백을 작성하셨습니다.';
    } else {
      return message.isNotEmpty 
          ? message 
          : '피드백은 매주 토요일 오전 7시부터 오후 11시 59분까지만 작성 가능합니다.';
    }
  }

  /// 다음 작성 가능 시간 포맷
  String? getNextAvailableTimeString(Map<String, dynamic> availability) {
    final nextAvailableTimeStr = availability['nextAvailableTime'] as String?;
    
    if (nextAvailableTimeStr == null) return null;
    
    try {
      final nextAvailableTime = DateTime.parse(nextAvailableTimeStr);
      final now = DateTime.now();
      final difference = nextAvailableTime.difference(now);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}일 ${difference.inHours % 24}시간 후';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 ${difference.inMinutes % 60}분 후';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 후';
      } else {
        return '곧 가능';
      }
    } catch (e) {
      print('Error parsing next available time: $e');
      return null;
    }
  }
}