import 'dart:io';
import 'package:flutter/foundation.dart';

/// 환경 설정 관리
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _current = Environment.development;
  
  static Environment get current => _current;
  
  static void setCurrent(Environment env) {
    _current = env;
  }
  
  static bool get isDevelopment => _current == Environment.development;
  static bool get isStaging => _current == Environment.staging;
  static bool get isProduction => _current == Environment.production;
  
  /// 환경별 기본 설정
  static Map<String, dynamic> get config {
    switch (_current) {
      case Environment.development:
        return {
          'baseUrl': 'http://10.0.2.2:8080', // Android 에뮬레이터에서 localhost 접근
          'baseUrlLocalhost': 'http://localhost:8080', // 웹/iOS용
          'baseUrlRealDevice': 'http://192.168.1.100:8080', // 실제 디바이스용 (PC의 로컬 IP)
          'enableLogging': true,
          'enableDebugMode': true,
          'apiTimeout': 30000, // 30초
        };
      case Environment.staging:
        return {
          'baseUrl': 'https://todayus-production.up.railway.app', // Railway 스테이징 URL
          'enableLogging': true,
          'enableDebugMode': true,
          'apiTimeout': 15000, // 15초
        };
      case Environment.production:
        return {
          'baseUrl': 'https://todayus-production.up.railway.app', // Railway 프로덕션 URL
          'enableLogging': false,
          'enableDebugMode': false,
          'apiTimeout': 10000, // 10초
        };
    }
  }
  
  static String get baseUrl {
    if (_current == Environment.development) {
      // 개발 환경에서 플랫폼별 URL 사용
      if (kIsWeb) {
        return 'http://localhost:8080';
      } else if (Platform.isAndroid) {
        // 실제 디바이스에서는 Railway 서버 사용 (로컬 서버 접근 불가)
        // 에뮬레이터에서만 10.0.2.2 사용하고, 실제 디바이스는 Railway 사용
        return 'https://todayus-production.up.railway.app'; // 실제 디바이스용
      } else if (Platform.isIOS) {
        return 'https://todayus-production.up.railway.app'; // iOS 실제 디바이스용
      } else {
        return 'http://localhost:8080'; // 기본값 (데스크톱)
      }
    } else {
      return config['baseUrl'] as String;
    }
  }
  
  /// 실제 디바이스용 개발 서버 URL (PC의 로컬 IP 사용)
  static String get realDeviceUrl => config['baseUrlRealDevice'] as String? ?? 'http://192.168.1.100:8080';
  
  /// 환경을 수동으로 변경하는 헬퍼 메서드들
  static void setDevelopment() => setCurrent(Environment.development);
  static void setStaging() => setCurrent(Environment.staging);
  static void setProduction() => setCurrent(Environment.production);
  static bool get enableLogging => config['enableLogging'] as bool;
  static bool get enableDebugMode => config['enableDebugMode'] as bool;
  static int get apiTimeout => config['apiTimeout'] as int;
}