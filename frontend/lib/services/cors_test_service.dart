import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';

/// CORS 설정 테스트를 위한 서비스
class CorsTestService {
  
  /// 단순 GET 요청 테스트
  static Future<Map<String, dynamic>> testSimpleGet() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/cors-test/simple';
      print('CORS GET 테스트: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'statusCode': response.statusCode,
          'headers': response.headers,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('CORS GET 테스트 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Preflight 요청 테스트 (POST)
  static Future<Map<String, dynamic>> testPreflight() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/cors-test/preflight';
      print('CORS POST 테스트: $url');
      
      final testData = {
        'test': 'preflight',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'message': 'Flutter에서 보낸 테스트 데이터',
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'http://localhost:3000', // Explicit origin for testing
        },
        body: json.encode(testData),
      );
      
      print('응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'statusCode': response.statusCode,
          'headers': response.headers,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('CORS POST 테스트 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 인증이 필요한 CORS 테스트
  static Future<Map<String, dynamic>> testAuth() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/cors-test/auth';
      print('CORS 인증 테스트: $url');
      
      // 실제 JWT 토큰 가져오기 (있는 경우)
      // final token = await AuthService.getAccessToken();
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': token != null ? 'Bearer $token' : '',
        },
      );
      
      print('응답 상태: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'statusCode': response.statusCode,
          'headers': response.headers,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('CORS 인증 테스트 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 모든 CORS 테스트 실행
  static Future<Map<String, dynamic>> runAllTests() async {
    print('=== CORS 전체 테스트 시작 ===');
    
    final results = <String, dynamic>{};
    
    // 1. 단순 GET 테스트
    print('1. 단순 GET 테스트 실행...');
    results['simpleGet'] = await testSimpleGet();
    
    // 2. Preflight POST 테스트
    print('2. Preflight POST 테스트 실행...');
    results['preflight'] = await testPreflight();
    
    // 3. 인증 테스트
    print('3. 인증 테스트 실행...');
    results['auth'] = await testAuth();
    
    // 결과 요약
    final summary = {
      'totalTests': 3,
      'successCount': results.values.where((r) => r['success'] == true).length,
      'failedCount': results.values.where((r) => r['success'] == false).length,
    };
    
    results['summary'] = summary;
    
    print('=== CORS 테스트 완료 ===');
    print('성공: ${summary['successCount']}, 실패: ${summary['failedCount']}');
    
    return results;
  }
}