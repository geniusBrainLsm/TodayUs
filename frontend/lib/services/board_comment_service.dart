import '../config/api_endpoints.dart';
import 'api_service.dart';

class BoardCommentService {
  /// 댓글 목록 조회
  static Future<List<Map<String, dynamic>>> getComments(int boardId) async {
    final response = await ApiService.get('${ApiEndpoints.baseUrl}/api/boards/$boardId/comments');

    if (ApiService.isSuccessful(response.statusCode)) {
      final parsed = ApiService.parseResponse(response);
      if (parsed is List) {
        return parsed.cast<Map<String, dynamic>>();
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
