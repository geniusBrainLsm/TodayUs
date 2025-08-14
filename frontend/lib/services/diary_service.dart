import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';
import '../config/api_endpoints.dart';

class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  /// 새 일기 생성
  Future<Map<String, dynamic>> createDiary({
    required String title,
    required String content,
    required DateTime diaryDate,
    required String moodEmoji,
    String? imageUrl,
  }) async {
    try {
      print('=== Creating Diary ===');
      print('Title: $title');
      print('Content length: ${content.length}');
      print('Date: ${diaryDate.toIso8601String().split('T')[0]}');
      print('Mood: $moodEmoji');
      print('ImageUrl: $imageUrl');
      print('API Endpoint: ${ApiEndpoints.diaries}');
      
      // 인증 토큰 확인
      final authToken = await ApiService.getAuthToken();
      print('Auth token: ${authToken != null ? "Present (${authToken.substring(0, 20)}...)" : "Missing"}');
      
      final requestBody = {
        'title': title,
        'content': content,
        'diaryDate': diaryDate.toIso8601String().split('T')[0],
        'moodEmoji': moodEmoji,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
      
      print('Request body: $requestBody');
      
      final response = await ApiService.post(
        ApiEndpoints.diaries,
        requestBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (ApiService.isSuccessful(response.statusCode)) {
        final result = ApiService.parseResponse(response) ?? {};
        print('Parsed response: $result');
        return result;
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        ApiService.handleErrorResponse(response);
        return {};
      }
    } catch (e) {
      print('Error creating diary: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// 일기 목록 조회 (페이지네이션)
  Future<List<Map<String, dynamic>>> getDiaries({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final endpoint = ApiEndpoints.withPagination(
        ApiEndpoints.diaries,
        page: page,
        size: size,
      );
      
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['content'] ?? []);
      } else {
        ApiService.handleErrorResponse(response);
        return [];
      }
    } catch (e) {
      print('Error getting diaries: $e');
      return [];
    }
  }

  /// 특정 일기 조회
  Future<Map<String, dynamic>?> getDiary(int diaryId) async {
    try {
      final response = await ApiService.get(ApiEndpoints.diaryById(diaryId));

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error getting diary: $e');
      return null;
    }
  }

  /// 일기 수정
  Future<Map<String, dynamic>?> updateDiary({
    required int diaryId,
    required String title,
    required String content,
    required DateTime diaryDate,
    required String moodEmoji,
    String? imageUrl,
  }) async {
    try {
      final response = await ApiService.put(
        ApiEndpoints.diaryById(diaryId),
        {
          'title': title,
          'content': content,
          'diaryDate': diaryDate.toIso8601String().split('T')[0],
          'moodEmoji': moodEmoji,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error updating diary: $e');
      rethrow;
    }
  }

  /// 일기 삭제
  Future<bool> deleteDiary(int diaryId) async {
    try {
      final response = await ApiService.delete(ApiEndpoints.diaryById(diaryId));

      if (ApiService.isSuccessful(response.statusCode)) {
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (e) {
      print('Error deleting diary: $e');
      return false;
    }
  }

  /// 일기에 댓글 추가
  Future<Map<String, dynamic>?> addComment({
    required int diaryId,
    required String comment,
  }) async {
    try {
      print('=== Adding Comment to Diary ===');
      print('Diary ID: $diaryId');
      print('Comment: $comment');
      print('API Endpoint: ${ApiEndpoints.diaryComments(diaryId)}');
      
      // 인증 토큰 확인
      final authToken = await ApiService.getAuthToken();
      print('Auth token: ${authToken != null ? "Present (${authToken.substring(0, 20)}...)" : "Missing"}');
      
      final requestBody = {'content': comment};
      print('Request body: $requestBody');
      
      final response = await ApiService.post(
        ApiEndpoints.diaryComments(diaryId),
        requestBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (ApiService.isSuccessful(response.statusCode)) {
        final result = ApiService.parseResponse(response);
        print('Parsed response: $result');
        return result;
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error adding comment: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// 최근 일기 조회
  Future<List<Map<String, dynamic>>> getRecentDiaries({int limit = 10}) async {
    try {
      final endpoint = ApiEndpoints.withParams(
        ApiEndpoints.recentDiaries,
        {'limit': limit},
      );
      
      print('🟡 Recent diaries API endpoint: $endpoint');
      
      final response = await ApiService.get(endpoint);
      
      print('🟡 Recent diaries response status: ${response.statusCode}');
      print('🟡 Recent diaries response body: ${response.body}');

      if (ApiService.isSuccessful(response.statusCode)) {
        try {
          // Backend returns List directly, so parse as List
          final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
          print('🟡 Parsed data type: ${data.runtimeType}');
          print('🟡 Parsed data content: $data');
          
          final result = data.map((item) => item as Map<String, dynamic>).toList();
          print('🟢 Recent diaries result count: ${result.length}');
          return result;
        } catch (e) {
          print('🔴 Error parsing recent diaries JSON: $e');
          return [];
        }
      } else {
        print('🔴 API call failed with status: ${response.statusCode}');
        print('🔴 Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('🔴 Error getting recent diaries: $e');
      return [];
    }
  }

  /// 감정 통계 조회
  Future<List<Map<String, dynamic>>> getEmotionStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final endpoint = ApiEndpoints.withDateRange(
        ApiEndpoints.emotionStats,
        startDate: startDate,
        endDate: endDate,
      );
      
      print('🟡 Emotion stats API endpoint: $endpoint');
      
      final response = await ApiService.get(endpoint);
      
      print('🟡 Emotion stats response status: ${response.statusCode}');
      print('🟡 Emotion stats response body: ${response.body}');

      if (ApiService.isSuccessful(response.statusCode)) {
        try {
          // Backend returns List directly, so parse as List
          final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
          print('🟡 Emotion stats parsed data type: ${data.runtimeType}');
          print('🟡 Emotion stats parsed data content: $data');
          
          final result = data.map((item) => item as Map<String, dynamic>).toList();
          print('🟢 Emotion stats result count: ${result.length}');
          return result;
        } catch (e) {
          print('🔴 Error parsing emotion stats JSON: $e');
          return [];
        }
      } else {
        print('🔴 Emotion stats API call failed with status: ${response.statusCode}');
        print('🔴 Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('🔴 Error getting emotion stats: $e');
      return [];
    }
  }

  /// 주간 감정 요약 조회
  Future<String> getWeeklyEmotionSummary() async {
    try {
      final response = await ApiService.get(ApiEndpoints.weeklyEmotionSummary);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return data?['summary'] ?? '감정 요약을 불러올 수 없습니다.';
      } else {
        return '감정 요약을 불러올 수 없습니다.';
      }
    } catch (e) {
      print('Error getting weekly emotion summary: $e');
      return '감정 요약을 불러올 수 없습니다.';
    }
  }

  /// 커플 요약 조회
  Future<String> getCoupleSummary() async {
    try {
      final response = await ApiService.get(ApiEndpoints.coupleSummary);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        final status = data?['status'] as String?;
        final summary = data?['summary'] as String?;
        final partnerName = data?['partnerName'] as String?;
        
        // 상태에 따라 다른 메시지 반환
        switch (status) {
          case 'BOTH_WRITTEN':
            // 양쪽 모두 작성한 경우 - AI 요약 표시
            return summary ?? '서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕';
          
          case 'ONLY_USER_WRITTEN':
            // 내가만 작성한 경우
            return '${partnerName ?? '파트너'}님이 아직\n일기를 작성하지 않았어요\n\n함께 하루를 나누면\n더욱 특별한 추억이 될 거예요 💝';
          
          case 'ONLY_PARTNER_WRITTEN':
            // 파트너만 작성한 경우
            return '${partnerName ?? '파트너'}님이 먼저\n일기를 작성했어요!\n\n당신의 이야기도 들려주세요 ✨';
          
          case 'NEITHER_WRITTEN':
          default:
            // 둘 다 작성하지 않은 경우
            return '아직 오늘의 일기가\n작성되지 않았어요\n\n첫 번째 일기를 작성하고\n소중한 하루를 기록해보세요 📝';
        }
      } else {
        return '서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕';
      }
    } catch (e) {
      print('Error getting couple summary: $e');
      return '서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕';
    }
  }

  /// 이미지 업로드
  Future<String?> uploadImage(File imageFile) async {
    try {
      final streamedResponse = await ApiService.uploadFile(
        ApiEndpoints.uploadImage,
        imageFile.path,
        'image',
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return data?['imageUrl'];
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// 일기 검색
  Future<List<Map<String, dynamic>>> searchDiaries(String query) async {
    try {
      final endpoint = ApiEndpoints.withSearch(ApiEndpoints.diaries, query);
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['content'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching diaries: $e');
      return [];
    }
  }
}