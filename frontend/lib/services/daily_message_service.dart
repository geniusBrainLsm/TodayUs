import 'dart:convert';
import 'api_service.dart';
import '../config/api_endpoints.dart';

class DailyMessageService {
  /// GPT가 생성한 오늘의 일일 메시지 가져오기
  static Future<String?> getTodaysDailyMessage() async {
    try {
      print('🟡 GPT 일일 메시지 API 호출 시작');
      final response = await ApiService.get('/api/daily-message');

      print('=== DailyMessage API Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('===============================');

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        final message = data?['message'] as String?;
        print('🟢 GPT 일일 메시지 API 성공: $message');
        return message;
      } else {
        print('🔴 GPT 일일 메시지 API 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('🔴 GPT 일일 메시지 API 오류: $e');
      return null;
    }
  }
}