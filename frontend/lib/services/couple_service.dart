import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/couple_models.dart';
import 'api_service.dart';
import '../config/api_endpoints.dart';

/// Service for managing couple connections and invite codes
class CoupleService {
  static const String _connectionKey = 'couple_connection';
  
  /// Get current couple connection status from API
  static Future<CoupleConnection> getConnection() async {
    try {
      // 먼저 API에서 최신 상태 확인
      final response = await ApiService.get(ApiEndpoints.coupleInfo);
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        final coupleData = data?['couple'];
        
        if (coupleData != null) {
          // 커플이 연결된 상태
          final partnerData = coupleData['partner'];
          final connection = CoupleConnection(
            status: CoupleConnectionStatus.connected,
            partnerName: partnerData?['name'] ?? '파트너',
            partnerNickname: partnerData?['nickname'] ?? '닉네임',
            connectedAt: DateTime.now(),
          );
          
          // 로컬에 저장
          await saveConnection(connection);
          
          if (kDebugMode) print('API에서 커플 연결 상태 확인됨');
          return connection;
        }
      }
      
      // API에서 커플 정보가 없으면 활성 초대 코드 확인
      final inviteResponse = await ApiService.get(ApiEndpoints.inviteCodes);
      
      if (ApiService.isSuccessful(inviteResponse.statusCode)) {
        final inviteData = ApiService.parseResponse(inviteResponse);
        final inviteCodeData = inviteData?['inviteCode'];
        
        if (kDebugMode) print('초대 코드 API 응답: $inviteData');
        
        if (inviteCodeData != null) {
          // 활성 초대 코드가 있음
          final codeString = inviteCodeData['code'];
          final expiresAtString = inviteCodeData['expiresAt'];
          
          if (kDebugMode) print('초대 코드 데이터 파싱: code=$codeString, expiresAt=$expiresAtString');
          
          final connection = CoupleConnection(
            status: CoupleConnectionStatus.pendingInvite,
            inviteCode: codeString,
            inviteExpiresAt: expiresAtString != null ? DateTime.parse(expiresAtString) : DateTime.now().add(const Duration(hours: 24)),
          );
          
          await saveConnection(connection);
          
          if (kDebugMode) print('API에서 활성 초대 코드 확인됨: $codeString');
          return connection;
        } else {
          if (kDebugMode) print('초대 코드 데이터가 null입니다');
        }
      } else {
        if (kDebugMode) print('초대 코드 API 호출 실패: ${inviteResponse.statusCode}');
      }
      
      // API에서도 아무것도 없으면 연결되지 않은 상태
      final connection = CoupleConnection.notConnected();
      await saveConnection(connection);
      
      if (kDebugMode) print('API 확인 결과: 연결되지 않은 상태');
      return connection;
      
    } catch (error) {
      if (kDebugMode) print('Error getting couple connection from API: $error');
      
      // API 오류 시 로컬 스토리지에서 확인
      try {
        final prefs = await SharedPreferences.getInstance();
        final connectionData = prefs.getString(_connectionKey);
        
        if (connectionData != null) {
          final data = jsonDecode(connectionData);
          return CoupleConnection.fromJson(data);
        }
      } catch (localError) {
        if (kDebugMode) print('Error getting local connection: $localError');
      }
      
      return CoupleConnection.notConnected();
    }
  }

  /// Save couple connection data
  static Future<bool> saveConnection(CoupleConnection connection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionJson = jsonEncode(connection.toJson());
      await prefs.setString(_connectionKey, connectionJson);
      return true;
    } catch (error) {
      if (kDebugMode) print('Error saving couple connection: $error');
      return false;
    }
  }

  /// Generate a new invite code
  static Future<String?> generateInviteCode() async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.generateInviteCode,
        {},
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        final inviteCode = data?['inviteCode'];
        
        if (kDebugMode) print('초대 코드 생성 응답: $data');
        
        if (inviteCode != null) {
          // 전체 초대 코드 데이터도 확인
          final inviteCodeData = data?['inviteCodeData'];
          final expiresAtString = inviteCodeData?['expiresAt'];
          
          // Create connection with pending invite status
          final connection = CoupleConnection(
            status: CoupleConnectionStatus.pendingInvite,
            inviteCode: inviteCode,
            inviteExpiresAt: expiresAtString != null ? DateTime.parse(expiresAtString) : DateTime.now().add(const Duration(hours: 24)),
          );
          
          // Save the connection locally
          await saveConnection(connection);
          
          if (kDebugMode) print('초대 코드 생성 완료: $inviteCode, 만료시간: $expiresAtString');
          return inviteCode;
        } else {
          if (kDebugMode) print('초대 코드가 응답에 없음');
        }
      } else {
        ApiService.handleErrorResponse(response);
      }
      
      return null;
    } catch (error) {
      if (kDebugMode) print('Error generating invite code: $error');
      return null;
    }
  }

  /// Connect with partner using invite code
  static Future<CoupleConnection?> connectWithInviteCode(String code) async {
    try {
      if (kDebugMode) print('연결 시도: 코드 $code로 파트너와 연결 중...');
      
      // Validate the invite code format
      if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
        throw Exception('잘못된 초대 코드 형식입니다. 6자리 숫자를 입력해주세요.');
      }
      
      final response = await ApiService.post(
        ApiEndpoints.connectWithCode,
        {'code': code},
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        
        if (kDebugMode) print('연결 응답: $data');
        
        final coupleData = data?['couple'];
        final partnerData = coupleData?['partner'];
        
        final connection = CoupleConnection(
          status: CoupleConnectionStatus.connected,
          partnerName: partnerData?['name'] ?? '파트너',
          partnerNickname: partnerData?['nickname'] ?? '닉네임',
          connectedAt: DateTime.now(),
        );
        
        // Save the connection locally
        await saveConnection(connection);
        
        if (kDebugMode) print('연결 성공: ${connection.partnerName}과 연결됨');
        return connection;
      } else {
        if (kDebugMode) print('연결 실패 - 상태코드: ${response.statusCode}, 응답: ${response.body}');
        final errorData = ApiService.parseResponse(response);
        if (kDebugMode) print('연결 실패 오류 데이터: $errorData');
        
        // 구체적인 오류 메시지 던지기
        final errorMessage = errorData?['error'] ?? '연결에 실패했습니다';
        throw Exception(errorMessage);
      }
    } catch (error) {
      if (kDebugMode) print('Error connecting with invite code: $error');
      // 예외를 다시 던져서 UI에서 구체적인 오류 메시지를 표시할 수 있게 함
      rethrow;
    }
  }

  /// Disconnect from current partner
  static Future<bool> disconnect() async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.disconnectCouple,
        {},
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        // Clear local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_connectionKey);
        
        if (kDebugMode) print('커플 연결 해제 완료');
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (error) {
      if (kDebugMode) print('Error disconnecting: $error');
      return false;
    }
  }

  /// Clear all couple connection data
  static Future<void> clearConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_connectionKey);
    } catch (error) {
      if (kDebugMode) print('Error clearing connection: $error');
    }
  }


  /// Clean up expired invite codes
  static Future<void> cleanupExpiredInvites() async {
    try {
      final connection = await getConnection();
      
      if (connection.status == CoupleConnectionStatus.pendingInvite &&
          connection.inviteExpiresAt != null &&
          DateTime.now().isAfter(connection.inviteExpiresAt!)) {
        
        // Mark as expired and save
        final expiredConnection = CoupleConnection.notConnected();
        await saveConnection(expiredConnection);
        
        if (kDebugMode) print('초대 코드 만료 처리: 1개 코드 만료');
      }
    } catch (error) {
      if (kDebugMode) print('Error cleaning up expired invites: $error');
    }
  }

  /// Validate invite code format
  static bool isValidInviteCodeFormat(String code) {
    try {
      final isValid = code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code);
      if (kDebugMode) print('초대 코드 검증: $code - 유효성: $isValid');
      return isValid;
    } catch (error) {
      if (kDebugMode) print('Error validating invite code: $error');
      return false;
    }
  }

  /// Validate invite code and return partner information
  static Future<InviteCodeValidation> validateInviteCode(String code) async {
    try {
      if (kDebugMode) print('초대 코드 유효성 검사: $code');
      
      // Validate the invite code format
      if (!isValidInviteCodeFormat(code)) {
        return InviteCodeValidation.invalid('잘못된 초대 코드 형식입니다. 6자리 숫자를 입력해주세요.');
      }
      
      final response = await ApiService.get(
        ApiEndpoints.validateInviteCode(code),
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        
        if (kDebugMode) print('초대 코드 검증 응답: $data');
        
        if (data?['isValid'] == true) {
          final partnerName = data?['partnerName'] ?? '파트너';
          final partnerNickname = data?['partnerNickname'] ?? '닉네임';
          
          if (kDebugMode) print('초대 코드 유효 - 파트너: $partnerName ($partnerNickname)');
          
          return InviteCodeValidation.valid(partnerName, partnerNickname);
        } else {
          final errorMessage = data?['message'] ?? '잘못된 초대 코드입니다.';
          if (kDebugMode) print('초대 코드 무효: $errorMessage');
          
          return InviteCodeValidation.invalid(errorMessage);
        }
      } else {
        return InviteCodeValidation.invalid('초대 코드 검증 중 오류가 발생했습니다.');
      }
    } catch (error) {
      if (kDebugMode) print('Error validating invite code: $error');
      return InviteCodeValidation.invalid('초대 코드 검증 중 오류가 발생했습니다.');
    }
  }

  /// Connect with partner using validated information
  static Future<bool> connectWithPartner(String partnerName, String partnerNickname) async {
    try {
      if (kDebugMode) print('파트너 연결 중: $partnerName ($partnerNickname)');
      
      final response = await ApiService.post(
        ApiEndpoints.connectCouple,
        {
          'partnerName': partnerName,
          'partnerNickname': partnerNickname,
        },
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        // Create connected state
        final connection = CoupleConnection(
          status: CoupleConnectionStatus.connected,
          partnerName: partnerName,
          partnerNickname: partnerNickname,
          connectedAt: DateTime.now(),
        );
        
        await saveConnection(connection);
        
        if (kDebugMode) print('파트너 연결 성공: $partnerName');
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (error) {
      if (kDebugMode) print('Error connecting with partner: $error');
      return false;
    }
  }

  /// Cancel current invite
  static Future<bool> cancelInvite() async {
    try {
      if (kDebugMode) print('초대 코드 취소 중...');
      
      final response = await ApiService.post(
        ApiEndpoints.cancelInvite,
        {},
      );
      
      if (ApiService.isSuccessful(response.statusCode)) {
        // Reset to not connected state
        final connection = CoupleConnection.notConnected();
        await saveConnection(connection);
        
        if (kDebugMode) print('초대 코드 취소 완료');
        return true;
      } else {
        ApiService.handleErrorResponse(response);
        return false;
      }
    } catch (error) {
      if (kDebugMode) print('Error canceling invite: $error');
      return false;
    }
  }
}