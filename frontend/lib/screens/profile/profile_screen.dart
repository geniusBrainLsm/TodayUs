import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/nickname_service.dart';
import '../../services/auth_service.dart';
import '../../services/anniversary_service.dart';
import '../../services/diary_service.dart';
import '../../services/notification_service.dart';
import '../../services/profile_image_service.dart';
import '../anniversary/anniversary_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final DiaryService _diaryService = DiaryService();
  
  String? _nickname;
  String? _userEmail;
  String? _profileImageUrl;
  File? _selectedImage;
  DateTime? _anniversaryDate;
  bool _isLoading = true;
  
  // Statistics
  int _totalDiaries = 0;
  List<Map<String, dynamic>> _emotionStats = [];
  
  // Notification settings
  Map<String, bool> _notificationSettings = {
    'diary': true,
    'couple_message': true,
    'anniversary': false,
    'weekly_feedback': true,
  };

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
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

    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final nickname = await NicknameService.getNickname();
      final email = await AuthService.getCurrentUserEmail();
      final anniversary = await AnniversaryService.getAnniversary();
      
      // 프로필 이미지 URL 가져오기
      String? profileImageUrl;
      try {
        profileImageUrl = await ProfileImageService.getProfileImageUrl();
      } catch (e) {
        print('Error loading profile image: $e');
      }

      // Load statistics
      int totalDiaries = 0;
      List<Map<String, dynamic>> emotionStats = [];
      
      try {
        final recentDiaries = await _diaryService.getRecentDiaries(limit: 100);
        totalDiaries = recentDiaries.length;
        
        // Get emotion stats for the last 30 days
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 30));
        emotionStats = await _diaryService.getEmotionStats(
          startDate: startDate,
          endDate: endDate,
        );
      } catch (diaryError) {
        print('Error loading diary statistics: $diaryError');
      }

      // Load notification settings
      Map<String, bool> notificationSettings = {};
      try {
        notificationSettings = await NotificationService.getAllNotificationSettings();
      } catch (notificationError) {
        print('Error loading notification settings: $notificationError');
        // Use default settings if error
        notificationSettings = {
          'diary': true,
          'couple_message': true,
          'anniversary': false,
          'weekly_feedback': true,
        };
      }

      if (mounted) {
        setState(() {
          _nickname = nickname;
          _userEmail = email;
          _profileImageUrl = profileImageUrl;
          _anniversaryDate = anniversary?['anniversaryDate'] as DateTime?;
          _totalDiaries = totalDiaries;
          _emotionStats = emotionStats;
          _notificationSettings = notificationSettings;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 알림 설정 변경
  Future<void> _updateNotificationSetting(String type, bool enabled) async {
    try {
      await NotificationService.setNotificationEnabled(type, enabled);
      
      if (mounted) {
        setState(() {
          _notificationSettings[type] = enabled;
        });
        
        // 사용자에게 피드백 제공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? '${_getNotificationTypeName(type)} 알림이 활성화되었습니다'
                : '${_getNotificationTypeName(type)} 알림이 비활성화되었습니다'
            ),
            backgroundColor: enabled ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating notification setting: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 설정 변경 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 알림 타입 이름 가져오기
  String _getNotificationTypeName(String type) {
    switch (type) {
      case 'diary':
        return '일기 작성';
      case 'couple_message':
        return '커플 메시지';
      case 'anniversary':
        return '기념일';
      case 'weekly_feedback':
        return '주간 피드백';
      default:
        return '알림';
    }
  }

  /// 테스트 알림 보내기
  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.sendTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('테스트 알림이 전송되었습니다! 📱'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('테스트 알림 전송 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getFormattedAnniversary() {
    if (_anniversaryDate == null) return '설정되지 않음';
    
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    
    final days = AnniversaryService.calculateDaysSince(_anniversaryDate!);
    final formattedDate = '${_anniversaryDate!.year}년 ${monthNames[_anniversaryDate!.month - 1]} ${_anniversaryDate!.day}일';
    
    return '$formattedDate (D+$days)';
  }

  /// 프로필 이미지 편집 (바로 갤러리 열기)
  Future<void> _editProfileImage() async {
    // 바로 갤러리에서 이미지 선택
    await _pickImage(ImageSource.gallery);
  }


  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // 파일 유효성 검증
        if (!ProfileImageService.validateImageFile(imageFile)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('유효하지 않은 이미지 파일입니다. (최대 5MB, jpg/png/gif/webp만 허용)'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // 로딩 상태 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          ),
        );

        try {
          // 서버에 업로드
          final imageUrl = await ProfileImageService.uploadProfileImage(imageFile);
          
          if (mounted) {
            Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
            
            setState(() {
              _selectedImage = imageFile;
              _profileImageUrl = imageUrl;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프로필 사진이 성공적으로 업로드되었습니다! 📸'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('프로필 사진 업로드 실패: ${e.toString()}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    // 삭제할 프로필 이미지가 있는지 확인
    if (_profileImageUrl == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제할 프로필 사진이 없습니다'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // 로딩 상태 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );

      // 서버에서 프로필 이미지 삭제
      if (_profileImageUrl != null) {
        await ProfileImageService.deleteProfileImage();
      }

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        setState(() {
          _selectedImage = null;
          _profileImageUrl = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 사진이 삭제되었습니다'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 사진 삭제 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        _nickname?.substring(0, 1).toUpperCase() ?? '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Color(0xFF667eea),
        ),
      ),
    );
  }

  /// 닉네임 편집
  Future<void> _editNickname() async {
    final TextEditingController controller = TextEditingController(text: _nickname);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('닉네임 변경'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '새 닉네임을 입력하세요',
              border: OutlineInputBorder(),
            ),
            maxLength: 20,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final newNickname = controller.text.trim();
                if (newNickname.isNotEmpty && newNickname != _nickname) {
                  try {
                    await NicknameService.updateNickname(newNickname);
                    if (mounted) {
                      setState(() {
                        _nickname = newNickname;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('닉네임이 "$newNickname"으로 변경되었습니다'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('닉네임 변경 중 오류가 발생했습니다'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                '변경',
                style: TextStyle(color: Color(0xFF667eea)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                ),
              )
            : AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: CustomScrollView(
                      slivers: [
                        // Clean Profile Header
                        SliverToBoxAdapter(
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                // App Bar
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '프로필',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                                
                                // Profile Header
                                _buildCleanProfileHeader(),
                                
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        
                        // Content with overlap effect
                        SliverToBoxAdapter(
                          child: Transform.translate(
                            offset: const Offset(0, -10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  
                                  // Settings Section
                                  _buildSettingsSection(),
                                  
                                  const SizedBox(height: 100), // Bottom padding
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCleanProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Profile Avatar with edit functionality
          GestureDetector(
            onTap: _editProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFF667eea).withValues(alpha: 0.2),
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(47), // 테두리를 고려한 radius
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : _profileImageUrl != null
                            ? Image.network(
                                _profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar();
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF667eea),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _buildDefaultAvatar(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 이미지가 있을 때 삭제 버튼 표시
                if (_selectedImage != null || _profileImageUrl != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: _removeProfileImage,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _editNickname,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nickname ?? '사용자',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          Text(
            _userEmail ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          if (_anniversaryDate != null) ...[
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.pink.shade100,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 20,
                    color: Colors.pink.shade400,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'D+${AnniversaryService.calculateDaysSince(_anniversaryDate!)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.pink.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '함께한 날',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.pink.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '감정 분석',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          if (_emotionStats.isNotEmpty) ...[
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 30일 주요 감정',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Top emotions with progress bars
                  Column(
                    children: _emotionStats.take(3).map((stat) {
                      final emotion = stat['emotion'] as String;
                      final percentage = stat['percentage'] as double;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getEmotionEmoji(emotion),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _getEmotionLabel(emotion),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: percentage / 100,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                              ),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mood,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아직 분석할 일기가 없어요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '일기를 작성하면 감정 분석을 확인할 수 있어요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '설정',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildModernSettingsTile(
            icon: Icons.celebration,
            title: '기념일 관리',
            subtitle: '특별한 날들을 확인하고 관리하세요',
            onTap: _showAnniversaryManagement,
          ),
          const SizedBox(height: 8),
          _buildModernSettingsTile(
            icon: Icons.notifications,
            title: '알림 설정',
            subtitle: '푸시 알림 및 알림 관리',
            onTap: _showNotificationSettings,
          ),
          const SizedBox(height: 8),
          _buildModernSettingsTile(
            icon: Icons.privacy_tip,
            title: '개인정보 처리방침',
            subtitle: '개인정보 보호 정책',
            onTap: _showPrivacyPolicy,
          ),
          const SizedBox(height: 8),
          _buildModernSettingsTile(
            icon: Icons.help_outline,
            title: '도움말',
            subtitle: '자주 묻는 질문 및 지원',
            onTap: _showHelp,
          ),
          const SizedBox(height: 8),
          _buildModernSettingsTile(
            icon: Icons.logout,
            title: '로그아웃',
            subtitle: '계정에서 로그아웃',
            onTap: _signOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive 
                      ? Colors.red.withValues(alpha: 0.1)
                      : const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive 
                      ? Colors.red.shade600
                      : const Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive 
                            ? Colors.red.shade600
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDestructive 
                            ? Colors.red.shade400
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withValues(alpha: 0.1)
                    : const Color(0xFF667eea).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive 
                    ? Colors.red.shade600
                    : const Color(0xFF667eea),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive 
                          ? Colors.red.shade600
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDestructive 
                          ? Colors.red.shade400
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 48,
      endIndent: 16,
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion) {
      case '😊': return '😊';
      case '🥰': return '🥰';
      case '😌': return '😌';
      case '😔': return '😔';
      case '😠': return '😠';
      case '😰': return '😰';
      case '🤔': return '🤔';
      case '😴': return '😴';
      default: return emotion;
    }
  }

  String _getEmotionLabel(String emotion) {
    switch (emotion) {
      case '😊': return '행복해요';
      case '🥰': return '사랑스러워요';
      case '😌': return '평온해요';
      case '😔': return '우울해요';
      case '😠': return '화나요';
      case '😰': return '불안해요';
      case '🤔': return '복잡해요';
      case '😴': return '피곤해요';
      default: return emotion;
    }
  }

  // 기념일 관리 화면으로 이동
  void _showAnniversaryManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AnniversaryManagementScreen(),
      ),
    ).then((_) {
      // 기념일 관리 화면에서 돌아올 때 데이터 새로고침
      _loadUserData();
    });
  }

  // 알림 설정 기능
  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Color(0xFF667eea),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '알림 설정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildNotificationTile(
                    title: '일기 작성 알림',
                    subtitle: '매일 저녁 일기 작성을 알려드려요',
                    value: _notificationSettings['diary'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('diary', value),
                  ),
                  _buildNotificationTile(
                    title: '커플 메시지 알림',
                    subtitle: '파트너가 메시지를 보낼 때 알려드려요',
                    value: _notificationSettings['couple_message'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('couple_message', value),
                  ),
                  _buildNotificationTile(
                    title: '기념일 알림',
                    subtitle: '특별한 날을 미리 알려드려요',
                    value: _notificationSettings['anniversary'] ?? false,
                    onChanged: (value) => _updateNotificationSetting('anniversary', value),
                  ),
                  _buildNotificationTile(
                    title: '주간 피드백 알림',
                    subtitle: '주간 감정 분석 결과를 알려드려요',
                    value: _notificationSettings['weekly_feedback'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('weekly_feedback', value),
                  ),
                  
                  // 테스트 알림 버튼 추가
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendTestNotification,
                      icon: const Icon(Icons.notification_add, color: Colors.white),
                      label: const Text(
                        '테스트 알림 보내기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF667eea),
          ),
        ],
      ),
    );
  }

  // 개인정보 처리방침
  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.privacy_tip,
                      color: Color(0xFF667eea),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '개인정보 처리방침',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacySection(
                      '1. 개인정보의 처리 목적',
                      'TodayUs는 다음의 목적을 위하여 개인정보를 처리합니다.\n\n'
                      '• 서비스 제공 및 계정 관리\n'
                      '• 일기 작성 및 감정 분석 서비스\n'
                      '• 커플 연결 및 소통 기능\n'
                      '• 서비스 개선 및 통계 분석',
                    ),
                    _buildPrivacySection(
                      '2. 개인정보의 처리 및 보유기간',
                      '회원가입일로부터 서비스 탈퇴 시까지 보유합니다.\n'
                      '단, 관련 법령에 따라 일정 기간 보관이 필요한 경우 해당 기간 동안 보관합니다.',
                    ),
                    _buildPrivacySection(
                      '3. 개인정보의 제3자 제공',
                      'TodayUs는 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다.\n'
                      '다만, 법령에 의해 요구되는 경우는 예외입니다.',
                    ),
                    _buildPrivacySection(
                      '4. 개인정보 보호책임자',
                      '개인정보 보호에 관한 문의사항이 있으시면 아래 연락처로 문의해 주세요.\n\n'
                      '이메일: privacy@todayus.com\n'
                      '전화: 02-1234-5678',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 도움말
  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Color(0xFF667eea),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '도움말',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildHelpTile(
                    icon: Icons.edit_note,
                    title: '일기 작성하기',
                    subtitle: '매일의 감정과 생각을 기록해보세요',
                    onTap: () {},
                  ),
                  _buildHelpTile(
                    icon: Icons.favorite,
                    title: '만난 날 설정하기',
                    subtitle: '커플의 특별한 날을 설정하고 기념하세요',
                    onTap: () {},
                  ),
                  _buildHelpTile(
                    icon: Icons.analytics,
                    title: '감정 분석 보기',
                    subtitle: '나의 감정 패턴을 확인해보세요',
                    onTap: () {},
                  ),
                  _buildHelpTile(
                    icon: Icons.notifications,
                    title: '알림 설정하기',
                    subtitle: '일기 작성 알림과 다양한 알림을 설정하세요',
                    onTap: () {},
                  ),
                  _buildHelpTile(
                    icon: Icons.contact_support,
                    title: '문의하기',
                    subtitle: '궁금한 점이 있으시면 언제든 연락하세요',
                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@todayus.com',
                        queryParameters: {
                          'subject': 'TodayUs 문의사항',
                        },
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TodayUs v1.0.0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '커플을 위한 감정 일기 앱',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}