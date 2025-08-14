import 'package:flutter/material.dart';
import '../services/diary_service.dart';

class WeeklyEmotionSummaryScreen extends StatefulWidget {
  const WeeklyEmotionSummaryScreen({super.key});

  @override
  State<WeeklyEmotionSummaryScreen> createState() => _WeeklyEmotionSummaryScreenState();
}

class _WeeklyEmotionSummaryScreenState extends State<WeeklyEmotionSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final DiaryService _diaryService = DiaryService();
  String _weeklyEmotionSummary = '로딩 중...';
  bool _isLoading = true;

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

    _loadWeeklyEmotionSummary();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyEmotionSummary() async {
    try {
      final summary = await _diaryService.getWeeklyEmotionSummary();
      
      if (mounted) {
        setState(() {
          _weeklyEmotionSummary = summary;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    } catch (e) {
      print('Error loading weekly emotion summary: $e');
      if (mounted) {
        setState(() {
          _weeklyEmotionSummary = '이번 주의 감정들을 정리하고 있어요.\n소중한 마음들이 담긴 한 주였네요 💝';
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '주간 감정 요약',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadWeeklyEmotionSummary,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Main Summary Card
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(32),
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
                                        // Robot Icon
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(50),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Image.asset(
                                              'assets/images/finger_robot.png',
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Title
                                        const Text(
                                          '이번 주 감정 분석',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Summary Text
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            _weeklyEmotionSummary,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white.withValues(alpha: 0.9),
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Info Card
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.white.withValues(alpha: 0.8),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              '주간 감정 요약이란?',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        Text(
                                          'AI가 지난 7일간의 일기를 분석하여 감정의 흐름과 변화를 요약해드립니다. 긍정적인 변화나 성장 포인트를 찾아 따뜻한 격려 메시지로 전달해요.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.8),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}