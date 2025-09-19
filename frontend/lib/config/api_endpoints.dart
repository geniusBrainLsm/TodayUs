import 'environment.dart';

/// 모든 API 엔드포인트를 중앙에서 관리
class ApiEndpoints {
  // Base URL 가져오기
  static String get baseUrl => EnvironmentConfig.baseUrl;
  
  // ================================================================
  // Authentication 관련 엔드포인트
  // ================================================================
  
  /// OAuth2 소셜 로그인 (직접 토큰 전송)
  static String get kakaoLogin => '$baseUrl/api/auth/kakao';
  static String get googleLogin => '$baseUrl/api/auth/google';
  
  /// 인증 관련
  static String get authMe => '$baseUrl/api/auth/me';
  static String get authValidate => '$baseUrl/api/auth/validate';
  static String get onboardingStatus => '$baseUrl/api/auth/onboarding-status';
  
  // ================================================================
  // User 관련 엔드포인트  
  // ================================================================
  
  /// 사용자 정보
  static String get users => '$baseUrl/api/users';
  static String userById(int userId) => '$baseUrl/api/users/$userId';
  
  /// 닉네임 관련
  static String get checkNikname => '$baseUrl/api/users/check-nickname';
  static String checkNicknameAvailability(String nickname) => '$baseUrl/api/users/check-nickname?nickname=${Uri.encodeComponent(nickname)}';
  static String get setNickname => '$baseUrl/api/auth/nickname';
  static String get getNickname => '$baseUrl/api/users/nickname';
  
  /// 프로필 이미지 관련
  static String get profileImage => '$baseUrl/api/profile/image';
  static String get uploadProfileImage => '$baseUrl/api/profile/image';
  static String get deleteProfileImage => '$baseUrl/api/profile/image';
  
  // ================================================================
  // Couple 관련 엔드포인트
  // ================================================================
  
  /// 커플 정보
  static String get couples => '$baseUrl/api/couples';
  static String get coupleInfo => '$baseUrl/api/couples/info';
  static String get disconnectCouple => '$baseUrl/api/couples/disconnect';
  static String get connectCouple => '$baseUrl/api/couples/connect';
  
  /// 초대 코드
  static String get inviteCodes => '$baseUrl/api/couples/invite-code';
  static String get generateInviteCode => '$baseUrl/api/couples/invite-code';
  static String get connectWithCode => '$baseUrl/api/couples/connect';
  static String get cancelInvite => '$baseUrl/api/couples/invite-code/cancel';
  static String validateInviteCode(String code) => '$baseUrl/api/couples/invite-code/validate?code=$code';
  
  // ================================================================
  // Anniversary 관련 엔드포인트
  // ================================================================
  
  /// 기념일
  static String get anniversaries => '$baseUrl/api/anniversary';
  static String get setAnniversary => '$baseUrl/api/anniversary';
  static String get getAnniversary => '$baseUrl/api/anniversary';
  
  // ================================================================
  // Diary 관련 엔드포인트
  // ================================================================
  
  /// 일기 CRUD
  static String get diaries => '$baseUrl/api/diaries';
  static String diaryById(int diaryId) => '$baseUrl/api/diaries/$diaryId';
  static String get recentDiaries => '$baseUrl/api/diaries/recent';
  static String get todayDiaryExists => '$baseUrl/api/diaries/today/exists';
  
  /// 일기 통계 및 분석
  static String get emotionStats => '$baseUrl/api/diaries/emotions/stats';
  static String get weeklyEmotionSummary => '$baseUrl/api/diaries/weekly-emotion-summary';
  static String get coupleSummary => '$baseUrl/api/diaries/couple-summary';
  
  /// 일기 댓글
  static String diaryComments(int diaryId) => '$baseUrl/api/diaries/$diaryId/comments';
  
  /// 일기 이미지 업로드
  static String diaryImage(int diaryId) => '$baseUrl/api/diaries/$diaryId/image';
  static String get uploadDiaryImage => '$baseUrl/api/diaries/upload-image';
  
  // ================================================================
  // Time Capsule 관련 엔드포인트
  // ================================================================
  
  /// 타임캡슐 CRUD
  static String get timeCapsules => '$baseUrl/api/time-capsules';
  static String timeCapsuleById(int timeCapsuleId) => '$baseUrl/api/time-capsules/$timeCapsuleId';
  static String timeCapsuleOpen(int timeCapsuleId) => '$baseUrl/api/time-capsules/$timeCapsuleId/open';
  
  /// 타임캡슐 관리
  static String get openableTimeCapsules => '$baseUrl/api/time-capsules/openable';
  static String get timeCapsuleSummary => '$baseUrl/api/time-capsules/summary';
  
