import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import '../config/api_endpoints.dart';

class ProfileImageService {
  
  /// 프로필 이미지 업로드
  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final uri = Uri.parse(ApiEndpoints.uploadProfileImage);
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
        filename: 'profile_image.${_getFileExtension(imageFile.path)}',
      );
      request.files.add(multipartFile);

      if (kDebugMode) {
        print('🟡 프로필 이미지 업로드 요청: ${uri.toString()}');
        print('🟡 파일 크기: ${await imageFile.length()} bytes');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print('🟡 프로필 이미지 업로드 응답: ${response.statusCode}');
        print('🟡 응답 본문: $responseBody');
      }

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          return data['profileImageUrl'];
        } else {
          throw Exception(data['message'] ?? '업로드에 실패했습니다.');
        }
      } else {
        final data = json.decode(responseBody);
        throw Exception(data['message'] ?? '서버 오류가 발생했습니다.');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error uploading profile image: $error');
      }
      rethrow;
    }
  }

  /// 프로필 이미지 삭제
  static Future<void> deleteProfileImage() async {
    try {
      final response = await ApiService.delete(ApiEndpoints.deleteProfileImage);

      if (kDebugMode) {
        print('🟡 프로필 이미지 삭제 응답: ${response.statusCode}');
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
        print('Error deleting profile image: $error');
      }
      rethrow;
    }
  }

  /// 현재 프로필 이미지 URL 조회
  static Future<String?> getProfileImageUrl() async {
    try {
      final response = await ApiService.get(ApiEndpoints.profileImage);

      if (kDebugMode) {
        print('🟡 프로필 이미지 조회 응답: ${response.statusCode}');
        print('🟡 응답 본문: ${response.body}');
      }

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        if (data?['success'] == true) {
          return data?['profileImageUrl'];
        }
      }
      
      return null;
    } catch (error) {
      if (kDebugMode) {
        print('Error getting profile image URL: $error');
      }
      return null;
    }
  }

  /// 이미지 파일 유효성 검증
  static bool validateImageFile(File file) {
    try {
      // 파일 크기 체크 (5MB)
      final fileSize = file.lengthSync();
      if (fileSize > 5 * 1024 * 1024) {
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
      // 이 기능은 image 패키지가 필요합니다.
      // 현재는 기본적인 정보만 반환
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