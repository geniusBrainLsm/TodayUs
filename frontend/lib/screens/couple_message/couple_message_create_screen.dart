import 'package:flutter/material.dart';
import '../../services/couple_message_service.dart';

class CoupleMessageCreateScreen extends StatefulWidget {
  const CoupleMessageCreateScreen({super.key});

  @override
  State<CoupleMessageCreateScreen> createState() => _CoupleMessageCreateScreenState();
}

class _CoupleMessageCreateScreenState extends State<CoupleMessageCreateScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _weeklyUsage;

  @override
  void initState() {
    super.initState();
    _loadWeeklyUsage();
  }

  Future<void> _loadWeeklyUsage() async {
    try {
      final usage = await CoupleMessageService.getWeeklyUsage();
      if (mounted) {
        setState(() {
          _weeklyUsage = usage;
        });
      }
    } catch (e) {
      print('Error loading weekly usage: $e');
    }
  }

  String _getNextAvailableMessage() {
    if (_weeklyUsage == null) return '';

    if (_weeklyUsage!['canSend'] == true) {
      return '';
    }

    final nextAvailableAt = _weeklyUsage!['nextAvailableAt'];
    if (nextAvailableAt != null) {
      try {
        final dateTime = DateTime.parse(nextAvailableAt);
        final now = DateTime.now();
        final difference = dateTime.difference(now);

        if (difference.inDays > 0) {
          return '${difference.inDays}일 ${difference.inHours % 24}시간 후 사용 가능';
        } else if (difference.inHours > 0) {
          return '${difference.inHours}시간 ${difference.inMinutes % 60}분 후 사용 가능';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes}분 후 사용 가능';
        }
      } catch (e) {
        return '잠시 후 사용 가능';
      }
    }

    return '3일에 한 번만 사용 가능';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('전달할 내용을 입력해주세요.', isError: true);
      return;
    }

    if (_weeklyUsage != null && !(_weeklyUsage!['canSend'] ?? false)) {
      _showSnackBar(_getNextAvailableMessage(), isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await CoupleMessageService.createMessage(_messageController.text.trim());

      if (mounted) {
        _showSnackBar('메시지가 AI로 처리되어 상대방에게 전달됩니다! 💕');
        _messageController.clear();
        _loadWeeklyUsage(); // 사용량 업데이트
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('메시지 전송에 실패했습니다: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
          ? const Color(0xFFFF6B8A).withValues(alpha: 0.8)
          : Colors.green[400],
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _weeklyUsage?['canSend'] ?? true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '마음 전하기',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFFF6B8A),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 간단한 안내
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_fix_high,
                    color: Color(0xFFFF6B8A),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI가 따뜻하게 순화해서 전달해드려요\n3일에 한 번 사용할 수 있어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 사용량 표시 (간단히)
            if (_weeklyUsage != null && !canSend) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getNextAvailableMessage(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 메시지 입력
            const Text(
              '전달하고 싶은 마음을 적어주세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  expands: true,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: '예: 요즘 연락이 뜸해서 서운해... 바쁜 건 알지만 가끔 안부라도 물어봐줬으면 좋겠어',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 전송 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || !canSend) ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSend ? const Color(0xFFFF6B8A) : Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        canSend ? 'AI가 따뜻하게 전달하기' : '사용 불가',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: canSend ? Colors.white : Colors.grey[600],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // 히스토리 버튼
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/couple-message-history');
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '전달 내역 보기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF6B8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}