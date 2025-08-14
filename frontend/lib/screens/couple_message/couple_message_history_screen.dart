import 'package:flutter/material.dart';
import '../../services/couple_message_service.dart';

class CoupleMessageHistoryScreen extends StatefulWidget {
  const CoupleMessageHistoryScreen({super.key});

  @override
  State<CoupleMessageHistoryScreen> createState() => _CoupleMessageHistoryScreenState();
}

class _CoupleMessageHistoryScreenState extends State<CoupleMessageHistoryScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessageHistory();
  }

  Future<void> _loadMessageHistory() async {
    try {
      final messages = await CoupleMessageService.getMessageHistory();
      if (mounted) {
        setState(() {
          _messages = messages ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading message history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadMessageHistory();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'AI 처리 중';
      case 'READY':
        return '전달 대기';
      case 'DELIVERED':
        return '전달 완료';
      case 'READ':
        return '읽음';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'READY':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'READ':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '전달 내역',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple[400],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.purple[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageCard(message);
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
            Icons.message_outlined,
            size: 64,
            color: Colors.purple[300],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 전달한 메시지가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '서운한 마음이 있을 때\n대신 전달하기를 사용해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/couple-message-create');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '대신 전달하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final status = message['status'] ?? '';
    final isFromMe = message['isFromCurrentUser'] ?? false;
    final senderNickname = message['senderNickname'] ?? '알 수 없음';
    final receiverNickname = message['receiverNickname'] ?? '알 수 없음';
    final originalMessage = message['originalMessage'] ?? '';
    final aiProcessedMessage = message['aiProcessedMessage'] ?? '';
    final createdAt = message['createdAt'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 - 송수신자 및 상태
            Row(
              children: [
                Icon(
                  isFromMe ? Icons.send : Icons.inbox,
                  color: isFromMe ? Colors.blue[400] : Colors.green[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFromMe 
                        ? '$receiverNickname님에게 전달'
                        : '$senderNickname님으로부터',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 시간
            if (createdAt != null)
              Text(
                _formatDateTime(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // 원본 메시지 (보낸 메시지인 경우)
            if (isFromMe && originalMessage.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '원본 메시지',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      originalMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // AI 처리된 메시지
            if (aiProcessedMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Colors.purple[600]),
                        const SizedBox(width: 4),
                        Text(
                          'AI가 순화한 메시지',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aiProcessedMessage,
                      style: const TextStyle(
                        fontSize: 14,
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
  }
}