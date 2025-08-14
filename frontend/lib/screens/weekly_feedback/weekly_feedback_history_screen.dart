import 'package:flutter/material.dart';
import '../../services/weekly_feedback_service.dart';

class WeeklyFeedbackHistoryScreen extends StatefulWidget {
  const WeeklyFeedbackHistoryScreen({super.key});

  @override
  State<WeeklyFeedbackHistoryScreen> createState() => _WeeklyFeedbackHistoryScreenState();
}

class _WeeklyFeedbackHistoryScreenState extends State<WeeklyFeedbackHistoryScreen> {
  final WeeklyFeedbackService _feedbackService = WeeklyFeedbackService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreFeedbacks();
      }
    }
  }

  Future<void> _loadFeedbacks() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _feedbacks.clear();
      _hasMore = true;
    });

    try {
      final result = await _feedbackService.getFeedbackHistory(page: 0, size: _pageSize);
      final content = List<Map<String, dynamic>>.from(result['content'] ?? []);
      final totalPages = result['totalPages'] as int? ?? 0;

      setState(() {
        _feedbacks = content;
        _hasMore = _currentPage + 1 < totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('피드백을 불러올 수 없습니다');
    }
  }

  Future<void> _loadMoreFeedbacks() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await _feedbackService.getFeedbackHistory(page: nextPage, size: _pageSize);
      final content = List<Map<String, dynamic>>.from(result['content'] ?? []);
      final totalPages = result['totalPages'] as int? ?? 0;

      setState(() {
        _feedbacks.addAll(content);
        _currentPage = nextPage;
        _hasMore = nextPage + 1 < totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('더 많은 피드백을 불러올 수 없습니다');
    }
  }

  Future<void> _viewFeedbackDetail(Map<String, dynamic> feedback) async {
    final feedbackId = feedback['id'] as int?;
    if (feedbackId == null) return;

    try {
      final detailFeedback = await _feedbackService.getFeedback(feedbackId);
      if (detailFeedback != null && mounted) {
        _showFeedbackDialog(detailFeedback);
      }
    } catch (e) {
      _showErrorSnackBar('피드백 상세 정보를 불러올 수 없습니다');
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> feedback) {
    final senderName = feedback['senderName'] as String? ?? '파트너';
    final receiverName = feedback['receiverName'] as String? ?? '나';
    final refinedMessage = feedback['refinedMessage'] as String? ?? '';
    final weekLabel = _generateWeekLabel(feedback['weekOf'] as String?);
    final isReceived = feedback['receiverName'] != null; // 임시로 수신 여부 판단
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              isReceived ? Icons.favorite : Icons.send,
              color: isReceived ? Colors.red.shade400 : Colors.blue.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isReceived ? '$senderName님의 마음' : '$receiverName님에게 보낸 마음',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isReceived ? Colors.pink.shade800 : Colors.blue.shade800,
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
                    color: isReceived ? Colors.pink.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isReceived ? Colors.pink.shade200 : Colors.blue.shade200,
                    ),
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'AI가 부드럽게 순화한 메시지입니다',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
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
        ],
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
      return '$month월 ${weekOfMonth}주차';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('피드백 히스토리'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeedbacks,
        child: _feedbacks.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _feedbacks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _feedbacks.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _feedbacks.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final feedback = _feedbacks[index];
                      return _buildFeedbackCard(feedback);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 주고받은 피드백이 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '매주 토요일에 서운했던 점을\n따뜻하게 전달해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final partnerName = feedback['partnerName'] as String? ?? '파트너';
    final weekLabel = feedback['weekLabel'] as String? ?? _generateWeekLabel(feedback['weekOf'] as String?);
    final refinedMessage = feedback['refinedMessage'] as String? ?? '';
    final isRead = feedback['isRead'] as bool? ?? true;
    final status = feedback['status'] as String? ?? '';
    
    // 받은 피드백인지 보낸 피드백인지 구분 (임시로 status로 구분)
    final isReceived = status == 'DELIVERED' || status == 'READ';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewFeedbackDetail(feedback),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isReceived ? Colors.pink.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isReceived ? Icons.favorite : Icons.send,
                      color: isReceived ? Colors.pink.shade600 : Colors.blue.shade600,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReceived ? '$partnerName님으로부터' : '$partnerName님에게',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isReceived ? Colors.pink.shade800 : Colors.blue.shade800,
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
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              
              if (refinedMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    refinedMessage.length > 100 
                        ? '${refinedMessage.substring(0, 100)}...'
                        : refinedMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI 순화됨',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '터치하여 자세히 보기',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}