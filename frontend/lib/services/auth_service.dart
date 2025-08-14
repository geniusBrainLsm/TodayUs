import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import '../config/api_endpoints.dart';

class AuthService {
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _onboardingStatusKey = 'onboarding_status';
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  

  /// Handle Google Sign In and get JWT token from backend
  static Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        print('Google Sign In cancelled by user');
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication authentication = await account.authentication;
      final idToken = authentication.idToken;
      
      if (idToken == null) {
        print('Failed to get ID token from Google');
        return false;
      }

      // Send ID token to backend for verification and JWT generation
      final response = await ApiService.post(ApiEndpoints.googleLogin, {
        'idToken': idToken,
      });

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        if (data != null && data['token'] != null) {
          // Save JWT token
          await ApiService.saveAuthToken(data['token']);
          
          // Save user info
          await _saveUserInfo(
            email: account.email,
            name: account.displayName ?? account.email,
          );
          
          // Save onboarding status for navigation
          if (data['onboarding'] != null) {
            await saveOnboardingStatus(data['onboarding']);
          }
          
          print('Google Sign In successful for: ${account.email}');
          return true;
        }
      }
      
      print('Failed to get JWT token from backend: ${response.statusCode}');
      return false;
    } catch (error) {
      print('Google Sign In error: $error');
      return false;
    }
  }

  /// Handle Kakao Sign In (placeholder for future implementation)
  static Future<bool> signInWithKakao() async {
    try {
      // TODO: Implement Kakao SDK integration
      print('Kakao Sign In attempted - not implemented yet');
      return false;
    } catch (error) {
      print('Kakao Sign In error: $error');
      return false;
    }
  }

  /// Sign out user
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear all stored data
      await ApiService.clearAuthToken();
      await _clearUserInfo();
      
    } catch (error) {
      print('Sign out error: $error');
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!isLoggedIn) {
        return false;
      }
      
      // Check if we have a valid token
      final token = await ApiService.getAuthToken();
      return token != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Get current user email
  static Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      print('Error getting current user email: $e');
      return null;
    }
  }

  /// Get current user name
  static Future<String?> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      print('Error getting current user name: $e');
      return null;
    }
  }

  /// Validate token with backend
  static Future<bool> validateToken() async {
    try {
      final response = await ApiService.get(ApiEndpoints.authValidate);
      return ApiService.isSuccessful(response.statusCode);
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  /// Save user information locally
  static Future<void> _saveUserInfo({
    required String email,
    required String name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, email);
      await prefs.setString(_userNameKey, name);
      await prefs.setBool(_isLoggedInKey, true);
    } catch (e) {
      print('Error saving user info: $e');
    }
  }

  /// Clear user information
  static Future<void> _clearUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_onboardingStatusKey);
    } catch (e) {
      print('Error clearing user info: $e');
    }
  }

  /// Handle authentication errors and redirect to login if needed
  static Future<bool> handleAuthError(int statusCode) async {
    if (statusCode == 401 || statusCode == 403) {
      print('Authentication error, signing out user');
      await signOut();
      return true; // Indicates need to redirect to login
    }
    return false;
  }

  /// Save JWT token from OAuth2 redirect
  static Future<void> saveToken(String token) async {
    try {
      await ApiService.saveAuthToken(token);
      
      // Mark user as logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      
      print('OAuth2 token saved successfully');
    } catch (e) {
      print('Error saving OAuth2 token: $e');
      throw e;
    }
  }

  /// Save onboarding status
  static Future<void> saveOnboardingStatus(Map<String, dynamic> onboardingStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_onboardingStatusKey, jsonEncode(onboardingStatus));
      print('Onboarding status saved: $onboardingStatus');
    } catch (e) {
      print('Error saving onboarding status: $e');
    }
  }

  /// Get onboarding status
  static Future<Map<String, dynamic>?> getOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_onboardingStatusKey);
      if (statusJson != null) {
        return jsonDecode(statusJson);
      }
      return null;
    } catch (e) {
      print('Error getting onboarding status: $e');
      return null;
    }
  }

  /// Refresh onboarding status from server
  static Future<void> refreshOnboardingStatus() async {
    try {
      final email = await getCurrentUserEmail();
      if (email == null) {
        print('🔴 refreshOnboardingStatus: 사용자 이메일이 없습니다');
        return;
      }

      final url = '${ApiEndpoints.onboardingStatus}?email=$email';
      print('🟡 refreshOnboardingStatus: API 호출 - $url');

      final response = await ApiService.get(url);

      print('🟡 refreshOnboardingStatus: 응답 상태 - ${response.statusCode}');
      print('🟡 refreshOnboardingStatus: 응답 내용 - ${response.body}');

      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        final onboardingStatus = data?['onboarding'];
        if (onboardingStatus != null) {
          await saveOnboardingStatus(onboardingStatus);
          print('🟢 refreshOnboardingStatus: 온보딩 상태 새로고침 완료');
        } else {
          print('🔴 refreshOnboardingStatus: 온보딩 데이터 없음');
        }
      } else {
        print('🔴 refreshOnboardingStatus: API 호출 실패 - ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 refreshOnboardingStatus 오류: $e');
    }
  }

  /// Get next route based on onboarding status
  static Future<String> getNextRoute() async {
    try {
      final onboardingStatus = await getOnboardingStatus();
      print('🟡 getNextRoute: 로컬 온보딩 상태 - $onboardingStatus');
      
      if (onboardingStatus != null) {
        final nextStep = onboardingStatus['nextStep'];
        print('🟡 getNextRoute: 다음 단계 - $nextStep');
        
        switch (nextStep) {
          case 'nickname':
            print('🟡 getNextRoute: 닉네임 입력 화면으로');
            return '/nickname-input';
          case 'couple_connection':
            print('🟡 getNextRoute: 커플 연결 화면으로');
            return '/couple-connection';
          case 'anniversary_setup':
            print('🟡 getNextRoute: 기념일 설정 화면으로');
            return '/anniversary-setup';
          case 'home':
          default:
            print('🟡 getNextRoute: 홈 화면으로');
            return '/home';
        }
      }
      // Default to nickname input if no onboarding status
      print('🟠 getNextRoute: 온보딩 상태 없음, 기본값으로 닉네임 입력');
      return '/nickname-input';
    } catch (e) {
      print('🔴 getNextRoute 오류: $e');
      return '/nickname-input';
    }
  }

  /// Get user info from token (after OAuth2 login)
  static Future<Map<String, dynamic>?> getUserInfoFromToken() async {
    try {
      final response = await ApiService.get(ApiEndpoints.authMe);
      
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response);
        if (data != null) {
          // Save user info locally
          await _saveUserInfo(
            email: data['email'] ?? '',
            name: data['name'] ?? '',
          );
          return data;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting user info from token: $e');
      return null;
    }
  }
}