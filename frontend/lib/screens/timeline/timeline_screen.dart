import 'package:flutter/material.dart';
import '../../services/diary_service.dart';

enum ViewMode { monthly, weekly }

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final DiaryService _diaryService = DiaryService();
  ViewMode _currentViewMode = ViewMode.monthly;
  DateTime _currentDate = DateTime.now();
  
  List<Map<String, dynamic>> _emotionStats = [];
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

    _loadTimelineData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTimelineData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime startDate, endDate;
      
      if (_currentViewMode == ViewMode.monthly) {
        startDate = DateTime(_currentDate.year, _currentDate.month, 1);
        endDate = DateTime(_currentDate.year, _currentDate.month + 1, 0);
      } else {
        // Weekly view - get current week
        final weekday = _currentDate.weekday;
        startDate = _currentDate.subtract(Duration(days: weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
      }

      print('🟡 Timeline loading data for period: ${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}');
      print('🟡 View mode: $_currentViewMode');

      // Load emotion stats for the period
      print('🟡 Loading emotion stats...');
      final emotionStats = await _diaryService.getEmotionStats(
        startDate: startDate,
        endDate: endDate,
      );
      print('🟢 Emotion stats loaded: ${emotionStats.length} items');

      if (mounted) {
        setState(() {
          _emotionStats = emotionStats;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    } catch (error) {
      print('🔴 Load timeline data error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleViewMode() {
    setState(() {
      _currentViewMode = _currentViewMode == ViewMode.monthly 
          ? ViewMode.weekly 
          : ViewMode.monthly;
    });
    _loadTimelineData();
  }

  void _navigateDate(int direction) {
    setState(() {
      if (_currentViewMode == ViewMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + direction, 1);
      } else {
        _currentDate = _currentDate.add(Duration(days: 7 * direction));
      }
    });
    _loadTimelineData();
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

  String _formatTimelinePeriod() {
    if (_currentViewMode == ViewMode.monthly) {
      return '${_currentDate.year}년 ${_currentDate.month}월';
    } else {
      final weekday = _currentDate.weekday;
      final startOfWeek = _currentDate.subtract(Duration(days: weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      if (startOfWeek.month == endOfWeek.month) {
        return '${startOfWeek.month}월 ${startOfWeek.day}일 - ${endOfWeek.day}일';
      } else {
        return '${startOfWeek.month}월 ${startOfWeek.day}일 - ${endOfWeek.month}월 ${endOfWeek.day}일';
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              // Header Card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.timeline_rounded,
                            color: Color(0xFF4A90E2),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '감정 타임라인',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '두 사람의 감정 동향을 확인해보세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: _toggleViewMode,
                            child: Text(
                              _currentViewMode == ViewMode.monthly ? '월별' : '주별',
                              style: const TextStyle(
                                color: Color(0xFF4A90E2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Date Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _navigateDate(-1),
                          icon: Icon(
                            Icons.chevron_left,
                            color: Colors.grey.shade600,
                            size: 28,
                          ),
                        ),
                        Text(
                          _formatTimelinePeriod(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _navigateDate(1),
                          icon: Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade600,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4A90E2),
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: CustomScrollView(
                              slivers: [
                                // Emotion Statistics
                                SliverToBoxAdapter(
                                  child: _emotionStats.isNotEmpty 
                                      ? _buildEmotionChart()
                                      : _buildEmptyEmotionStats(),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 20),
                                ),
                                
                                
                                // bottom padding
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 100),
                                ),
                              ],
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

  Widget _buildEmotionChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_currentViewMode == ViewMode.monthly ? '이번 달' : '이번 주'} 감정 분석',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Emotion bars
          Column(
            children: _emotionStats.map((stat) {
              final emotion = stat['emotion'] as String;
              final count = stat['count'] as int;
              final percentage = stat['percentage'] as double;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Emoji
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _getEmotionEmoji(emotion),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Label and bar
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
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '$count회 (${percentage.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF4A90E2),
                            ),
                          ),
                        ],
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


  Widget _buildEmptyEmotionStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_currentViewMode == ViewMode.monthly ? '이번 달' : '이번 주'} 감정 분석',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'AI 감정 분석 대기 중',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '일기가 AI 분석을 완료하면 감정 통계가 표시됩니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}