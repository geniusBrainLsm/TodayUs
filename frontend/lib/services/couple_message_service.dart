import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../config/api_endpoints.dart';

class CoupleMessageService {

  /// 새로운 대신 전달하기 메시지 생성
  static Future<Map<String, dynamic>?> createMessage(String originalMessage) async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.coupleMessages,
        {'originalMessage': originalMessage},
      );

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error creating message: $e');
      rethrow;
    }
  }

  /// 로그인 시 받을 메시지 확인 (팝업용)
  static Future<Map<String, dynamic>?> getMessageForPopup() async {
    try {
      final response = await ApiService.get(ApiEndpoints.messageForPopup);
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        
        // hasMessage가 false이면 null 반환
        if (data != null && data.containsKey('hasMessage') && data['hasMessage'] == false) {
          return null;
        }
        
        return data;
      } else {
        // 404나 다른 오류는 조용히 처리 (팝업이 없을 수 있음)
        return null;
      }
    } catch (e) {
      print('Error getting popup message: $e');
      return null;
    }
  }

  /// 메시지를 전달됨 상태로 변경 (팝업 표시 후)
  static Future<bool> markAsDelivered(int messageId) async {
    try {
      final response = await ApiService.put(
        ApiEndpoints.markAsDelivered(messageId),
        {},
      );

      return ApiService.isSuccessful(response.statusCode);
    } catch (e) {
      print('Error marking as delivered: $e');
      return false;
    }
  }

  /// 메시지를 읽음 상태로 변경
  static Future<bool> markAsRead(int messageId) async {
    try {
      final response = await ApiService.put(
        ApiEndpoints.markAsRead(messageId),
        {},
      );

      return ApiService.isSuccessful(response.statusCode);
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  /// 주간 사용량 조회
  static Future<Map<String, dynamic>?> getWeeklyUsage() async {
    try {
      final response = await ApiService.get(ApiEndpoints.weeklyUsage);

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        print('Failed to get weekly usage: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting weekly usage: $e');
      return null;
    }
  }

  /// 메시지 히스토리 조회
  static Future<List<Map<String, dynamic>>?> getMessageHistory() async {
    try {
      final response = await ApiService.get(ApiEndpoints.messageHistory);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['messages'] ?? []);
      } else {
        print('Failed to get message history: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting message history: $e');
      return null;
    }
  }
}