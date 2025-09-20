import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../firebase_options.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 알림 설정 키들
  static const String _diaryReminderKey = 'diary_reminder_enabled';
  static const String _partnerDiaryKey = 'partner_diary_enabled';
  static const String _diaryCommentKey = 'diary_comment_enabled';
  static const String _coupleMessageKey = 'couple_message_enabled';
  static const String _fcmTokenKey = 'fcm_token';

  /// 알림 서비스 초기화
  static Future<void> initialize() async {
    try {
      print('🔔 Initializing notification service...');

      // Timezone 데이터 초기화
      tz.initializeTimeZones();

      // Firebase 초기화 (main.dart에서 이미 했다면 스킵)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // FCM 권한 요청
      await _requestPermissions();

      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      // FCM 설정
      await _configureFCM();

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// FCM 권한 요청
  static Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ FCM provisional permissions granted');
      } else {
        print('❌ FCM permissions denied');
      }
    } catch (e) {
      print('❌ Error requesting FCM permissions: $e');
    }
  }

  /// 로컬 알림 초기화
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  /// FCM 설정
  static Future<void> _configureFCM() async {
    try {
      // FCM 토큰 가져오기 및 저장
      await _getFCMToken();

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen(_saveFCMToken);

      // 포그라운드 메시지 처리
      FirebaseMessaging.onMessage.listen((message) async {
        await _handleForegroundMessage(message);
      });

      // 백그라운드 메시지 처리 (외부에서 설정)
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 앱이 종료된 상태에서 알림 클릭으로 앱이 열렸을 때
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      print('✅ FCM configured successfully');
    } catch (e) {
      print('❌ Error configuring FCM: $e');
    }
  }

  /// FCM 토큰 가져오기
  static Future<String?> _getFCMToken() async {
    try {
      // Web에서 VAPID 키 사용
      final token = await _messaging.getToken(
          vapidKey:
              'BC6Dchco017oiKHiZxbg4E4AYu9JtW7FcPb_fOPaLqLRu7r82sMdk2tMbzmlX_bE_A6f4A7mzAwvVoaJ6i9qY5Y');

      if (token != null) {
        await _saveFCMToken(token);
        print('📱 FCM Token: ${token.substring(0, 20)}...');
        return token;
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
    return null;
  }

  /// FCM 토큰 저장
  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      print('💾 FCM token saved');

      // TODO: 서버에 토큰 전송
      // await _sendTokenToServer(token);
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// 저장된 FCM 토큰 가져오기
  static Future<String?> getFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      print('❌ Error getting saved FCM token: $e');
      return null;
    }
  }

  /// 포그라운드에서 메시지 받았을 때
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message: \${message.notification?.title}');

    final data = message.data;
    final String type = data['type'] ?? 'general';

    if (!await _shouldDisplayNotification(type)) {
      print('🔕 Notification suppressed for type: \${type}');
      return;
    }

    await _showLocalNotification(
      title: message.notification?.title ?? 'TodayUs',
      body: message.notification?.body ?? '',
      payload: jsonEncode(data),
    );
  }

  /// 알림 탭했을 때
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationAction(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// 앱이 종료된 상태에서 알림으로 열렸을 때
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('🚀 App opened from notification: ${message.notification?.title}');
    _handleNotificationAction(message.data);
  }

  /// 알림 액션 처리
  static void _handleNotificationAction(Map<String, dynamic> data) {
    final String? type = data['type'];

    switch (type) {
      case 'diary_reminder':
        // 일기 작성 화면으로 이동
        print('📝 Navigate to diary write screen');
        break;
      case 'couple_message':
        // 커플 메시지 화면으로 이동
        print('💌 Navigate to couple message screen');
        break;
      case 'diary_created':
        // 파트너 일기 화면으로 이동
        print('📖 Navigate to partner diary screen');
        break;
      case 'diary_comment':
        // 댓글 상세 화면으로 이동
        print('💬 Navigate to diary comment screen');
        break;
      default:
        print('🏠 Navigate to home screen');
        break;
    }
  }

  static Future<bool> _shouldDisplayNotification(String type) async {
    switch (type) {
      case 'diary_reminder':
        return await isNotificationEnabled('diary');
      case 'couple_message':
        return await isNotificationEnabled('couple_message');
      case 'diary_created':
        return await isNotificationEnabled('diary_created');
      case 'diary_comment':
        return await isNotificationEnabled('diary_comment');
      case 'test':
        return true;
      default:
        return true;
    }
  }

  /// 로컬 알림 표시
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'todayus_general',
        'TodayUs 알림',
        channelDescription: 'TodayUs 앱의 일반 알림',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// 일기 작성 알림 스케줄링 (매일 저녁 6시)
  static Future<void> scheduleDailyDiaryReminder() async {
    try {
      await _localNotifications.cancel(1); // 기존 일기 알림 취소

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'todayus_diary',
        '일기 작성 알림',
        channelDescription: '매일 일기 작성을 알려드립니다',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 오늘 저녁 6시 설정
      final now = DateTime.now();
      var scheduledTime =
          DateTime(now.year, now.month, now.day, 18, 0); // 저녁 6시

      // 이미 6시가 지났으면 내일 6시로 설정
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // 일회성 알림으로 설정하고, 매일 반복하려면 앱에서 다시 스케줄링
      await _localNotifications.zonedSchedule(
        1,
        '오늘 일기 작성하셨나요? ✍️',
        '하루를 마무리하며 소중한 순간들을 기록해보세요',
        _convertToTZDateTime(scheduledTime),
        details,
        payload: jsonEncode({'type': 'diary_reminder'}),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간에 반복
      );

      print('⏰ Daily diary reminder scheduled for $scheduledTime');
    } catch (e) {
      print('❌ Error scheduling diary reminder: $e');
    }
  }

  /// 기념일 알림 스케줄링
  static Future<void> scheduleAnniversaryNotification({
    required DateTime date,
    required String title,
    required String message,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'todayus_anniversary',
        '기념일 알림',
        channelDescription: '특별한 날을 알려드립니다',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int id = date.millisecondsSinceEpoch % 100000;

      // zonedSchedule 사용 (새로운 API)
      await _localNotifications.zonedSchedule(
        id,
        title,
        message,
        _convertToTZDateTime(date),
        details,
        payload:
            jsonEncode({'type': 'anniversary', 'date': date.toIso8601String()}),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('🎉 Anniversary notification scheduled for $date');
    } catch (e) {
      print('❌ Error scheduling anniversary notification: $e');
    }
  }

  /// 알림 설정 저장
  static Future<void> setNotificationEnabled(String type, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String key;

      switch (type) {
        case 'diary':
          key = _diaryReminderKey;
          break;
        case 'diary_created':
          key = _partnerDiaryKey;
          break;
        case 'diary_comment':
          key = _diaryCommentKey;
          break;
        case 'couple_message':
          key = _coupleMessageKey;
          break;
        default:
          return;
      }

      await prefs.setBool(key, enabled);

      // 일기 알림인 경우 스케줄링 처리
      if (type == 'diary') {
        if (enabled) {
          await scheduleDailyDiaryReminder();
        } else {
          await _localNotifications.cancel(1); // 일기 알림 ID는 1
        }
      }

      print('⚙️ $type notification ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Error setting notification preference: $e');
    }
  }

  /// 알림 설정 가져오기
  static Future<bool> isNotificationEnabled(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String key;

      switch (type) {
        case 'diary':
          key = _diaryReminderKey;
          break;
        case 'diary_created':
          key = _partnerDiaryKey;
          break;
        case 'diary_comment':
          key = _diaryCommentKey;
          break;
        case 'couple_message':
          key = _coupleMessageKey;
          break;
        default:
          return true;
      }

      return prefs.getBool(key) ?? true; // 기본값은 true
    } catch (e) {
      print('❌ Error getting notification preference: $e');
      return false;
    }
  }

  /// 모든 알림 설정 가져오기
  static Future<Map<String, bool>> getAllNotificationSettings() async {
    return {
      'diary': await isNotificationEnabled('diary'),
      'diary_created': await isNotificationEnabled('diary_created'),
      'diary_comment': await isNotificationEnabled('diary_comment'),
      'couple_message': await isNotificationEnabled('couple_message'),
    };
  }

  /// 테스트 알림 보내기
  static Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: '🧪 테스트 알림',
      body: '알림이 정상적으로 작동합니다!',
      payload: jsonEncode({'type': 'test'}),
    );
  }

  /// DateTime을 TZDateTime으로 변환
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final seoul = tz.getLocation('Asia/Seoul');
    return tz.TZDateTime.from(dateTime, seoul);
  }
}

/// 백그라운드 메시지 핸들러 (톱레벨 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('📨 Background message: ${message.notification?.title}');
}
