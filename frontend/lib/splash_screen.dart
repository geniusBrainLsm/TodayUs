import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_endpoints.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start scale animation immediately
    _scaleController.forward();
    
    // Start fade animation with a slight delay
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    
    // Check for OAuth2 token in URL first
    await _checkForOAuth2Token();
    
    // Navigate to appropriate page after animations complete
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      await _navigateToNextScreen();
    }
  }
  
  Future<void> _checkForOAuth2Token() async {
    try {
      // 웹 플랫폼에서만 URL 파라미터 확인 (OAuth2 리다이렉트 처리)
      if (Uri.base.hasQuery) {
        final uri = Uri.base;
        final token = uri.queryParameters['token'];
        final error = uri.queryParameters['error'];
        
        if (error != null) {
          print('OAuth2 error: ${Uri.decodeComponent(error)}');
          return;
        }
        
        if (token != null) {
          try {
            await AuthService.saveToken(token);
            print('OAuth2 token saved successfully');
          } catch (e) {
            print('Error saving OAuth2 token: $e');
          }
        }
      }
    } catch (e) {
      // URL 파라미터 확인 실패 시 무시 (모바일 플랫폼 등)
      print('URL parameter check failed: $e');
    }
  }
  
  Future<void> _navigateToNextScreen() async {
    try {
      // 토큰이 있는지 확인
      final token = await ApiService.getAuthToken();
      
      if (token != null && token.isNotEmpty) {
        print('🟡 토큰 발견 - 온보딩 상태 확인 시작');
        
        // 항상 서버에서 최신 온보딩 상태를 확인 (캐시 무시)
        print('🟡 서버에서 최신 온보딩 상태 확인 시작');
        final nextRoute = await _checkUserOnboardingStatus(token);
        Navigator.of(context).pushReplacementNamed(nextRoute);
      } else {
        print('🟡 토큰 없음 - 로그인 화면으로 이동');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('🔴 네비게이션 오류: $e');
      // 오류 시 로그인으로
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  Future<String> _checkUserOnboardingStatus(String token) async {
    try {
      print('🟡 /api/auth/me 호출 시작');
      
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('🟡 응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🟢 사용자 정보 획득 성공: $responseData');
        
        // 온보딩 상태 확인을 위해 별도 API 호출
        return await _getOnboardingRoute(responseData, token);
      } else {
        print('🔴 사용자 정보 획득 실패: ${response.statusCode}');
        // 토큰이 유효하지 않은 경우 로그인으로
        await ApiService.clearAuthToken();
        return '/login';
      }
    } catch (e) {
      print('🔴 온보딩 상태 확인 오류: $e');
      return '/login';
    }
  }
  
  Future<String> _getOnboardingRoute(Map<String, dynamic> userData, String token) async {
    try {
      final userEmail = userData['email'];
      print('🟡 온보딩 상태 API 호출: $userEmail');
      print('🟡 요청 URL: ${ApiEndpoints.baseUrl}/api/auth/onboarding-status?email=$userEmail');
      
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/onboarding-status?email=$userEmail'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('🟡 온보딩 API 응답 상태: ${response.statusCode}');
      print('🟡 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        final onboardingData = jsonDecode(response.body);
        final user = onboardingData['user'];
        final onboarding = onboardingData['onboarding'];
        final nextStep = onboarding['nextStep'];
        
        print('🟡 사용자 정보: $user');
        print('🟢 온보딩 상태: $onboarding');
        print('🟡 다음 단계: $nextStep');
        
        // AuthService에 온보딩 상태 저장
        await AuthService.saveOnboardingStatus(onboarding);
        print('🟢 온보딩 상태 로컬 저장 완료');
        
        // 다음 단계에 따라 라우트 결정
        switch (nextStep) {
          case 'nickname':
            print('🟡 닉네임 설정 화면으로 이동');
            return '/nickname-input';
          case 'couple_connection':
            print('🟡 커플 연결 화면으로 이동');
            return '/couple-connection';
          case 'anniversary_setup':
            print('🟡 기념일 설정 화면으로 이동');
            return '/anniversary-setup';
          case 'home':
          default:
            print('🟡 홈 화면으로 이동');
            return '/home';
        }
      } else {
        print('🔴 온보딩 상태 확인 실패: ${response.statusCode}');
        print('🔴 응답 내용: ${response.body}');
        // API 호출 실패 시 닉네임 설정부터 시작
        return '/nickname-input';
      }
    } catch (e) {
      print('🔴 온보딩 라우트 결정 오류: $e');
      // 오류 발생 시 닉네임 설정부터 시작
      return '/nickname-input';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(75),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: Image.asset(
                      'assets/images/done_robot.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.smart_toy,
                          size: 75,
                          color: Colors.grey[400],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}