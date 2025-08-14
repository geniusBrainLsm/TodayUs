import 'package:flutter/material.dart';
import 'services/nickname_service.dart';
import 'services/auth_service.dart';

class NicknameInputScreen extends StatefulWidget {
  const NicknameInputScreen({super.key});

  @override
  State<NicknameInputScreen> createState() => _NicknameInputScreenState();
}

class _NicknameInputScreenState extends State<NicknameInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isNicknameValid = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    
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

    _nicknameController.addListener(_validateNickname);
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
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  void _validateNickname() {
    final nickname = _nicknameController.text;
    final validation = NicknameService.validateNickname(nickname);
    
    setState(() {
      if (nickname.trim().isEmpty) {
        _isNicknameValid = false;
        _errorMessage = '';
      } else {
        _isNicknameValid = validation['isValid'];
        _errorMessage = validation['error'];
      }
    });
  }

  Future<void> _saveNickname() async {
    if (!_isNicknameValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nickname = _nicknameController.text.trim();
      
      // Save nickname using service
      final success = await NicknameService.saveNickname(nickname);
      
      if (success) {
        if (mounted) {
          // Get the next route based on updated onboarding status
          final nextRoute = await AuthService.getNextRoute();
          Navigator.of(context).pushReplacementNamed(nextRoute);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('닉네임 저장에 실패했습니다. 다시 시도해 주세요.');
        }
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('닉네임 저장에 실패했습니다. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
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
                        // Welcome section
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha:0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/images/question_robot.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person_add,
                                      size: 40,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            Text(
                              '환영합니다!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha:0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Text(
                              'TodayUs에서 사용할\n닉네임을 입력해 주세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha:0.9),
                                letterSpacing: 0.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Nickname input section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '닉네임',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha:0.9),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _errorMessage.isNotEmpty 
                                    ? Colors.red.withValues(alpha:0.5)
                                    : Colors.white.withValues(alpha:0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _nicknameController,
                                focusNode: _nicknameFocusNode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: '예: 홍길동, User123, 😀커플',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha:0.6),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                  suffixIcon: _nicknameController.text.isNotEmpty
                                    ? Icon(
                                        _isNicknameValid 
                                          ? Icons.check_circle
                                          : Icons.error,
                                        color: _isNicknameValid 
                                          ? Colors.green.shade300
                                          : Colors.red.shade300,
                                      )
                                    : null,
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _saveNickname(),
                              ),
                            ),
                            
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade300,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              '• 2-10글자 이내 (한글, 영어, 숫자, 이모지, 특수문자 사용 가능)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha:0.7),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Continue button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isNicknameValid && !_isLoading 
                              ? _saveNickname 
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isNicknameValid 
                                ? Colors.white 
                                : Colors.white.withValues(alpha:0.3),
                              foregroundColor: _isNicknameValid 
                                ? const Color(0xFF667eea) 
                                : Colors.white.withValues(alpha:0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              disabledBackgroundColor: Colors.white.withValues(alpha:0.3),
                            ),
                            child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'TodayUs 시작하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Skip option
                        TextButton(
                          onPressed: () async {
                            await NicknameService.saveNickname('사용자');
                            
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/home');
                            }
                          },
                          child: Text(
                            '나중에 설정하기',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha:0.8),
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha:0.8),
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
}