  // ================================================================
  // Couple Message (대신 전달하기) 관련 엔드포인트
  // ================================================================
  
  /// 메시지 CRUD
  static String get coupleMessages => '$baseUrl/api/couple-messages';
  static String get messageForPopup => '$baseUrl/api/couple-messages/popup';
  static String get messageHistory => '$baseUrl/api/couple-messages/history';
  static String get weeklyUsage => '$baseUrl/api/couple-messages/weekly-usage';
  
  /// 메시지 상태 관리
  static String markAsDelivered(int messageId) => '$baseUrl/api/couple-messages/$messageId/delivered';
  static String markAsRead(int messageId) => '$baseUrl/api/couple-messages/$messageId/read';
  
  // ================================================================
  // File Upload 관련 엔드포인트
  // ================================================================
  
  /// 파일 업로드
  static String get uploadImage => '$baseUrl/api/upload/image';
  static String get uploadFile => '$baseUrl/api/upload/file';
  
  // ================================================================
  // 유틸리티 메서드들
  // ================================================================
  
  /// 페이지네이션 쿼리 추가
  static String withPagination(String endpoint, {int page = 0, int size = 10}) {
    return '$endpoint?page=$page&size=$size';
  }
  
  /// 날짜 범위 쿼리 추가
  static String withDateRange(String endpoint, {DateTime? startDate, DateTime? endDate}) {
    if (startDate == null && endDate == null) return endpoint;
    
    final params = <String>[];
    if (startDate != null) {
      params.add('startDate=${startDate.toIso8601String().split('T')[0]}');
    }
    if (endDate != null) {
      params.add('endDate=${endDate.toIso8601String().split('T')[0]}');
    }
    
    return '$endpoint?${params.join('&')}';
  }
  
  /// 검색 쿼리 추가
  static String withSearch(String endpoint, String query) {
    return '$endpoint?search=${Uri.encodeComponent(query)}';
  }
  
  /// 정렬 쿼리 추가
  static String withSort(String endpoint, String sortBy, {bool ascending = true}) {
    final direction = ascending ? 'asc' : 'desc';
    return '$endpoint?sort=$sortBy,$direction';
  }
  
  /// 복합 쿼리 파라미터 추가
  static String withParams(String endpoint, Map<String, dynamic> params) {
    if (params.isEmpty) return endpoint;
    
    final queryParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
    
    return '$endpoint?$queryParams';
  }
  
  // ================================================================
  // 디버깅용 메서드들
  // ================================================================
  
  /// 모든 엔드포인트 목록 (디버깅용)
  static Map<String, String> getAllEndpoints() {
    return {
      // Auth
      'kakaoLogin': kakaoLogin,
      'googleLogin': googleLogin,
      'authMe': authMe,
      'authValidate': authValidate,
      'onboardingStatus': onboardingStatus,
      
      // User
      'users': users,
      'checkNikname': checkNikname,
      'setNickname': setNickname,
      'getNickname': getNickname,
      
      // Couple
      'couples': couples,
      'coupleInfo': coupleInfo,
      'disconnectCouple': disconnectCouple,
      'connectCouple': connectCouple,
      'inviteCodes': inviteCodes,
      'generateInviteCode': generateInviteCode,
      'connectWithCode': connectWithCode,
      'cancelInvite': cancelInvite,
      
      // Anniversary
      'anniversaries': anniversaries,
      'setAnniversary': setAnniversary,
      'getAnniversary': getAnniversary,
      
      // Diary
      'diaries': diaries,
      'recentDiaries': recentDiaries,
      'emotionStats': emotionStats,
      'weeklyEmotionSummary': weeklyEmotionSummary,
      'coupleSummary': coupleSummary,
      
      // Time Capsule
      'timeCapsules': timeCapsules,
      'openableTimeCapsules': openableTimeCapsules,
      'timeCapsuleSummary': timeCapsuleSummary,
      
      // Couple Message
      'coupleMessages': coupleMessages,
      'messageForPopup': messageForPopup,
      'messageHistory': messageHistory,
      'weeklyUsage': weeklyUsage,
      
      // File Upload
      'uploadImage': uploadImage,
      'uploadFile': uploadFile,
    };
  }
  
  /// 엔드포인트 정상성 체크 (디버깅용)
  static void printAllEndpoints() {
    if (!EnvironmentConfig.enableDebugMode) return;
    
    print('=== API Endpoints (${EnvironmentConfig.current.name}) ===');
    print('Base URL: $baseUrl');
    print('');
    
    final endpoints = getAllEndpoints();
    endpoints.forEach((name, url) {
      print('$name: $url');
    });
    print('');
  }
}