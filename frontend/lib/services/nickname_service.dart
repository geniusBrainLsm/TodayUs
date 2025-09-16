import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:characters/characters.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../config/api_endpoints.dart';

class NicknameService {
  static const String _nicknameKey = 'user_nickname';
  static const String _nicknameSetKey = 'nickname_set';

  /// Check if the user has set their nickname
  static Future<bool> hasSetNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_nicknameSetKey) ?? false;
    } catch (error) {
      if (kDebugMode) print('Error checking nickname status: $error');
      return false;
    }
  }

  /// Get the current user's nickname
  static Future<String?> getNickname() async {
    try {
      // First try to get from API
      final response = await ApiService.get(ApiEndpoints.getNickname);
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        final nickname = data?['nickname'];
        
        if (nickname != null) {
          // Cache locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_nicknameKey, nickname);
          await prefs.setBool(_nicknameSetKey, true);
          return nickname;
        }
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_nicknameKey);
    } catch (error) {
      if (kDebugMode) print('Error getting nickname: $error');
      
      // Fallback to local storage on error
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_nicknameKey);
      } catch (localError) {
        if (kDebugMode) print('Error getting local nickname: $localError');
        return null;
      }
    }
  }

  /// Save the user's nickname
  static Future<bool> saveNickname(String nickname) async {
    try {
      // Validate first
      final validation = validateNickname(nickname);
      if (!validation['isValid']) {
        if (kDebugMode) print('Nickname validation failed: ${validation['error']}');
        return false;
      }
      
      // Save to API using PUT method
      print('🟡 닉네임 설정 API 호출: ${ApiEndpoints.setNickname}');
      
      // 토큰 확인
      final token = await ApiService.getAuthToken();
      print('🟡 JWT 토큰 존재 여부: ${token != null ? "YES" : "NO"}');
      if (token != null) {
        print('🟡 JWT 토큰: ${token.substring(0, 20)}...');
      }
      
      final response = await ApiService.put(
        ApiEndpoints.setNickname,
        {'nickname': nickname.trim()},
      );
      
      print('🟡 닉네임 설정 응답: ${response.statusCode}');
      print('🟡 응답 본문: ${response.body}');
      
      if (ApiService.isSuccessful(response.statusCode)) {
        // Parse response and save onboarding status
        final data = ApiService.parseResponse(response);
        if (data != null && data['onboarding'] != null) {
          await AuthService.saveOnboardingStatus(data['onboarding']);
          print('🟢 온보딩 상태 업데이트: ${data['onboarding']}');
        }
        
        // Save locally on success
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_nicknameKey, nickname.trim());
        await prefs.setBool(_nicknameSetKey, true);
        
        if (kDebugMode) print('Nickname saved successfully: $nickname');
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (error) {
      if (kDebugMode) print('Error saving nickname: $error');
      return false;
    }
  }

  /// Validate nickname format
  static Map<String, dynamic> validateNickname(String nickname) {
    final trimmed = nickname.trim();
    
    if (trimmed.isEmpty) {
      return {'isValid': false, 'error': '닉네임을 입력해 주세요'};
    }
    
    // 문자 길이 체크 (이모지 등 멀티바이트 문자 고려)
    final characters = trimmed.characters;
    
    if (characters.length < 2) {
      return {'isValid': false, 'error': '닉네임은 2글자 이상이어야 합니다'};
    }
    
    if (characters.length > 10) {
      return {'isValid': false, 'error': '닉네임은 10글자 이하여야 합니다'};
    }
    
    // 금지된 문자나 패턴 체크 (필요시 추가)
    // 예: 연속된 공백, 특정 금지어 등
    if (trimmed.contains(RegExp(r'\s{2,}'))) {
      return {'isValid': false, 'error': '연속된 공백은 사용할 수 없습니다'};
    }
    
    return {'isValid': true, 'error': ''};
  }

  /// Check if nickname is available
  static Future<bool> checkNicknameAvailability(String nickname) async {
    try {
      // Validate first
      final validation = validateNickname(nickname);
      if (!validation['isValid']) {
        return false;
      }
      
      final response = await ApiService.get(
        ApiEndpoints.checkNicknameAvailability(nickname.trim()),
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        return data?['available'] ?? false;
      } else {
        return false;
      }
    } catch (error) {
      if (kDebugMode) print('Error checking nickname availability: $error');
      return false;
    }
  }
  
  /// Update the user's nickname (alias for saveNickname)
  static Future<bool> updateNickname(String nickname) async {
    return await saveNickname(nickname);
  }
  
  /// Clear nickname data (for logout/reset)
  static Future<void> clearNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_nicknameKey);
      await prefs.remove(_nicknameSetKey);
    } catch (error) {
      if (kDebugMode) print('Error clearing nickname: $error');
    }
  }
}