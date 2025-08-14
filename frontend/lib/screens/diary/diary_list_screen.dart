import 'package:flutter/material.dart';
import '../../services/diary_service.dart';
import 'diary_detail_screen.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  final DiaryService _diaryService = DiaryService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _diaries = [];
  List<Map<String, dynamic>> _emotionStats = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoadingEmotionStats = false;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
    _loadEmotionStats();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMoreDiaries();
      }
    }
  }

  Future<void> _loadDiaries() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final diaries = await _diaryService.getDiaries(page: 0, size: _pageSize);
      
      setState(() {
        _diaries = diaries;
        _currentPage = 0;
        _hasMore = diaries.length == _pageSize;
        _isLoading = false;
      });
    } catch (error) {
      print('Load diaries error: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('일기 목록을 불러오는데 실패했습니다.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreDiaries() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newDiaries = await _diaryService.getDiaries(page: nextPage, size: _pageSize);
      
      setState(() {
        _diaries.addAll(newDiaries);
        _currentPage = nextPage;
        _hasMore = newDiaries.length == _pageSize;
        _isLoading = false;
      });
    } catch (error) {
      print('Load more diaries error: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDiaries() async {
    await _loadDiaries();
    await _loadEmotionStats();
  }

  Future<void> _loadEmotionStats() async {
    setState(() {
      _isLoadingEmotionStats = true;
    });

    try {
      // Load emotion stats for current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      
      final emotionStats = await _diaryService.getEmotionStats(
        startDate: startDate,
        endDate: endDate,
      );
      
      setState(() {
        _emotionStats = emotionStats;
        _isLoadingEmotionStats = false;
      });
    } catch (error) {
      print('Load emotion stats error: $error');
      setState(() {
        _isLoadingEmotionStats = false;
      });
    }
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

  String _formatDate(String dateStr) {
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
        final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월',
                           '7월', '8월', '9월', '10월', '11월', '12월'];
        return '${date.month}월 ${date.day}일';
      }
    } catch (e) {
      return dateStr;
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
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF4A90E2),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '우리의 일기장',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '소중한 추억을 기록해보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshDiaries,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Emotion Summary Card
              if (!_isLoadingEmotionStats && _emotionStats.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                          const Text(
                            '이번 달 감정 요약',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Emotion bars
                      Column(
                        children: _emotionStats.take(5).map((stat) {
                          final emotion = stat['emotion'] as String;
                          final count = stat['count'] as int;
                          final percentage = stat['percentage'] as double;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                // Emoji
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getEmotionEmoji(emotion),
                                      style: const TextStyle(fontSize: 16),
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
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '$count회',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
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
                ),
              
              // Content
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Empty State
                    if (_diaries.isEmpty && !_isLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
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
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    size: 40,
                                    color: Color(0xFF4A90E2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  '아직 작성된 일기가 없어요',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '오른쪽 하단의 + 버튼을 눌러\n첫 번째 일기를 작성해보세요!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _diaries.length) {
                                return _hasMore && _isLoading
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF4A90E2),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }
                              
                              final diary = _diaries[index];
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
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
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
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail Image (if exists)
                                      if (diary['imageUrl'] != null && diary['imageUrl'].toString().isNotEmpty)
                                        Container(
                                          width: 80,
                                          height: 80,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              'http://localhost:8080${diary['imageUrl']}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey.shade400,
                                                    size: 24,
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  color: Colors.grey.shade100,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header
                                            Row(
                                              children: [
                                                // Mood Emoji
                                                if (diary['moodEmoji'] != null && diary['moodEmoji'].toString().isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      diary['moodEmoji'],
                                                      style: const TextStyle(fontSize: 20),
                                                    ),
                                                  ),
                                                const SizedBox(width: 12),
                                                
                                                // Author and Date
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        author['nickname'] ?? '익명',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatDate(diary['diaryDate']),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                // AI Processing Status
                                                if (diary['aiProcessed'] == true)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade100,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.auto_awesome,
                                                          size: 12,
                                                          color: Colors.green.shade700,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'AI 분석',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.green.shade700,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 12),
                                            
                                            // Title
                                            Text(
                                              diary['title'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            
                                            const SizedBox(height: 8),
                                            
                                            // Comment Count
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.chat_bubble_outline,
                                                  size: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '댓글 ${diary['commentCount'] ?? 0}개',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _diaries.length + (_hasMore && _isLoading ? 1 : 0),
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
    );
  }
}