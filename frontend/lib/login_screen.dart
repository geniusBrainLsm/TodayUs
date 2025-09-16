import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'dart:math'; // For pi constant
import 'config/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart'; // JWT 토큰 저장용
import 'package:url_launcher/url_launcher.dart'; // 브라우저 열기용

// Google Logo CustomPainter (improved)
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    
    // Red path (top-left segment) - fixed to connect properly
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    
    final redPath = Path()
      ..moveTo(24 * scale, 9.5 * scale)
      ..cubicTo(27.54 * scale, 9.5 * scale, 30.71 * scale, 10.72 * scale, 33.21 * scale, 12.6 * scale)
      ..lineTo(40.06 * scale, 6.25 * scale)
      ..cubicTo(35.9 * scale, 2.38 * scale, 30.47 * scale, 0, 24 * scale, 0)
      ..cubicTo(14.62 * scale, 0, 6.51 * scale, 5.38 * scale, 2.56 * scale, 13.22 * scale)
      ..lineTo(10.54 * scale, 19.41 * scale)
      ..cubicTo(12.44 * scale, 13.72 * scale, 17.74 * scale, 9.5 * scale, 24 * scale, 9.5 * scale)
      ..close();
    
    canvas.drawPath(redPath, redPaint);
    
    // Blue path (top-right segment)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final bluePath = Path()
      ..moveTo(46.98 * scale, 24.55 * scale)
      ..cubicTo(46.98 * scale, 22.98 * scale, 46.83 * scale, 21.46 * scale, 46.6 * scale, 20 * scale)
      ..lineTo(24 * scale, 20 * scale)
      ..lineTo(24 * scale, 29.02 * scale)
      ..lineTo(36.94 * scale, 29.02 * scale)
      ..cubicTo(36.36 * scale, 31.98 * scale, 34.68 * scale, 34.5 * scale, 32.16 * scale, 36.2 * scale)
      ..lineTo(39.89 * scale, 42.2 * scale)
      ..cubicTo(44.4 * scale, 38.02 * scale, 46.98 * scale, 31.84 * scale, 46.98 * scale, 24.55 * scale)
      ..close();
    
    canvas.drawPath(bluePath, bluePaint);
    
    // Yellow path (bottom-left segment)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    
    final yellowPath = Path()
      ..moveTo(10.53 * scale, 28.59 * scale)
      ..cubicTo(10.05 * scale, 27.14 * scale, 9.77 * scale, 25.6 * scale, 9.77 * scale, 24 * scale)
      ..cubicTo(9.77 * scale, 22.4 * scale, 10.04 * scale, 20.86 * scale, 10.53 * scale, 19.41 * scale)
      ..lineTo(2.55 * scale, 13.22 * scale)
      ..cubicTo(0.92 * scale, 16.46 * scale, 0, 20.12 * scale, 0, 24 * scale)
      ..cubicTo(0, 27.88 * scale, 0.92 * scale, 31.54 * scale, 2.56 * scale, 34.78 * scale)
      ..lineTo(10.53 * scale, 28.59 * scale)
      ..close();
    
    canvas.drawPath(yellowPath, yellowPaint);
    
    // Green path (bottom-right segment)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    
    final greenPath = Path()
      ..moveTo(24 * scale, 48 * scale)
      ..cubicTo(30.48 * scale, 48 * scale, 35.93 * scale, 45.87 * scale, 39.89 * scale, 42.19 * scale)
      ..lineTo(32.16 * scale, 36.19 * scale)
      ..cubicTo(30.01 * scale, 37.64 * scale, 27.24 * scale, 38.49 * scale, 24 * scale, 38.49 * scale)
      ..cubicTo(17.74 * scale, 38.49 * scale, 12.43 * scale, 34.27 * scale, 10.53 * scale, 28.58 * scale)
      ..lineTo(2.55 * scale, 34.77 * scale)
      ..cubicTo(6.51 * scale, 42.61 * scale, 14.62 * scale, 48 * scale, 24 * scale, 48 * scale)
      ..close();
    
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

  @override
  void initState() {
    super.initState();

    // AppLifecycle 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // Kakao SDK는 main.dart에서 이미 초기화됨
    _checkBackendStatus();


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
                      height: 52,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _loginWithKakao,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE500), // Kakao Yellow
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE500).withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Kakao Symbol
                                    Image.asset(
                                      'assets/images/kakao_symbol.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '카카오 로그인',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Google Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _loginWithGoogle,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF), // White background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFDADCE0), // Light gray border like Google
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
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
                              : Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google G Logo (Official SVG)
                                      Container(
                                        width: 18,
                                        height: 18,
                                        child: CustomPaint(
                                          painter: GoogleLogoPainter(),
                                          size: const Size(18, 18),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Sign in with Google',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF3C4043),
                                        ),
                                      ),
                                    ],
                                  ),
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
