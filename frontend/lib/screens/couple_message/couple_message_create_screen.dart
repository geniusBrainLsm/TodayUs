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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('전달할 내용을 입력해주세요.', isError: true);
      return;
    }

    if (_weeklyUsage != null && !(_weeklyUsage!['canSend'] ?? false)) {
      _showSnackBar('오늘 사용 횟수를 모두 사용했습니다.', isError: true);
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
          child: Column(
            children: [
              // 커스텀 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFFFF6B8A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '대신 전해주기',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            'AI가 따뜻하게 전달해드려요',
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
                ),
              ),
              // 컨텐츠 영역
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // 향상된 안내 카드
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B8A),
                                        Color(0xFFFFB6C1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '대신 전해주기란?',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      Text(
                                        'AI가 따뜻하게 도와드려요',
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
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F5),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '서운하거나 속상했던 마음을 직접 말하기 어려울 때,\nAI가 따뜻하고 부드럽게 순화해서 상대방에게 전달해드려요.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF6B8A).withValues(alpha: 0.15),
                                    const Color(0xFFFFB6C1).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Color(0xFFFF6B8A),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '하루에 1번만 사용할 수 있어요 (테스트용)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 향상된 사용량 표시
                      if (_weeklyUsage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _weeklyUsage!['canSend'] 
                                  ? const Color(0xFFE8F5E8)
                                  : const Color(0xFFFFECEC),
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _weeklyUsage!['canSend'] 
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _weeklyUsage!['canSend'] 
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _weeklyUsage!['canSend'] ? Icons.check_circle : Icons.block,
                                  color: _weeklyUsage!['canSend'] ? Colors.green[600] : Colors.red[600],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '오늘 사용량 (테스트용)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${_weeklyUsage!['usedCount']}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: _weeklyUsage!['canSend'] ? Colors.green[600] : Colors.red[600],
                                          ),
                                        ),
                                        Text(
                                          ' / ${_weeklyUsage!['maxCount']}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!_weeklyUsage!['canSend'])
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    '사용 완료',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // 향상된 메시지 입력 영역
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Color(0xFFFF6B8A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  '전달하고 싶은 마음을 솔직하게 적어주세요',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
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
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: TextField(
                                controller: _messageController,
                                maxLines: 8,
                                maxLength: 1000,
                                decoration: InputDecoration(
                                  hintText: '예: 요즘 연락이 뜸해서 서운해... 바쁜 건 알지만 가끔 안부라도 물어봐줬으면 좋겠어',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                  border: InputBorder.none,
                                  counterText: '',
                                ),
                                style: const TextStyle(
                                  fontSize: 16, 
                                  height: 1.6,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // 향상된 전송 버튼
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B8A),
                              Color(0xFFFFB6C1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || 
                                      (_weeklyUsage != null && !_weeklyUsage!['canSend']))
                                ? null 
                                : _sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.auto_fix_high,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'AI가 따뜻하게 전달하기',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 향상된 히스토리 버튼
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/couple-message-history');
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history, 
                                  color: const Color(0xFFFF6B8A), 
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '전달 내역 보기',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFFFF6B8A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
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