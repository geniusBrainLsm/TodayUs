import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../config/api_endpoints.dart';

class TimeCapsuleService {
  static final TimeCapsuleService _instance = TimeCapsuleService._internal();
  factory TimeCapsuleService() => _instance;
  TimeCapsuleService._internal();

  /// 새 타임캡슐 생성
  Future<Map<String, dynamic>> createTimeCapsule({
    required String title,
    required String content,
    required DateTime openDate,
    required String type,
  }) async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.timeCapsules,
        {
          'title': title,
          'content': content,
          'openDate': openDate.toIso8601String(),
          'type': type,
        },
      );

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response) ?? {};
      } else {
        ApiService.handleErrorResponse(response);
        return {};
      }
    } catch (e) {
      print('Error creating time capsule: $e');
      rethrow;
    }
  }

  /// 타임캡슐 목록 조회 (페이지네이션)
  Future<List<Map<String, dynamic>>> getTimeCapsules({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final endpoint = ApiEndpoints.withPagination(
        ApiEndpoints.timeCapsules,
        page: page,
        size: size,
      );
      
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['content'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting time capsules: $e');
      return [];
    }
  }

  /// 타임캡슐 목록 조회 (전체 페이지네이션 정보 포함)
  Future<Map<String, dynamic>> getTimeCapsulesPaginated({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final endpoint = ApiEndpoints.withPagination(
        ApiEndpoints.timeCapsules,
        page: page,
        size: size,
      );
      
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response) ?? {
          'content': [],
          'last': true,
          'totalElements': 0,
          'totalPages': 0,
        };
      } else {
        return {
          'content': [],
          'last': true,
          'totalElements': 0,
          'totalPages': 0,
        };
      }
    } catch (e) {
      print('Error getting time capsules: $e');
      return {
        'content': [],
        'last': true,
        'totalElements': 0,
        'totalPages': 0,
      };
    }
  }

  /// 특정 타임캡슐 조회
  Future<Map<String, dynamic>?> getTimeCapsule(int timeCapsuleId) async {
    try {
      final response = await ApiService.get(
        ApiEndpoints.timeCapsuleById(timeCapsuleId),
      );

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error getting time capsule: $e');
      return null;
    }
  }

  /// 타임캡슐 열기
  Future<Map<String, dynamic>?> openTimeCapsule(int timeCapsuleId) async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.timeCapsuleOpen(timeCapsuleId),
        {},
      );

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response);
      } else {
        ApiService.handleErrorResponse(response);
        return null;
      }
    } catch (e) {
      print('Error opening time capsule: $e');
      rethrow;
    }
  }

  /// 열 수 있는 타임캡슐 조회
  Future<List<Map<String, dynamic>>> getOpenableTimeCapsules() async {
    try {
      final response = await ApiService.get(ApiEndpoints.openableTimeCapsules);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['timeCapsules'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting openable time capsules: $e');
      return [];
    }
  }

  /// 타임캡슐 요약 정보 조회
  Future<Map<String, dynamic>> getTimeCapsuleSummary() async {
    try {
      final response = await ApiService.get(ApiEndpoints.timeCapsuleSummary);

      if (ApiService.isSuccessful(response.statusCode)) {
        return ApiService.parseResponse(response) ?? {};
      } else {
        return {
          'totalCapsules': 0,
          'openableCapsules': 0,
          'openedCapsules': 0,
        };
      }
    } catch (e) {
      print('Error getting time capsule summary: $e');
      return {
        'totalCapsules': 0,
        'openableCapsules': 0,
        'openedCapsules': 0,
      };
    }
  }

  /// 타임캡슐 삭제
  Future<bool> deleteTimeCapsule(int timeCapsuleId) async {
    try {
      final response = await ApiService.delete(
        ApiEndpoints.timeCapsuleById(timeCapsuleId),
      );

      if (ApiService.isSuccessful(response.statusCode)) {
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (e) {
      print('Error deleting time capsule: $e');
      return false;
    }
  }

  /// 타입별 타임캡슐 조회
  Future<List<Map<String, dynamic>>> getTimeCapsulesByType(String type) async {
    try {
      final endpoint = ApiEndpoints.withParams(
        ApiEndpoints.timeCapsules,
        {'type': type},
      );
      
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['content'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting time capsules by type: $e');
      return [];
    }
  }

  /// 상태별 타임캡슐 조회
  Future<List<Map<String, dynamic>>> getTimeCapsulesByStatus(String status) async {
    try {
      final endpoint = ApiEndpoints.withParams(
        ApiEndpoints.timeCapsules,
        {'status': status},
      );
      
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['content'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting time capsules by status: $e');
      return [];
    }
  }

  /// 날짜 범위로 타임캡슐 조회
  Future<List<Map<String, dynamic>>> getTimeCapsulesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final endpoint = ApiEndpoints.withDateRange(
        ApiEndpoints.timeCapsules,
        startDate: startDate,
        endDate: endDate,
      );
      
      final response = await ApiService.get(endpoint);

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return List<Map<String, dynamic>>.from(data?['content'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting time capsules by date range: $e');
      return [];
    }
  }
}