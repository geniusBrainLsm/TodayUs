import '../config/api_endpoints.dart';
import 'api_service.dart';

class BoardService {
  /// 게시글 생성
  static Future<Map<String, dynamic>> createBoard({
    required String title,
    required String content,
    required String type, // NOTICE, SUGGESTION, FAQ
  }) async {
    final response = await ApiService.post(
      ApiEndpoints.boards,
      {
        'title': title,
        'content': content,
        'type': type,
      },
    );

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response) ?? {};
    } else {
      ApiService.handleErrorResponse(response);
      return {};
    }
  }

  /// 게시글 목록 조회
  static Future<Map<String, dynamic>> getBoards({
    int page = 0,
    int size = 20,
  }) async {
    final endpoint = ApiEndpoints.withPagination(
      ApiEndpoints.boards,
      page: page,
      size: size,
    );

    final response = await ApiService.get(endpoint);

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response) ?? {};
    } else {
      ApiService.handleErrorResponse(response);
      return {};
    }
  }

  /// 타입별 게시글 조회
  static Future<Map<String, dynamic>> getBoardsByType({
    required String type,
    int page = 0,
    int size = 20,
  }) async {
    final endpoint = ApiEndpoints.withPagination(
      ApiEndpoints.boardByType(type),
      page: page,
      size: size,
    );

    final response = await ApiService.get(endpoint);

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response) ?? {};
    } else {
      ApiService.handleErrorResponse(response);
      return {};
    }
  }

  /// 게시글 상세 조회
  static Future<Map<String, dynamic>?> getBoardDetail(int boardId) async {
    final response = await ApiService.get(ApiEndpoints.boardById(boardId));

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response);
    } else {
      ApiService.handleErrorResponse(response);
      return null;
    }
  }

  /// 게시글 수정
  static Future<Map<String, dynamic>?> updateBoard({
    required int boardId,
    required String title,
    required String content,
  }) async {
    final response = await ApiService.put(
      ApiEndpoints.boardById(boardId),
      {
        'title': title,
        'content': content,
      },
    );

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response);
    } else {
      ApiService.handleErrorResponse(response);
      return null;
    }
  }

  /// 게시글 삭제
  static Future<bool> deleteBoard(int boardId) async {
    final response = await ApiService.delete(ApiEndpoints.boardById(boardId));
    return ApiService.isSuccessful(response.statusCode);
  }

  /// 내가 작성한 게시글 조회
  static Future<Map<String, dynamic>> getMyBoards({
    int page = 0,
    int size = 20,
  }) async {
    final endpoint = ApiEndpoints.withPagination(
      ApiEndpoints.myBoards,
      page: page,
      size: size,
    );

    final response = await ApiService.get(endpoint);

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response) ?? {};
    } else {
      ApiService.handleErrorResponse(response);
      return {};
    }
  }

  /// 게시글 검색
  static Future<Map<String, dynamic>> searchBoards({
    required String keyword,
    int page = 0,
    int size = 20,
  }) async {
    final endpoint = ApiEndpoints.withParams(
      ApiEndpoints.searchBoards,
      {'keyword': keyword, 'page': page, 'size': size},
    );

    final response = await ApiService.get(endpoint);

    if (ApiService.isSuccessful(response.statusCode)) {
      return ApiService.parseResponse(response) ?? {};
    } else {
      ApiService.handleErrorResponse(response);
      return {};
    }
  }

  /// 고정된 공지사항 조회
  static Future<List<Map<String, dynamic>>> getPinnedNotices() async {
    final response = await ApiService.get(ApiEndpoints.pinnedNotices);

    if (ApiService.isSuccessful(response.statusCode)) {
      final data = ApiService.parseResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } else {
      return [];
    }
  }
}
