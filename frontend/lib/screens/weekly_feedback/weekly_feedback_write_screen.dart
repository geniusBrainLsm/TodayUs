import 'package:flutter/material.dart';
import '../../services/weekly_feedback_service.dart';

class WeeklyFeedbackWriteScreen extends StatefulWidget {
  const WeeklyFeedbackWriteScreen({super.key});

  @override
  State<WeeklyFeedbackWriteScreen> createState() => _WeeklyFeedbackWriteScreenState();
}

class _WeeklyFeedbackWriteScreenState extends State<WeeklyFeedbackWriteScreen> {
  final TextEditingController _messageController = TextEditingController();
  final WeeklyFeedbackService _feedbackService = WeeklyFeedbackService();
  
  bool _isLoading = false;
  bool _canWrite = false;
  String _availabilityMessage = '';
  String? _nextAvailableTime;
  
  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      final availability = await _feedbackService.checkAvailability();
      
      setState(() {
        _canWrite = availability['canWrite'] as bool? ?? false;
        _availabilityMessage = _feedbackService.getAvailabilityMessage(availability);
        _nextAvailableTime = _feedbackService.getNextAvailableTimeString(availability);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('상태를 확인할 수 없습니다');
    }
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();
    
    if (message.isEmpty) {
      _showErrorSnackBar('서운했던 점을 입력해주세요');
      return;
    }
    
    if (message.length < 10) {
      _showErrorSnackBar('10자 이상 입력해주세요');
      return;
    }
    
    if (message.length > 1000) {
      _showErrorSnackBar('1000자 이하로 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _feedbackService.createFeedback(message);
      
      if (result != null) {
        _showSuccessSnackBar('피드백이 전송되었습니다. AI가 순화하여 전달할 예정입니다.');
        Navigator.of(context).pop(true); // 성공 표시와 함께 돌아가기
      } else {
        _showErrorSnackBar('피드백 전송에 실패했습니다');
      }
    } catch (e) {
      _showErrorSnackBar('오류가 발생했습니다');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
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
        title: const Text('서운함 전달하기'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '서운함 전달하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '이번 주에 서운했던 점을 작성하시면\nAI가 부드럽게 순화하여 파트너에게 전달해드려요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 작성 가능 여부 표시
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _canWrite ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _canWrite ? Colors.green.shade200 : Colors.orange.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _canWrite ? Icons.edit : Icons.schedule,
                          color: _canWrite ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _availabilityMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _canWrite ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                        if (_nextAvailableTime != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '다음 작성 가능: $_nextAvailableTime',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 메시지 입력 필드
                  if (_canWrite) ...[
                    const Text(
                      '이번 주에 서운했던 점을 솔직하게 작성해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      maxLines: 8,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: '예시: 이번 주에 연락이 뜸해서 외로웠어요. 더 자주 연락하며 지냈으면 좋겠어요.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        counterText: '${_messageController.text.length}/1000',
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 주의사항
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI가 부드럽고 건설적인 표현으로 순화하여 전달합니다. 솔직한 마음을 편하게 작성해주세요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 전송 버튼
                    ElevatedButton(
                      onPressed: _messageController.text.trim().length >= 10
                          ? _submitFeedback
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'AI에게 전달 요청하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  
                  // 작성 불가능한 경우의 안내
                  if (!_canWrite) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.grey.shade600,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '작성 가능 시간',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '매주 토요일 오전 7시 ~ 오후 11시 59분',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}