import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/anniversary_service.dart';
import '../../services/diary_service.dart';
import '../../services/couple_message_service.dart';
import '../../services/weekly_feedback_service.dart';
import '../../services/milestone_service.dart';
import '../../services/custom_anniversary_service.dart';
import '../../widgets/couple_message_popup.dart';
import '../diary/diary_write_screen.dart';
import '../diary/diary_detail_screen.dart';
import '../weekly_emotion_summary_screen.dart';
import '../weekly_feedback/weekly_feedback_history_screen.dart';
import '../../config/environment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  DateTime? _anniversaryDate;
  int? _daysSince;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _recentDiaries = [];
  List<Map<String, dynamic>> _emotionStats = [];
  final DiaryService _diaryService = DiaryService();
  int _totalDiaries = 0;
  final WeeklyFeedbackService _weeklyFeedbackService = WeeklyFeedbackService();
  bool _canWriteDiary = true;
  String _coupleSummary = '로딩 중...';
  List<Map<String, dynamic>> _unreadFeedbacks = [];
  Timer? _refreshTimer;
  Map<String, dynamic>? _todaysMilestone;
  List<Map<String, dynamic>> _todaysCustomAnniversaries = [];
  bool _hasAnyTodaysAnniversary = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _loadData();
    _checkDiaryWritePermission();
    _checkForCoupleMessage();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 앱이 포그라운드로 돌아올 때 일기 상태 업데이트
    if (state == AppLifecycleState.resumed) {
      print('🟡 앱이 포그라운드로 복귀 - 일기 상태 업데이트');
      _refreshCoupleSummary();
    }
  }

  /// 커플 요약 새로고침
  Future<void> _refreshCoupleSummary() async {
    try {
      print('🟡 커플 요약 새로고침 시작');
      final newSummary = await _diaryService.getCoupleSummary();
      
      if (mounted) {
        setState(() {
          _coupleSummary = newSummary;
        });
        print('🟢 커플 요약 업데이트 완료: ${newSummary.replaceAll('\n', ' ')}');
      }
    } catch (e) {
      print('🔴 커플 요약 새로고침 오류: $e');
    }
  }

  /// 주기적 새로고침 시작 (5분마다)
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      print('🟡 주기적 커플 요약 새로고침');
      _refreshCoupleSummary();
    });
  }

  Future<void> _checkDiaryWritePermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastWriteTimeStr = prefs.getString('last_diary_write_time');
      
      if (lastWriteTimeStr != null) {
        final lastWriteTime = DateTime.parse(lastWriteTimeStr);
        final now = DateTime.now();
        final timeDifference = now.difference(lastWriteTime);
        
        // 6시간(21600초) 이후에만 작성 가능
        if (mounted) {
          setState(() {
            _canWriteDiary = timeDifference.inSeconds >= 21600;
          });
        }
      }
    } catch (e) {
      print('Error checking diary write permission: $e');
      // 오류 발생시 기본적으로 작성 가능하게 설정
      if (mounted) {
        setState(() {
          _canWriteDiary = true;
        });
      }
    }
  }

  Future<void> _checkForCoupleMessage() async {
    try {
      // 잠시 대기 후 체크 (UI 로딩 완료 후)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      final messageData = await CoupleMessageService.getMessageForPopup();
      
      if (messageData != null && mounted) {
        // 팝업 표시
        await showCoupleMessagePopup(
          context, 
          messageData,
          onClosed: () {
            print('Couple message popup closed');
          },
        );
      }
    } catch (e) {
      print('Error checking for couple message: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final anniversary = await AnniversaryService.getAnniversary();
      
      print('🔵 Home screen loading anniversary data: $anniversary');
      
      int? daysSince;
      if (anniversary != null && anniversary['anniversaryDate'] != null) {
        daysSince = AnniversaryService.calculateDaysSince(anniversary['anniversaryDate'] as DateTime);
        print('🟢 Anniversary found: ${anniversary['anniversaryDate']}, Days since: $daysSince');
      } else {
        print('🟡 No anniversary found');
      }

      // Load recent diaries
      List<Map<String, dynamic>> recentDiaries = [];
      List<Map<String, dynamic>> emotionStats = [];
      int totalDiaries = 0;
      String coupleSummary = '서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕';
      
      try {
        recentDiaries = await _diaryService.getRecentDiaries(limit: 3);
        
        // Get total diaries count
        final allDiaries = await _diaryService.getRecentDiaries(limit: 100);
        totalDiaries = allDiaries.length;
        
        // Get emotion stats for the last 30 days
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 30));
        emotionStats = await _diaryService.getEmotionStats(
          startDate: startDate,
          endDate: endDate,
        );

        // Get AI couple summary
        coupleSummary = await _diaryService.getCoupleSummary();
      } catch (diaryError) {
        print('Error loading diary data: $diaryError');
        // Continue without diary data
      }

      // Load unread weekly feedbacks
      List<Map<String, dynamic>> unreadFeedbacks = [];
      try {
        unreadFeedbacks = await _weeklyFeedbackService.getUnreadFeedbacks();
      } catch (feedbackError) {
        print('Error loading weekly feedbacks: $feedbackError');
        // Continue without feedback data
      }

      // Check for today's milestone
      Map<String, dynamic>? todaysMilestone;
      try {
        todaysMilestone = await MilestoneService.getTodaysMilestone();
        if (todaysMilestone != null) {
          print('🎉 Today\'s milestone found: ${todaysMilestone['title']}');
        }
      } catch (milestoneError) {
        print('Error loading milestone: $milestoneError');
      }

      // Check for today's custom anniversaries
      List<Map<String, dynamic>> todaysCustomAnniversaries = [];
      try {
        todaysCustomAnniversaries = await CustomAnniversaryService.getTodaysCustomAnniversaries();
        if (todaysCustomAnniversaries.isNotEmpty) {
          print('🎉 Today\'s custom anniversaries found: ${todaysCustomAnniversaries.length}');
        }
      } catch (customAnniversaryError) {
        print('Error loading custom anniversaries: $customAnniversaryError');
      }

      // Check if there's any anniversary today (milestone or custom)
      bool hasAnyTodaysAnniversary = todaysMilestone != null || todaysCustomAnniversaries.isNotEmpty;

      if (mounted) {
        setState(() {
          _anniversaryDate = anniversary?['anniversaryDate'] as DateTime?;
          _daysSince = daysSince;
          _recentDiaries = recentDiaries;
          _emotionStats = emotionStats;
          _totalDiaries = totalDiaries;
          _coupleSummary = coupleSummary;
          _unreadFeedbacks = unreadFeedbacks;
          _todaysMilestone = todaysMilestone;
          _todaysCustomAnniversaries = todaysCustomAnniversaries;
          _hasAnyTodaysAnniversary = hasAnyTodaysAnniversary;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateLastWriteTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_diary_write_time', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error updating last write time: $e');
    }
  }

  String _getFormattedAnniversary() {
    if (_anniversaryDate == null) return '설정되지 않음';
    
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    
    return '${_anniversaryDate!.year}년 ${monthNames[_anniversaryDate!.month - 1]} ${_anniversaryDate!.day}일';
  }


  Widget _buildMainRobotSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 마스코트 로봇 이미지 (크게)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(60),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                'assets/images/done_robot.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.smart_toy,
                    size: 60,
                    color: Colors.grey[400],
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // AI 일일 응원 메시지
          _buildDailyMessage(),
          
          const SizedBox(height: 24),
          
          // AI 요약 (간단하게)
          if (_coupleSummary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _coupleSummary,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // OO봇 일일 응원 메시지
  Widget _buildDailyMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.blue[600],
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            _getDailyMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[800],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 일일 메시지 생성 (기념일이 있으면 기념일 메시지, 없으면 일반 메시지)
  String _getDailyMessage() {
    // 자동 기념일이 있으면 기념일 메시지 우선
    if (_todaysMilestone != null) {
      return MilestoneService.getMilestoneMessage(_todaysMilestone!);
    }
    
    // 사용자 정의 기념일이 있으면 커스톰 기념일 메시지
    if (_todaysCustomAnniversaries.isNotEmpty) {
      final anniversary = _todaysCustomAnniversaries.first;
      return CustomAnniversaryService.getCustomAnniversaryMessage(anniversary);
    }
    
    // 기본 일일 메시지들
    final messages = [
      "오늘도 서로를 향한 따뜻한 마음으로 하루를 시작해보세요! 💕",
      "작은 관심과 배려가 큰 사랑을 만들어갑니다 🌟",
      "함께하는 모든 순간이 소중한 추억이 되고 있어요 💝",
      "서로의 다름을 이해하며 더 깊은 사랑을 나누세요 🤗",
      "오늘 하루도 서로에게 힘이 되는 연인이 되어보아요 ✨",
      "작은 감사의 마음을 전하는 것만으로도 충분해요 🙏",
      "함께 웃고 함께 꿈꾸는 오늘이 되길 바라요 😊",
      "서로의 꿈을 응원하며 더 단단한 사랑을 만들어가세요 🌈",
    ];
    
    final today = DateTime.now();
    final messageIndex = today.day % messages.length;
    return messages[messageIndex];
  }

  Widget _buildAnniversaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '우리가 만난 날',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getFormattedAnniversary(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'D+${_daysSince ?? 0}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFDF2F8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE91E63),
                      Color(0xFFAD1457),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '우리의 감정 이야기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF831843),
                      ),
                    ),
                    Text(
                      '최근 30일간의 마음',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF9D174D).withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WeeklyEmotionSummaryScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE91E63),
                        Color(0xFFAD1457),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '주간 요약',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Emotion Stats
          Column(
            children: _emotionStats.take(3).map((stat) {
              final emotion = stat['emotion'] as String;
              final percentage = stat['percentage'] as double;
              
              final emotionEmoji = _getEmotionEmoji(emotion);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFCE7F3).withValues(alpha: 0.6),
                      const Color(0xFFFDF2F8).withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      emotionEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getEmotionLabel(emotion),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF831843),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFFE91E63),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE91E63),
                            Color(0xFFAD1457),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiariesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.book,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '최근 일기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_recentDiaries.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Navigate to diary list
                  },
                  child: Text(
                    '더보기',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_recentDiaries.isEmpty)
            // Empty state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아직 작성된 일기가 없어요\n첫 번째 일기를 작성해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            )
          else
            // Recent diaries list
            Column(
              children: _recentDiaries.map((diary) {
                final author = diary['author'] as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DiaryDetailScreen(
                          diaryId: diary['id'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                      // Thumbnail Image (if exists)
                      if (diary['imageUrl'] != null && diary['imageUrl'].toString().isNotEmpty)
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              '${EnvironmentConfig.baseUrl}${diary['imageUrl']}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      // Mood emoji
                      else if (diary['moodEmoji'] != null && diary['moodEmoji'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            diary['moodEmoji'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      const SizedBox(width: 12),
                      
                      // Diary info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diary['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${author['nickname']} • ${_formatDiaryDate(diary['diaryDate'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // AI processed indicator
                      if (diary['aiProcessed'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 배경 패턴
          CustomPaint(
            size: Size(double.infinity, double.infinity),
            painter: DotPatternPainter(),
          ),
          // 메인 콘텐츠
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFE9ECEF),
                ],
              ),
            ),
            child: SafeArea(
              child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshCoupleSummary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 메인 콘텐츠 영역 (헤더 포함)
                        _buildMainContent(),
                        
                        const SizedBox(height: 20),
                        
                        // 하단 통계 영역
                        if (_emotionStats.isNotEmpty) 
                          _buildBottomStats(),
                        
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 헤더 영역
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // OO봇의 오늘의 한마디
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요! 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'OO봇의 오늘의 한마디',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        // D-day (단순 텍스트)
        if (_daysSince != null)
          Text(
            'D+$_daysSince',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
      ],
    );
  }

  // 메인 콘텐츠 세로 배치
  Widget _buildMainContent() {
    return Column(
      children: [
        // 마스코트 로봇 + OO봇 메시지 합친 카드
        _buildRobotWithMessageCard(),
        
        const SizedBox(height: 16),
        
        // OO봇 관계 분석
        if (_coupleSummary.isNotEmpty)
          _buildSummaryCard(),
        
        const SizedBox(height: 16),
        
        // Quick Stats Cards (프로필에서 이동)
        _buildQuickStatsCards(),
      ],
    );
  }

  // 로봇 + 메시지 합친 카드 (헤더 포함)
  Widget _buildRobotWithMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더 부분 (안녕하세요 + D-day)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요! 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OO봇의 오늘의 한마디',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // D-day (단순 텍스트)
              if (_daysSince != null)
                Text(
                  'D+$_daysSince',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 로봇 이미지 (기념일이면 특별한 로봇)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _hasAnyTodaysAnniversary ? Colors.amber[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(60),
              border: _hasAnyTodaysAnniversary ? Border.all(
                color: Colors.amber.shade200,
                width: 3,
              ) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: _hasAnyTodaysAnniversary 
                ? Stack(
                    children: [
                      Image.asset(
                        'assets/images/question_robot.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.celebration,
                            size: 60,
                            color: Colors.amber[600],
                          );
                        },
                      ),
                      // 기념일 효과
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 기념일 아이콘
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🎉',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Image.asset(
                    'assets/images/done_robot.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.smart_toy,
                        size: 60,
                        color: Colors.blue[400],
                      );
                    },
                  ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // OO봇의 한마디 (기념일이면 특별한 스타일)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _hasAnyTodaysAnniversary ? Colors.amber[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasAnyTodaysAnniversary ? Colors.amber[200]! : Colors.blue[100]!,
                width: _hasAnyTodaysAnniversary ? 2 : 1,
              ),
              boxShadow: _hasAnyTodaysAnniversary ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasAnyTodaysAnniversary ? Icons.celebration : Icons.auto_awesome,
                      color: _hasAnyTodaysAnniversary ? Colors.amber[700] : Colors.blue[600],
                      size: 20,
                    ),
                    if (_todaysMilestone != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _todaysMilestone!['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ] else if (_todaysCustomAnniversaries.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        _todaysCustomAnniversaries.first['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getDailyMessage(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _hasAnyTodaysAnniversary ? Colors.amber[900] : Colors.blue[800],
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 로봇 카드
  Widget _buildRobotCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(60),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.asset(
              'assets/images/done_robot.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.smart_toy,
                  size: 60,
                  color: Colors.blue[400],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // OO봇 관계 분석 카드
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.orange[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'OO봇의 관계 분석',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _coupleSummary,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // 일기 작성 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/diary-write');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '오늘 일기 작성하기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 대신 전해주기 버튼 (일기 작성 바로 다음)
          _buildCoupleMessageButton(),
        ],
      ),
    );
  }

  // 하단 통계
  Widget _buildBottomStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '최근 감정 현황',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _emotionStats.take(4).map((stat) {
              return Column(
                children: [
                  Text(
                    _getEmotionEmoji(stat['emotion']),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stat['count']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleEmotionStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 감정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _emotionStats.take(4).map((stat) {
              return Column(
                children: [
                  Text(
                    _getEmotionEmoji(stat['emotion']),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stat['count']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion) {
      case '😊':
        return '😊';
      case '🥰':
        return '🥰';
      case '😌':
        return '😌';
      case '😔':
        return '😔';
      case '😠':
        return '😠';
      case '😰':
        return '😰';
      case '🤔':
        return '🤔';
      case '😴':
        return '😴';
      default:
        return emotion;
    }
  }

  String _getEmotionLabel(String emotion) {
    switch (emotion) {
      case '😊':
        return '행복해요';
      case '🥰':
        return '사랑스러워요';
      case '😌':
        return '평온해요';
      case '😔':
        return '우울해요';
      case '😠':
        return '화나요';
      case '😰':
        return '불안해요';
      case '🤔':
        return '복잡해요';
      case '😴':
        return '피곤해요';
      default:
        return emotion;
    }
  }

  Widget _buildFeedbackNotificationCard() {
    final feedback = _unreadFeedbacks.first;
    final partnerName = feedback['partnerName'] as String? ?? '파트너';
    final weekLabel = feedback['weekLabel'] as String? ?? '이번 주';
    
    return GestureDetector(
      onTap: () {
        // 피드백 상세 화면으로 이동
        _navigateToFeedbackDetail(feedback);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade100,
              Colors.purple.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.pink.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💝 새로운 피드백이 도착했어요!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$partnerName님이 $weekLabel 마음을 전해왔습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.pink.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_unreadFeedbacks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '터치하여 확인하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFeedbackDetail(Map<String, dynamic> feedback) async {
    final feedbackId = feedback['id'] as int?;
    if (feedbackId == null) return;

    try {
      // 피드백 상세 정보 가져오기 (읽음 처리도 함께 됨)
      final detailFeedback = await _weeklyFeedbackService.getFeedback(feedbackId);
      
      if (detailFeedback != null && mounted) {
        // 피드백 상세 다이얼로그 표시
        _showFeedbackDialog(detailFeedback);
        
        // 읽음 처리 후 목록 새로고침
        _loadData();
      }
    } catch (e) {
      print('Error loading feedback detail: $e');
      _showErrorSnackBar('피드백을 불러올 수 없습니다');
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> feedback) {
    final senderName = feedback['senderName'] as String? ?? '파트너';
    final refinedMessage = feedback['refinedMessage'] as String? ?? '';
    final weekLabel = _generateWeekLabel(feedback['weekOf'] as String?);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '$senderName님의 마음',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800,
              ),
            ),
            Text(
              weekLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink.shade200),
                  ),
                  child: Text(
                    refinedMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'AI가 부드럽게 전달한 메시지입니다',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
          if (_unreadFeedbacks.length > 1)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showFeedbackHistoryScreen();
              },
              child: const Text('더 보기'),
            ),
        ],
      ),
    );
  }

  void _showFeedbackHistoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WeeklyFeedbackHistoryScreen(),
      ),
    );
  }

  String _generateWeekLabel(String? weekOfStr) {
    if (weekOfStr == null) return '이번 주';
    
    try {
      final weekOf = DateTime.parse(weekOfStr);
      final month = weekOf.month;
      final dayOfMonth = weekOf.day;
      final weekOfMonth = (dayOfMonth - 1) ~/ 7 + 1;
      return '$month월 $weekOfMonth주차';
    } catch (e) {
      return '이번 주';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDiaryDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final diaryDate = DateTime(date.year, date.month, date.day);
      
      if (diaryDate == today) {
        return '오늘';
      } else if (diaryDate == yesterday) {
        return '어제';
      } else {
        return '${date.month}월 ${date.day}일';
      }
    } catch (e) {
      return dateStr;
    }
  }

  // Quick Stats Cards (프로필에서 이동한 함수)
  Widget _buildQuickStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$_totalDiaries',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '총 일기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_emotionStats.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '감정 종류',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 대신 전해주기 버튼
  Widget _buildCoupleMessageButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF6B8A),
            Color(0xFFFFB6C1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/couple-message-create');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💕 대신 전해주기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI가 마음을 따뜻하게 전달해드려요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 점 패턴 페인터
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    const double spacing = 30;
    const double dotRadius = 1;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}