import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'config/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart'; // JWT 토큰 저장용
import 'package:url_launcher/url_launcher.dart'; // 브라우저 열기용
import 'debug_key_hash.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _errorMessage;
  String? _debugKeyHash;

  @override
  void initState() {
    super.initState();

    // AppLifecycle 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // Kakao SDK는 main.dart에서 이미 초기화됨
    _checkBackendStatus();
    _getDebugKeyHash(); // 실제 키 해시 가져오기


    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🟡 AppLifecycleState changed: $state');
    
    if (state == AppLifecycleState.resumed) {
      print('🟡 앱이 다시 활성화됨 - 로딩 상태 확인');
      // 앱이 다시 활성화될 때 로딩 상태가 너무 오래 지속되었다면 해제
      if (_isLoading) {
        print('🟠 로딩 상태가 지속 중 - 강제 해제');
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인 과정에서 문제가 발생했습니다. 다시 시도해주세요.';
        });
      }
    }
  }

  Future<void> _checkBackendStatus() async {
    try {
      print('Checking backend status at: ${ApiEndpoints.baseUrl}');
      
      // 여러 엔드포인트로 테스트
      final endpoints = [
        '${ApiEndpoints.baseUrl}/actuator/health',
        '${ApiEndpoints.baseUrl}/api/auth/kakao',
        '${ApiEndpoints.baseUrl}',
      ];
      
      for (String endpoint in endpoints) {
        try {
          print('Testing: $endpoint');
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 3));
          
          print('✅ $endpoint - Status: ${response.statusCode}');
          if (response.statusCode == 200) {
            print('Backend is accessible!');
            return;
          }
        } catch (e) {
          print('❌ $endpoint - Error: ${e.toString()}');
        }
      }
      
      print('⚠️ All backend endpoints failed');
    } catch (e) {
      print('Backend health check failed: ${e.toString()}');
    }
  }

  Future<void> _getDebugKeyHash() async {
    try {
      final keyHash = await DebugKeyHash.getKeyHash();
      if (keyHash != null) {
        setState(() {
          _debugKeyHash = keyHash;
        });
      }
    } catch (e) {
      print('Debug key hash error: $e');
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    // AppLifecycle 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // --- Kakao Login Logic (OAuth2 Web Flow) ---
  Future<void> _loginWithKakao() async {
    print('🟡 카카오 웹 OAuth2 로그인 시작');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 카카오 OAuth2 인증 URL 생성
      const String kakaoClientId = 'e74f4850d8af7e2b2aec20f4faa636b3'; // .env에서 가져온 값
      const String redirectUri = 'https://todayus-production.up.railway.app/api/auth/kakao/callback';
      final String state = DateTime.now().millisecondsSinceEpoch.toString(); // CSRF 보호
      
      final String authUrl = 'https://kauth.kakao.com/oauth/authorize'
          '?client_id=$kakaoClientId'
          '&redirect_uri=$redirectUri'
          '&response_type=code'
          '&state=$state';
      
      print('🟡 카카오 인증 URL로 브라우저 열기: $authUrl');
      
      // 브라우저에서 카카오 로그인 페이지 열기
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
        print('🟢 카카오 인증 페이지 열기 성공');
      } else {
        throw Exception('카카오 로그인 페이지를 열 수 없습니다.');
      }
      
      // 콜백 처리는 AndroidManifest.xml의 intent-filter에서 자동 처리됨
      // 백엔드에서 JWT 토큰과 함께 앱으로 리다이렉트
      
    } catch (e) {
      print('🔴 Kakao OAuth2 login error: ${e.toString()}');
      setState(() {
        _errorMessage = '카카오 로그인 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      print('🟡 카카오 로그인 프로세스 종료 - 로딩 상태 해제');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to send Kakao Access Token to your Spring Boot backend
  Future<bool> _sendKakaoTokenToBackend(String accessToken) async {
    try {
      print('Sending Kakao token to backend: ${ApiEndpoints.kakaoLogin}');
      print('Access token length: ${accessToken.length}');
      
      final response = await http.post(
        Uri.parse(ApiEndpoints.kakaoLogin),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'accessToken': accessToken,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('Kakao Backend Login Success: $responseBody');
        
        // JWT 토큰 저장
        if (responseBody['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseBody['token']);
          print('🟢 JWT 토큰 저장 완료: ${responseBody['token'].substring(0, 20)}...');
        }
        
        Navigator.pushReplacementNamed(context, '/home');
        return true;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception('백엔드 로그인 실패: ${errorBody['error'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Backend communication error: ${e.toString()}');
      setState(() {
        _errorMessage = '백엔드 통신 오류: ${e.toString()}';
      });
      return false;
    }
  }

  // --- Google Login Logic ---
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  Future<void> _loginWithGoogle() async {
    print('🔵 구글 로그인 시작');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔵 구글 로그인 창 호출');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('🟠 구글 로그인 취소됨');
        throw Exception('구글 로그인이 취소되었습니다.');
      }

      print('🔵 구글 인증 정보 획득: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken != null) {
        print('🔵 백엔드로 구글 토큰 전송 시작');
        final success = await _sendGoogleTokenToBackend(googleAuth.accessToken!);
        if (!success) {
          throw Exception('백엔드 로그인에 실패했습니다.');
        }
        print('🟢 구글 로그인 전체 프로세스 완료');
      } else {
        throw Exception('구글 토큰을 받지 못했습니다.');
      }
    } catch (e) {
      print('🔴 Google login error: ${e.toString()}');
      setState(() {
        _errorMessage = '구글 로그인 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      print('🔵 구글 로그인 프로세스 종료 - 로딩 상태 해제');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to send Google Access Token to your Spring Boot backend
  Future<bool> _sendGoogleTokenToBackend(String accessToken) async {
    try {
      print('Sending Google token to backend: ${ApiEndpoints.googleLogin}');
      print('Access token length: ${accessToken.length}');
      
      final response = await http.post(
        Uri.parse(ApiEndpoints.googleLogin),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'accessToken': accessToken,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('Google Backend Login Success: $responseBody');
        
        // JWT 토큰 저장
        if (responseBody['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseBody['token']);
          print('🟢 JWT 토큰 저장 완료: ${responseBody['token'].substring(0, 20)}...');
        }
        
        // 온보딩 상태에 따라 적절한 화면으로 이동
        String nextRoute = '/home'; // 기본값
        if (responseBody['onboarding'] != null) {
          final onboarding = responseBody['onboarding'];
          final nextStep = onboarding['nextStep'];
          
          print('🟡 온보딩 상태: $onboarding');
          print('🟡 다음 단계: $nextStep');
          
          switch (nextStep) {
            case 'nickname':
              nextRoute = '/nickname-input';
              break;
            case 'couple_connection':
              nextRoute = '/couple-connection';
              break;
            case 'anniversary_setup':
              nextRoute = '/anniversary-setup';
              break;
            case 'home':
            default:
              nextRoute = '/home';
              break;
          }
        }
        
        print('🟡 이동할 경로: $nextRoute');
        Navigator.pushReplacementNamed(context, nextRoute);
        return true;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception('백엔드 로그인 실패: ${errorBody['error'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Backend communication error: ${e.toString()}');
      setState(() {
        _errorMessage = '백엔드 통신 오류: ${e.toString()}';
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고 및 타이틀
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea),
                        borderRadius: BorderRadius.circular(80),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/finger_robot.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.favorite,
                            size: 80,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      'TodayUs',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '우리의 특별한 순간들을\n함께 기록해보세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // 디버그 키 해시 표시
                    if (_debugKeyHash != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔑 Debug Key Hash:',
                              style: TextStyle(
                                color: Color(0xFF2D3748),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              _debugKeyHash!,
                              style: const TextStyle(
                                color: Color(0xFF2D3748),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Copy this to Kakao Console',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 오류 메시지
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1), // Corrected withValues to withOpacity
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3), // Corrected withValues to withOpacity
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Kakao Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _loginWithKakao,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1), // Corrected withValues to withOpacity
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE812).withOpacity(0.7), // Corrected withValues to withOpacity
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF191919),
                                  ),
                                ),
                              ),
                            ),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/kakao_login_large_narrow.png',
                              fit: BoxFit.cover,
                              height: 56,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Google Login Button (Google Branding Guidelines)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _loginWithGoogle,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4), // Google uses 4dp radius
                            border: Border.all(
                              color: const Color(0xFFDDDDDD),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF4285F4),
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google G Logo (using SVG colors in Container)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Stack(
                                        children: [
                                          // Blue section
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            child: Container(
                                              width: 20,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF4285F4),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Red section
                                          Positioned(
                                            top: 10,
                                            left: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEA4335),
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Yellow section
                                          Positioned(
                                            top: 10,
                                            right: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFBBC05),
                                                borderRadius: BorderRadius.only(
                                                  bottomRight: Radius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Green section (small part)
                                          Positioned(
                                            top: 5,
                                            right: 2,
                                            child: Container(
                                              width: 6,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF34A853),
                                              ),
                                            ),
                                          ),
                                          // Center white G shape
                                          const Center(
                                            child: Text(
                                              'G',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Google로 로그인',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF3C4043), // Google text color
                                        fontFamily: 'Roboto', // Google uses Roboto
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 하단 정보
                    Text(
                      '로그인하면 TodayUs의 서비스 이용약관 및\n개인정보 처리방침에 동의하게 됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
