import 'package:flutter/material.dart';
import '../../services/time_capsule_service.dart';
import 'time_capsule_create_screen.dart';
import 'time_capsule_detail_screen.dart';

class TimeCapsuleListScreen extends StatefulWidget {
  const TimeCapsuleListScreen({super.key});

  @override
  State<TimeCapsuleListScreen> createState() => _TimeCapsuleListScreenState();
}

class _TimeCapsuleListScreenState extends State<TimeCapsuleListScreen> {
  final TimeCapsuleService _timeCapsuleService = TimeCapsuleService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _timeCapsules = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadTimeCapsules();
    _loadSummary();
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
        _loadMoreTimeCapsules();
      }
    }
  }

  Future<void> _loadTimeCapsules() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _timeCapsuleService.getTimeCapsulesPaginated(page: 0, size: _pageSize);
      final content = response['content'] as List<dynamic>;
      
      setState(() {
        _timeCapsules = content.cast<Map<String, dynamic>>();
        _currentPage = 0;
        _hasMore = !(response['last'] as bool? ?? true);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load time capsules error: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('타임캡슐 목록을 불러오는데 실패했습니다.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreTimeCapsules() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _timeCapsuleService.getTimeCapsulesPaginated(page: nextPage, size: _pageSize);
      final content = response['content'] as List<dynamic>;
      
      setState(() {
        _timeCapsules.addAll(content.cast<Map<String, dynamic>>());
        _currentPage = nextPage;
        _hasMore = !(response['last'] as bool? ?? true);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load more time capsules error: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _timeCapsuleService.getTimeCapsuleSummary();
      setState(() {
        _summary = summary;
      });
    } catch (error) {
      debugPrint('Load summary error: $error');
    }
  }

  Future<void> _refreshTimeCapsules() async {
    await _loadTimeCapsules();
    await _loadSummary();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      
      if (targetDate == today) {
        return '오늘';
      } else if (targetDate.isBefore(today)) {
        final diff = today.difference(targetDate).inDays;
        return '$diff일 전';
      } else {
        final diff = targetDate.difference(today).inDays;
        return '$diff일 후';
      }
    } catch (e) {
      return dateStr;
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
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: _refreshTimeCapsules,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                  ),
                ],
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text(
                    '타임캡슐',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: false,
                ),
              ),
              
              // Summary Card
              if (_summary != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${_summary!['totalCount']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  '전체',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${_summary!['openableCount']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow,
                                  ),
                                ),
                                const Text(
                                  '열 수 있음',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${_summary!['openedCount']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Text(
                                  '열림',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Content
              if (_timeCapsules.isEmpty && !_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '아직 생성된 타임캡슐이 없어요',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '미래의 자신이나 연인에게\n특별한 메시지를 남겨보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _timeCapsules.length) {
                          return _hasMore && _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        
                        final timeCapsule = _timeCapsules[index];
                        final author = timeCapsule['author'] as Map<String, dynamic>;
                        final isOpened = timeCapsule['isOpened'] as bool;
                        final canOpen = timeCapsule['canOpen'] as bool;
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TimeCapsuleDetailScreen(
                                  timeCapsuleId: timeCapsule['id'],
                                ),
                              ),
                            ).then((_) => _refreshTimeCapsules());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: canOpen && !isOpened 
                                  ? Border.all(color: Colors.yellow, width: 2)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Icon(
                                      isOpened 
                                          ? Icons.lock_open 
                                          : canOpen 
                                              ? Icons.vpn_key 
                                              : Icons.lock,
                                      color: isOpened 
                                          ? Colors.green 
                                          : canOpen 
                                              ? Colors.orange 
                                              : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      author['nickname'] ?? '익명',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOpened 
                                            ? Colors.green.shade100 
                                            : canOpen 
                                                ? Colors.orange.shade100 
                                                : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isOpened 
                                            ? '열림' 
                                            : canOpen 
                                                ? '열 수 있음' 
                                                : '대기 중',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isOpened 
                                              ? Colors.green.shade700 
                                              : canOpen 
                                                  ? Colors.orange.shade700 
                                                  : Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Title
                                Text(
                                  timeCapsule['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Date Info
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '오픈 예정: ${_formatDate(timeCapsule['openDate'])}',
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
                        );
                      },
                      childCount: _timeCapsules.length + (_hasMore && _isLoading ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TimeCapsuleCreateScreen(),
            ),
          ).then((_) => _refreshTimeCapsules());
        },
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.add,
          color: Color(0xFF667eea),
        ),
      ),
    );
  }
}