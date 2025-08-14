import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/anniversary_service.dart';

class AnniversarySetupScreen extends StatefulWidget {
  const AnniversarySetupScreen({super.key});

  @override
  State<AnniversarySetupScreen> createState() => _AnniversarySetupScreenState();
}

class _AnniversarySetupScreenState extends State<AnniversarySetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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

    _checkExistingAnniversary();
    _startAnimations();
  }

  Future<void> _checkExistingAnniversary() async {
    try {
      final currentAnniversaryData = await AnniversaryService.getAnniversary();
      if (currentAnniversaryData != null && currentAnniversaryData['anniversaryDate'] != null) {
        // 기념일이 이미 설정되어 있으면 바로 홈화면으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }
    } catch (error) {
      debugPrint('Check existing anniversary error: $error');
      // 에러가 발생해도 계속 진행
    }
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

    // Validate anniversary date
    final validation = AnniversaryService.validateAnniversaryDate(_selectedDate);
    if (!validation['isValid']) {
      _showErrorSnackBar(validation['error']);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if anniversary is already set by checking current state
      final currentAnniversaryData = await AnniversaryService.getAnniversary();
      if (currentAnniversaryData != null && currentAnniversaryData['anniversaryDate'] != null) {
        final setterName = currentAnniversaryData['setterName'] as String? ?? '상대방';
        _showErrorSnackBar('기념일이 이미 $setterName님에 의해 설정되어 있습니다.');
        // 기념일이 이미 설정된 경우 홈화면으로 이동
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }
      
      // Save anniversary date to storage
      final success = await AnniversaryService.saveAnniversary(_selectedDate);
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        _showErrorSnackBar('기념일 저장에 실패했습니다.');
      }
    } catch (error) {
      debugPrint('Anniversary save error: $error');
      if (error.toString().contains('이미 설정')) {
        _showErrorSnackBar('기념일이 이미 설정되어 있습니다. 한 커플당 한 명만 기념일을 설정할 수 있습니다.');
        // 기념일이 이미 설정된 경우 홈화면으로 이동
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        _showErrorSnackBar('기념일 저장에 실패했습니다.');
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
                        // Header section
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/images/finger_robot.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.favorite,
                                      size: 40,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            Text(
                              '만난 날을 설정해주세요',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Text(
                              '두 분이 처음 만난 특별한 날을 기록해보세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.3,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Date selector section
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
                                      style: TextStyle(
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
                              
                              // Simple date selection
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showDatePickerDialog,
                                  icon: const Icon(Icons.calendar_month, size: 20),
                                  label: const Text(
                                    '달력에서 날짜 선택하기',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Continue button
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
                            onPressed: _isLoading ? null : _saveAnniversary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF667eea),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF667eea),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    '계속하기',
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


  // Show native date picker dialog
  Future<void> _showDatePickerDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade400,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // 햅틱 피드백 추가
      HapticFeedback.selectionClick();
    }
  }

}