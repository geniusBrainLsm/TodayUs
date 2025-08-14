import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../config/api_endpoints.dart';

class ApiService {
  static String get baseUrl => ApiEndpoints.baseUrl;
  static const String _tokenKey = 'auth_token';
  
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  static Future<http.Response> get(String endpoint) async {
    final url = _parseUrl(endpoint);
    final headers = await _getHeaders();
    
    _logRequest('GET', url, headers);
    
    final response = await http.get(url, headers: headers)
        .timeout(Duration(milliseconds: EnvironmentConfig.apiTimeout));
    
    _logResponse(response);
    
    return response;
  }
  
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = _parseUrl(endpoint);
    final headers = await _getHeaders();
    final bodyJson = jsonEncode(body);
    
    _logRequest('POST', url, headers, bodyJson);
    
    final response = await http.post(
      url,
      headers: headers,
      body: bodyJson,
    ).timeout(Duration(milliseconds: EnvironmentConfig.apiTimeout));
    
    _logResponse(response);
    
    return response;
  }
  
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = _parseUrl(endpoint);
    final headers = await _getHeaders();
    final bodyJson = jsonEncode(body);
    
    _logRequest('PUT', url, headers, bodyJson);
    
    final response = await http.put(
      url,
      headers: headers,
      body: bodyJson,
    ).timeout(Duration(milliseconds: EnvironmentConfig.apiTimeout));
    
    _logResponse(response);
    
    return response;
  }
  
  static Future<http.Response> delete(String endpoint) async {
    final url = _parseUrl(endpoint);
    final headers = await _getHeaders();
    
    _logRequest('DELETE', url, headers);
    
    final response = await http.delete(url, headers: headers)
        .timeout(Duration(milliseconds: EnvironmentConfig.apiTimeout));
    
    _logResponse(response);
    
    return response;
  }
  
  static bool isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
  
  static Map<String, dynamic>? parseResponse(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (EnvironmentConfig.enableLogging) {
        print('Error parsing response: $e');
      }
      return null;
    }
  }
  
  // ================================================================
  // 편의 메서드들 (ApiEndpoints와 연동)
  // ================================================================
  
  /// URL 파싱 (절대 URL인지 상대 URL인지 확인)
  static Uri _parseUrl(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      // 절대 URL인 경우 그대로 사용
      return Uri.parse(endpoint);
    } else {
      // 상대 URL인 경우 baseUrl과 결합
      return Uri.parse('$baseUrl$endpoint');
    }
  }
  
  /// 요청 로깅
  static void _logRequest(String method, Uri url, Map<String, String> headers, [String? body]) {
    if (!EnvironmentConfig.enableLogging) return;
    
    print('=== API Request ===');
    print('$method: $url');
    print('Headers: $headers');
    if (body != null) {
      print('Body: $body');
    }
    print('==================');
  }
  
  /// 응답 로깅
  static void _logResponse(http.Response response) {
    if (!EnvironmentConfig.enableLogging) return;
    
    print('=== API Response ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('===================');
  }
  
  // ================================================================
  // 고급 HTTP 메서드들
  // ================================================================
  
  /// PATCH 메서드
  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = _parseUrl(endpoint);
    final headers = await _getHeaders();
    final bodyJson = jsonEncode(body);
    
    _logRequest('PATCH', url, headers, bodyJson);
    
    final response = await http.patch(
      url,
      headers: headers,
      body: bodyJson,
    ).timeout(Duration(milliseconds: EnvironmentConfig.apiTimeout));
    
    _logResponse(response);
    
    return response;
  }
  
  /// 파일 업로드를 위한 멀티파트 요청
  static Future<http.StreamedResponse> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? additionalFields,
  }) async {
    final url = _parseUrl(endpoint);
    final token = await getAuthToken();
    
    final request = http.MultipartRequest('POST', url);
    
    // 헤더 설정
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // 파일 추가
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    
    // 추가 필드
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }
    
    if (EnvironmentConfig.enableLogging) {
      print('=== File Upload ===');
      print('POST: $url');
      print('File: $filePath');
      print('Field: $fieldName');
      print('Additional Fields: $additionalFields');
      print('==================');
    }
    
    return await request.send().timeout(
      Duration(milliseconds: EnvironmentConfig.apiTimeout),
    );
  }
  
  // ================================================================
  // 오류 처리 및 재시도 로직
  // ================================================================
  
  /// 자동 재시도가 포함된 GET 요청
  static Future<http.Response> getWithRetry(
    String endpoint, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await get(endpoint);
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        if (EnvironmentConfig.enableLogging) {
          print('Request failed (attempt $attempt/$maxRetries): $e');
          print('Retrying in ${retryDelay.inSeconds} seconds...');
        }
        
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Max retries exceeded');
  }
  
  /// 응답 상태 코드 확인 및 예외 처리
  static void handleErrorResponse(http.Response response) {
    if (isSuccessful(response.statusCode)) return;
    
    String errorMessage = 'HTTP ${response.statusCode}';
    
    try {
      final errorData = parseResponse(response);
      if (errorData != null && errorData.containsKey('error')) {
        errorMessage = errorData['error'].toString();
      } else if (errorData != null && errorData.containsKey('message')) {
        errorMessage = errorData['message'].toString();
      }
    } catch (e) {
      // JSON 파싱 실패 시 기본 메시지 사용
    }
    
    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 429:
        throw TooManyRequestsException(errorMessage);
      case 500:
        throw InternalServerErrorException(errorMessage);
      default:
        throw ApiException(response.statusCode, errorMessage);
    }
  }
}

// ================================================================
// Custom Exception Classes
// ================================================================

class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException(this.statusCode, this.message);
  
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(401, message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(403, message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(404, message);
}

class TooManyRequestsException extends ApiException {
  TooManyRequestsException(String message) : super(429, message);
}

class InternalServerErrorException extends ApiException {
  InternalServerErrorException(String message) : super(500, message);
}