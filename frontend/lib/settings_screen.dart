import 'package:flutter/material.dart';
import 'services/anniversary_service.dart';
import 'services/nickname_service.dart';
import 'services/auth_service.dart';
import 'screens/debug/environment_debug_screen.dart';
import 'config/environment.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? _currentAnniversary;
  bool _canEditAnniversary = true;
  String? _anniversarySetterName;
  String? _nickname;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final anniversaryData = await AnniversaryService.getAnniversary();
      final nickname = await NicknameService.getNickname();
      final email = await AuthService.getCurrentUserEmail();

      if (mounted) {
        setState(() {
          _currentAnniversary = anniversaryData?['anniversaryDate'] as DateTime?;
          _canEditAnniversary = anniversaryData?['canEdit'] as bool? ?? true;
          _anniversarySetterName = anniversaryData?['setterName'] as String?;
          _nickname = nickname;
          _userEmail = email;
          _isLoading = false;
        });
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

  Future<void> _editAnniversary() async {
    if (!_canEditAnniversary) {
      _showPermissionDeniedDialog();
      return;
    }
    
    final result = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (context) => AnniversaryEditScreen(
          currentDate: _currentAnniversary,
          canEdit: _canEditAnniversary,
        ),
      ),
    );

    if (result != null) {
      // Reload data to get updated state
      await _loadUserData();
    }
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('캐시 초기화'),
          content: const Text('로컬에 저장된 기념일 및 기타 캐시 데이터를 모두 삭제합니다.\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  // Clear anniversary cache
                  await AnniversaryService.clearAnniversary();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('캐시가 성공적으로 초기화되었습니다'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload data
                    _loadUserData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('캐시 초기화 중 오류가 발생했습니다: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                '초기화',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
    if (_currentAnniversary == null) return '설정되지 않음';
    
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    
    final days = AnniversaryService.calculateDaysSince(_currentAnniversary!);
    final formattedDate = '${_currentAnniversary!.year}년 ${monthNames[_currentAnniversary!.month - 1]} ${_currentAnniversary!.day}일';
    
    String result = '$formattedDate (D+$days)';
    
    if (!_canEditAnniversary && _anniversarySetterName != null) {
      result += '\n($_anniversarySetterName님이 설정)';
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Info Section
                  _buildSection(
                    title: '사용자 정보',
                    children: [
                      _buildInfoTile(
                        icon: Icons.person,
                        title: '닉네임',
                        subtitle: _nickname ?? '설정되지 않음',
                        onTap: () {
                          // TODO: Navigate to nickname edit screen
                        },
                      ),
                      _buildInfoTile(
                        icon: Icons.email,
                        title: '이메일',
                        subtitle: _userEmail ?? '알 수 없음',
                        onTap: null, // Email is not editable
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Couple Info Section
                  _buildSection(
                    title: '커플 정보',
                    children: [
                      _buildInfoTile(
                        icon: Icons.favorite,
                        title: '만난 날',
                        subtitle: _getFormattedAnniversary(),
                        onTap: _canEditAnniversary ? _editAnniversary : null,
                        isReadOnly: !_canEditAnniversary,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Debug Section (only in development)
                  if (EnvironmentConfig.enableDebugMode) ...[
                    _buildSection(
                      title: '개발자 도구',
                      children: [
                        _buildInfoTile(
                          icon: Icons.settings,
                          title: '환경 설정',
                          subtitle: '개발/스테이징/프로덕션 환경 변경',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EnvironmentDebugScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Account Section
                  _buildSection(
                    title: '계정',
                    children: [
                      _buildInfoTile(
                        icon: Icons.refresh,
                        title: '캐시 초기화',
                        subtitle: '로컬 저장된 데이터를 모두 지웁니다',
                        onTap: _clearCache,
                      ),
                      _buildInfoTile(
                        icon: Icons.logout,
                        title: '로그아웃',
                        subtitle: '계정에서 로그아웃합니다',
                        onTap: _signOut,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red.shade300 : Colors.white.withValues(alpha: 0.9),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red.shade300 : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive 
                ? Colors.red.shade200 
                : Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right,
                color: isDestructive 
                    ? Colors.red.shade300 
                    : Colors.white.withValues(alpha: 0.7),
              )
            : isReadOnly 
                ? Icon(
                    Icons.lock,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  )
                : null,
        onTap: onTap,
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('수정 불가'),
          content: Text(
            _anniversarySetterName != null 
                ? '기념일은 $_anniversarySetterName님이 설정하셨습니다.\n설정한 사용자만 수정할 수 있습니다.'
                : '기념일은 설정한 사용자만 수정할 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}

class AnniversaryEditScreen extends StatefulWidget {
  final DateTime? currentDate;
  final bool canEdit;

  const AnniversaryEditScreen({
    super.key,
    this.currentDate,
    this.canEdit = true,
  });

  @override
  State<AnniversaryEditScreen> createState() => _AnniversaryEditScreenState();
}

class _AnniversaryEditScreenState extends State<AnniversaryEditScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _selectedDate = widget.currentDate ?? DateTime.now();
    
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

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _saveAnniversary() async {
    if (_isLoading) return;

    final validation = AnniversaryService.validateAnniversaryDate(_selectedDate);
    if (!validation['isValid']) {
      _showErrorSnackBar(validation['error']);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (widget.currentDate == null) {
        // First time setting anniversary
        success = await AnniversaryService.saveAnniversary(_selectedDate);
      } else {
        // Updating existing anniversary
        success = await AnniversaryService.updateAnniversary(_selectedDate);
      }
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(_selectedDate);
        }
      } else {
        _showErrorSnackBar('기념일 저장에 실패했습니다.');
      }
    } catch (error) {
      print('Anniversary save error: $error');
      _showErrorSnackBar('기념일 저장에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentDate == null ? '만난 날 설정' : '만난 날 확인'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current selection display
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Selected date display
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_selectedDate.year}년 ${monthNames[_selectedDate.month - 1]} ${_selectedDate.day}일',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Date picker - only show if can edit
                              if (widget.canEdit) ...[
                                Row(
                                  children: [
                                    // Year picker
                                    Expanded(
                                      child: _buildDateDial(
                                        'Year',
                                        _selectedDate.year,
                                        DateTime.now().year - 10,
                                        DateTime.now().year,
                                        (value) {
                                          setState(() {
                                            _selectedDate = DateTime(value, _selectedDate.month, _selectedDate.day);
                                          });
                                        },
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Month picker
                                    Expanded(
                                      child: _buildDateDial(
                                        'Month',
                                        _selectedDate.month,
                                        1,
                                        12,
                                        (value) {
                                          final maxDay = DateTime(_selectedDate.year, value + 1, 0).day;
                                          final day = _selectedDate.day > maxDay ? maxDay : _selectedDate.day;
                                          setState(() {
                                            _selectedDate = DateTime(_selectedDate.year, value, day);
                                          });
                                        },
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Day picker
                                    Expanded(
                                      child: _buildDateDial(
                                        'Day',
                                        _selectedDate.day,
                                        1,
                                        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day,
                                        (value) {
                                          setState(() {
                                            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, value);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Read-only display
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '상대방이 설정한 기념일',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '기념일은 설정한 사용자만 수정할 수 있습니다',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Save/Close button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.canEdit 
                                ? (_isLoading ? null : _saveAnniversary)
                                : () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF667eea),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: widget.canEdit
                                ? (_isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF667eea),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        widget.currentDate == null ? '설정하기' : '수정하기',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ))
                                : const Text(
                                    '닫기',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  Widget _buildDateDial(String label, int currentValue, int minValue, int maxValue, Function(int) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                currentValue.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStepperButton(
                    icon: Icons.remove,
                    onPressed: currentValue > minValue 
                        ? () => onChanged(currentValue - 1)
                        : null,
                  ),
                  _buildStepperButton(
                    icon: Icons.add,
                    onPressed: currentValue < maxValue 
                        ? () => onChanged(currentValue + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null 
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null 
              ? Colors.white
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}