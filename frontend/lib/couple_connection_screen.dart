import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'models/couple_models.dart';
import 'services/couple_service.dart';
import 'widgets/connection_confirmation_popup.dart';

/// Screen for managing couple connections
class CoupleConnectionScreen extends StatefulWidget {
  const CoupleConnectionScreen({super.key});

  @override
  State<CoupleConnectionScreen> createState() => _CoupleConnectionScreenState();
}

class _CoupleConnectionScreenState extends State<CoupleConnectionScreen> {
  CoupleConnection _connection = CoupleConnection.notConnected();
  bool _isLoading = false;
  Timer? _countdownTimer;
  Timer? _statusPollingTimer;
  String _timeRemaining = '';
  final TextEditingController _inviteCodeController = TextEditingController();
  String? _inviteCodeError;

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusPollingTimer?.cancel();
    _inviteCodeController.dispose();
    super.dispose();
  }

  /// Load current connection status
  Future<void> _loadConnectionStatus() async {
    setState(() => _isLoading = true);
    
    try {
      print('🟡 연결 상태 로딩 시작');
      final connection = await CoupleService.getConnection();
      
      // 연결 상태가 변경되었는지 확인
      final wasConnected = _connection.status == CoupleConnectionStatus.connected;
      final isNowConnected = connection.status == CoupleConnectionStatus.connected;
      
      print('🟡 연결 상태 업데이트 - 상태: ${connection.status}, 초대코드: ${connection.inviteCode}');
      
      setState(() {
        _connection = connection;
        _isLoading = false;
      });
      
      // 새로 연결되었다면 성공 메시지 표시 후 기념일 설정으로 이동
      if (!wasConnected && isNowConnected) {
        _showSuccessSnackBar('파트너와 연결되었습니다! 🎉');
        
        // 2초 후 기념일 설정 화면으로 이동
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/anniversary-setup');
          }
        });
      }
      
      _startCountdownTimer();
      _startStatusPolling();
    } catch (error) {
      print('🔴 연결 상태 로딩 오류: $error');
      setState(() => _isLoading = false);
      _showErrorSnackBar('연결 상태를 불러오는데 실패했습니다');
    }
  }

  /// Start status polling for real-time connection updates
  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    
    // 초대 코드 대기 중일 때만 폴링 활성화
    if (_connection.status == CoupleConnectionStatus.pendingInvite) {
      print('🟡 상태 폴링 시작 - 5초마다 연결 상태 확인');
      
      _statusPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          final connection = await CoupleService.getConnection();
          
          // 연결되었다면 폴링 중단하고 UI 업데이트
          if (connection.status == CoupleConnectionStatus.connected && 
              _connection.status != CoupleConnectionStatus.connected) {
            
            print('🟢 폴링으로 연결 상태 감지됨!');
            timer.cancel();
            
            setState(() {
              _connection = connection;
            });
            
            _showSuccessSnackBar('파트너와 연결되었습니다! 🎉');
            
            // 2초 후 기념일 설정 화면으로 이동
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/anniversary-setup');
              }
            });
          }
        } catch (error) {
          print('🔴 상태 폴링 오류: $error');
          // 네트워크 오류 등은 무시하고 계속 폴링
        }
      });
    }
  }

  /// Start countdown timer for invite expiration
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    
    if (_connection.status == CoupleConnectionStatus.pendingInvite &&
        _connection.inviteExpiresAt != null) {
      _updateTimeRemaining();
      
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateTimeRemaining();
        
        if (_connection.isInviteExpired) {
          timer.cancel();
          _handleInviteExpired();
        }
      });
    }
  }

  /// Update time remaining display
  void _updateTimeRemaining() {
    final timeLeft = _connection.timeUntilExpiration;
    if (timeLeft != null) {
      final hours = timeLeft.inHours;
      final minutes = timeLeft.inMinutes % 60;
      final seconds = timeLeft.inSeconds % 60;
      
      setState(() {
        _timeRemaining = '${hours.toString().padLeft(2, '0')}:'
                        '${minutes.toString().padLeft(2, '0')}:'
                        '${seconds.toString().padLeft(2, '0')}';
      });
    }
  }

  /// Handle invite expiration
  void _handleInviteExpired() async {
    await CoupleService.cancelInvite();
    await _loadConnectionStatus();
    _showErrorSnackBar('초대 코드가 만료되었습니다');
  }

  /// Generate new invite code
  Future<void> _generateInviteCode() async {
    setState(() => _isLoading = true);
    
    try {
      print('🟡 초대 코드 생성 시작');
      final inviteCode = await CoupleService.generateInviteCode();
      
      if (inviteCode != null) {
        print('🟢 초대 코드 생성 성공: $inviteCode');
        
        // 직접 상태 업데이트 (더 빠른 UI 반응)
        final connection = await CoupleService.getConnection();
        setState(() {
          _connection = connection;
        });
        
        print('🟡 연결 상태 업데이트 완료, 현재 코드: ${_connection.inviteCode}');
        _showSuccessSnackBar('초대 코드가 생성되었습니다');
        
        // 초대 코드 생성 후 폴링 시작
        print('🟡 초대 코드 생성 완료, 폴링 시작');
        _startCountdownTimer();
        _startStatusPolling();
      } else {
        print('🔴 초대 코드 생성 실패: null 반환');
        _showErrorSnackBar('초대 코드 생성에 실패했습니다');
      }
    } catch (error) {
      print('🔴 초대 코드 생성 중 오류: $error');
      _showErrorSnackBar('초대 코드 생성 중 오류가 발생했습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Validate and connect with invite code
  Future<void> _connectWithInviteCode() async {
    final code = _inviteCodeController.text.trim();
    
    if (code.isEmpty) {
      setState(() => _inviteCodeError = '초대 코드를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _inviteCodeError = null;
    });

    try {
      final validation = await CoupleService.validateInviteCode(code);
      
      print('🟡 초대 코드 검증 결과: isValid=${validation.isValid}, error=${validation.error}');
      print('🟡 파트너 정보: name=${validation.partnerName}, nickname=${validation.partnerNickname}');
      
      if (!validation.isValid) {
        setState(() {
          _inviteCodeError = validation.error;
          _isLoading = false;
        });
        return;
      }

      // Show enhanced connection confirmation popup
      if (mounted) {
        print('🟡 확인 팝업 표시 시도');
        final confirmed = await ConnectionConfirmationPopup.show(
          context: context,
          partnerName: validation.partnerName!,
          partnerNickname: validation.partnerNickname!,
        );
        
        print('🟡 사용자 확인 결과: $confirmed');

        if (confirmed == true && mounted) {
          print('🟡 실제 연결 진행 - 초대코드: $code');
          
          try {
            final connection = await CoupleService.connectWithInviteCode(code);
            
            if (connection != null) {
              await _loadConnectionStatus();
              _inviteCodeController.clear();
              _showSuccessSnackBar('파트너와 연결되었습니다!');
            } else {
              _showErrorSnackBar('연결에 실패했습니다');
            }
          } catch (connectError) {
            print('🔴 연결 실행 중 오류: $connectError');
            _showErrorSnackBar(connectError.toString().replaceAll('Exception: ', ''));
          }
        }
      }
    } catch (error) {
      _showErrorSnackBar('연결 중 오류가 발생했습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  /// Cancel current invite
  Future<void> _cancelInvite() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await CoupleService.cancelInvite();
      if (success) {
        // 초대 취소 시 폴링 중단
        _statusPollingTimer?.cancel();
        print('🟡 초대 취소로 인한 폴링 중단');
        
        await _loadConnectionStatus();
        _showSuccessSnackBar('초대가 취소되었습니다');
      } else {
        _showErrorSnackBar('초대 취소에 실패했습니다');
      }
    } catch (error) {
      _showErrorSnackBar('초대 취소 중 오류가 발생했습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Disconnect from partner
  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결 해제'),
        content: const Text('정말로 파트너와의 연결을 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('해제하기'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      setState(() => _isLoading = true);
      
      try {
        final success = await CoupleService.disconnect();
        if (success) {
          await _loadConnectionStatus();
          _showSuccessSnackBar('파트너와의 연결이 해제되었습니다');
        } else {
          _showErrorSnackBar('연결 해제에 실패했습니다');
        }
      } catch (error) {
        _showErrorSnackBar('연결 해제 중 오류가 발생했습니다');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Copy invite code to clipboard
  void _copyInviteCode() {
    if (_connection.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _connection.inviteCode!));
      _showSuccessSnackBar('초대 코드가 복사되었습니다');
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE4E1), // 연한 핑크
              Color(0xFFFFF0F5), // 아주 연한 핑크
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingView()
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B8A)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '연결 중...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_connection.status) {
      case CoupleConnectionStatus.notConnected:
        return _buildNotConnectedView();
      case CoupleConnectionStatus.pendingInvite:
        return _buildPendingInviteView();
      case CoupleConnectionStatus.connected:
        return _buildConnectedView();
      case CoupleConnectionStatus.connectionFailed:
        return _buildConnectionFailedView();
    }
  }

  /// Build view when not connected
  Widget _buildNotConnectedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Enhanced header section
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFB6C1),
                        Color(0xFFFF6B8A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '파트너와 연결하기',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '초대 코드로 소중한 사람과\n특별한 순간들을 함께 나눠보세요 💕',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Generate invite code section with enhanced design
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                  const Color(0xFFFFB6C1).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B8A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '초대 코드 생성하기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '파트너가 입력할 6자리 초대 코드를 만들어요',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6B8A),
                        Color(0xFFFFB6C1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _generateInviteCode,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      '초대 코드 생성',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '또는',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Enhanced enter invite code section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFB6C1).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB6C1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.link,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '초대 코드 입력하기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '파트너로부터 받은 6자리 초대 코드를 입력해주세요',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _inviteCodeError != null 
                          ? Colors.red.withValues(alpha: 0.5)
                          : const Color(0xFFFFB6C1).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _inviteCodeController,
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      counterText: '',
                      errorText: _inviteCodeError,
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFB6C1),
                        Color(0xFFFF91A4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB6C1).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _connectWithInviteCode,
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text(
                      '연결하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build view when invite is pending
  Widget _buildPendingInviteView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Enhanced waiting header
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB6C1).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFB6C1).withValues(alpha: 0.3),
                            const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B8A)),
                      ),
                    ),
                    const Icon(
                      Icons.hourglass_empty,
                      size: 40,
                      color: Color(0xFFFF6B8A),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '파트너를 기다리는 중...',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '초대 코드를 파트너에게 전달하고\n연결되기를 기다리고 있어요 😊',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFFF6B8A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '실시간 확인 중',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Enhanced invite code display
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                  const Color(0xFFFFB6C1).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.key,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '내 초대 코드',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    _connection.inviteCode ?? '',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: Color(0xFFFF6B8A),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6B8A),
                        Color(0xFFFFB6C1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _copyInviteCode,
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text(
                      '코드 복사하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Enhanced timer display
          if (_timeRemaining.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: Color(0xFFFF6B8A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '남은 시간',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _timeRemaining,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B8A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Enhanced cancel button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: OutlinedButton.icon(
              onPressed: _cancelInvite,
              icon: const Icon(Icons.cancel_outlined, size: 20),
              label: const Text(
                '초대 취소',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B8A),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build view when connected
  Widget _buildConnectedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Success celebration section
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                  const Color(0xFFFFB6C1).withValues(alpha: 0.05),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Success animation container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6B8A),
                        Color(0xFFFFB6C1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '연결 성공! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '파트너와 성공적으로 연결되었어요!\n이제 함께 소중한 순간들을 기록해보세요 💕',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Enhanced partner info card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Partner avatar with enhanced design
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFB6C1),
                        Color(0xFFFF91A4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(45),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB6C1).withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _connection.partnerName ?? '파트너',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '@${_connection.partnerNickname ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_connection.connectedAt != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '연결일: ${_formatDate(_connection.connectedAt!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Enhanced action buttons
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B8A),
                  Color(0xFFFFB6C1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to anniversary setup after couple connection
                Navigator.of(context).pushReplacementNamed('/anniversary-setup');
              },
              icon: const Icon(Icons.favorite, color: Colors.white),
              label: const Text(
                '만난 날 설정하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off, size: 20),
              label: const Text(
                '연결 해제',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B8A),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build view when connection failed
  Widget _buildConnectionFailedView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced error state
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '연결에 실패했어요',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '잘못된 초대 코드이거나 네트워크 문제일 수 있어요.\n다시 한 번 시도해주세요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B8A),
                  Color(0xFFFFB6C1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _loadConnectionStatus,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                '다시 시도하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}