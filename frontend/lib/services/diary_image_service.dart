import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import '../config/api_endpoints.dart';

class DiaryImageService {
  
  /// 일기 이미지 업로드 (임시, 일기 ID 없이)
  static Future<String?> uploadDiaryImage(File imageFile) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final uri = Uri.parse(ApiEndpoints.uploadDiaryImage);
      final request = http.MultipartRequest('POST', uri);

      // 헤더 설정
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // 파일 추가
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'diary_image.${_getFileExtension(imageFile.path)}',
      );
      request.files.add(multipartFile);

      if (kDebugMode) {
        print('🟡 일기 이미지 업로드 요청: ${uri.toString()}');
        print('🟡 파일 크기: ${await imageFile.length()} bytes');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print('🟡 일기 이미지 업로드 응답: ${response.statusCode}');
        print('🟡 응답 본문: $responseBody');
      }

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          return data['imageUrl'];
        } else {
          throw Exception(data['message'] ?? '업로드에 실패했습니다.');
        }
      } else {
        final data = json.decode(responseBody);
        throw Exception(data['message'] ?? '서버 오류가 발생했습니다.');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error uploading diary image: $error');
      }
      rethrow;
    }
  }

  /// 특정 일기에 이미지 업로드 (일기 ID와 함께)
  static Future<String?> uploadDiaryImageWithId(File imageFile, int diaryId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final uri = Uri.parse(ApiEndpoints.diaryImage(diaryId));
      final request = http.MultipartRequest('POST', uri);

      // 헤더 설정
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // 파일 추가
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'diary_image.${_getFileExtension(imageFile.path)}',
      );
      request.files.add(multipartFile);

      if (kDebugMode) {
        print('🟡 일기 이미지 업로드 요청 (ID: $diaryId): ${uri.toString()}');
        print('🟡 파일 크기: ${await imageFile.length()} bytes');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print('🟡 일기 이미지 업로드 응답: ${response.statusCode}');
        print('🟡 응답 본문: $responseBody');
      }

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          return data['imageUrl'];
        } else {
          throw Exception(data['message'] ?? '업로드에 실패했습니다.');
        }
      } else {
        final data = json.decode(responseBody);
        throw Exception(data['message'] ?? '서버 오류가 발생했습니다.');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error uploading diary image with ID: $error');
      }
      rethrow;
    }
  }

  /// 일기 이미지 삭제
  static Future<void> deleteDiaryImage(int diaryId) async {
    try {
      final response = await ApiService.delete(ApiEndpoints.diaryImage(diaryId));

      if (kDebugMode) {
        print('🟡 일기 이미지 삭제 응답: ${response.statusCode}');
        print('🟡 응답 본문: ${response.body}');
      }

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        if (data?['success'] != true) {
          throw Exception(data?['message'] ?? '삭제에 실패했습니다.');
        }
      } else {
        ApiService.handleErrorResponse(response);
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error deleting diary image: $error');
      }
      rethrow;
    }
  }

  /// 이미지 파일 유효성 검증
  static bool validateImageFile(File file) {
    try {
      // 파일 크기 체크 (10MB)
      final fileSize = file.lengthSync();
      if (fileSize > 10 * 1024 * 1024) {
        return false;
      }

      // 파일 확장자 체크
      final extension = _getFileExtension(file.path).toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      
      return allowedExtensions.contains(extension);
    } catch (e) {
      if (kDebugMode) {
        print('Error validating image file: $e');
      }
      return false;
    }
  }

  /// 파일 확장자 추출
  static String _getFileExtension(String filePath) {
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filePath.length - 1) {
      return '';
    }
    return filePath.substring(lastDotIndex + 1);
  }

  /// 이미지 크기 정보 가져오기
  static Future<Map<String, int>?> getImageDimensions(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      
      return {
        'fileSize': fileSize,
        'width': 0, // 실제 구현시 image 패키지 사용
        'height': 0, // 실제 구현시 image 패키지 사용
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting image dimensions: $e');
      }
      return null;
    }
  }
}