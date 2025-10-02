import 'dart:convert';
import '../config/api_endpoints.dart';
import 'api_service.dart';

class BoardCommentService {
  /// 댓글 목록 조회
  static Future<List<Map<String, dynamic>>> getComments(int boardId) async {
    final response = await ApiService.get('${ApiEndpoints.baseUrl}/api/boards/$boardId/comments');

    if (ApiService.isSuccessful(response.statusCode)) {
      if (response.body.isEmpty) {
        return [];
      }
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) => item as Map<String, dynamic>).toList();
        }
      } catch (e) {
        print('Error parsing comments: $e');
      }
      return [];
    } else {
      ApiService.handleErrorResponse(response);
      return [];
    }
  }

  /// 댓글 작성
  static Future<Map<String, dynamic>?> createComment({
    required int boardId,
    required String content,
  }) async {
    final response = await ApiService.post(
      '${ApiEndpoints.baseUrl}/api/boards/$boardId/comments',
      {'content': content},
    );

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response);
    } else {
      ApiService.handleErrorResponse(response);
      return null;
    }
  }

  /// 댓글 수정
  static Future<Map<String, dynamic>?> updateComment({
    required int boardId,
    required int commentId,
    required String content,
  }) async {
    final response = await ApiService.put(
      '${ApiEndpoints.baseUrl}/api/boards/$boardId/comments/$commentId',
      {'content': content},
    );

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response);
    } else {
      ApiService.handleErrorResponse(response);
      return null;
    }
  }

  /// 댓글 삭제
  static Future<bool> deleteComment({
    required int boardId,
    required int commentId,
  }) async {
    final response = await ApiService.delete(
      '${ApiEndpoints.baseUrl}/api/boards/$boardId/comments/$commentId',
    );
    return ApiService.isSuccessful(response.statusCode);
  }
}
