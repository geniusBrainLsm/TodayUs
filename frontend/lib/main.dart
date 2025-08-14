import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'nickname_input_screen.dart';
import 'anniversary_setup_screen.dart';
import 'couple_connection_screen.dart';
import 'settings_screen.dart';
import 'main_layout.dart';
import 'screens/couple_message/couple_message_create_screen.dart';
import 'screens/couple_message/couple_message_history_screen.dart';
import 'config/environment.dart';
import 'config/api_endpoints.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  // Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // 알림 서비스 초기화
  await NotificationService.initialize();
  
  // Kakao SDK 초기화 (앱 전체에서 한 번만)
  KakaoSdk.init(nativeAppKey: '20646fff67488fe8fb17b19016b7f2a3');
  
  // 환경 설정 초기화 - 빌드 시점에 결정
  _initializeEnvironment();

  // 디버그 모드에서 API 엔드포인트 출력
  if (EnvironmentConfig.enableDebugMode) {
    ApiEndpoints.printAllEndpoints();
  }
  
  runApp(const TodayUsApp());
}

/// 빌드 시점에 환경 자동 결정
void _initializeEnvironment() {
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  switch (environment) {
    case 'production':
      EnvironmentConfig.setCurrent(Environment.production);
      break;
    case 'staging':
      EnvironmentConfig.setCurrent(Environment.staging);
      break;
    default:
      EnvironmentConfig.setCurrent(Environment.development);
  }
  
  print('🌍 환경 설정: ${EnvironmentConfig.current.name}');
  print('🔗 Base URL: ${EnvironmentConfig.baseUrl}');
}

/// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('📨 Background message received: ${message.notification?.title}');
}

class TodayUsApp extends StatefulWidget {
  const TodayUsApp({super.key});

  @override
  State<TodayUsApp> createState() => _TodayUsAppState();
}

class _TodayUsAppState extends State<TodayUsApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // 앱이 실행 중일 때 들어오는 링크 처리
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('🟢 Deep link 수신: $uri');
      _handleDeepLink(uri);
    });

    // 앱이 종료된 상태에서 링크로 실행된 경우
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) {
        print('🟢 초기 Deep link 수신: $uri');
        _handleDeepLink(uri);
      }
    } catch (e) {
      print('초기 deep link 처리 오류: $e');
    }
  }

  void _handleDeepLink(Uri uri) async {
    print('🟡 Deep link 처리 시작: ${uri.toString()}');
    
    if (uri.scheme == 'todayus' && uri.host == 'login') {
      final token = uri.queryParameters['token'];
      final userId = uri.queryParameters['user_id'];
      
      if (token != null) {
        print('🟢 JWT 토큰 수신: ${token.substring(0, 20)}...');
        
        // SharedPreferences에 토큰 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        
        // 토큰 저장 후 스플래시 화면으로 이동하여 온보딩 상태 체크
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
        
        print('🟢 토큰 저장 완료 - 스플래시 화면에서 온보딩 상태 확인');
      } else {
        print('🔴 토큰이 없는 Deep link');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'TodayUs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 한국어 지원 추가
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어
      ],
      locale: const Locale('ko', 'KR'),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/nickname-input': (context) => const NicknameInputScreen(),
        '/anniversary-setup': (context) => const AnniversarySetupScreen(),
        '/couple-connection': (context) => const CoupleConnectionScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/home': (context) => const MainLayout(),
        '/couple-message-create': (context) => const CoupleMessageCreateScreen(),
        '/couple-message-history': (context) => const CoupleMessageHistoryScreen(),
      },
    );
  }
}

