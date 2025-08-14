import 'package:flutter/material.dart';
import '../../services/time_capsule_service.dart';

class TimeCapsuleDetailScreen extends StatefulWidget {
  final int timeCapsuleId;

  const TimeCapsuleDetailScreen({
    super.key,
    required this.timeCapsuleId,
  });

  @override
  State<TimeCapsuleDetailScreen> createState() => _TimeCapsuleDetailScreenState();
}

class _TimeCapsuleDetailScreenState extends State<TimeCapsuleDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TimeCapsuleService _timeCapsuleService = TimeCapsuleService();
  Map<String, dynamic>? _timeCapsule;
  bool _isLoading = true;
  bool _isOpening = false;

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

    _loadTimeCapsule();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeCapsule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final timeCapsule = await _timeCapsuleService.getTimeCapsule(widget.timeCapsuleId);
      
      if (mounted) {
        setState(() {
          _timeCapsule = timeCapsule;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().contains('권한이 없습니다')
                ? '타임캡슐에 접근할 권한이 없습니다.'
                : '타임캡슐을 불러오는데 실패했습니다.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _openTimeCapsule() async {
    if (_timeCapsule == null) return;
    
    setState(() {
      _isOpening = true;
    });

    try {
      final updatedTimeCapsule = await _timeCapsuleService.openTimeCapsule(widget.timeCapsuleId);
      
      if (mounted) {
        setState(() {
          _timeCapsule = updatedTimeCapsule;
          _isOpening = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('타임캡슐이 열렸습니다! 🎉'),
            backgroundColor: Colors.green.shade400,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().contains('열 수 없습니다')
                ? '아직 열 수 없는 타임캡슐입니다.'
                : '타임캡슐 열기에 실패했습니다.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월',
                         '7월', '8월', '9월', '10월', '11월', '12월'];
      return '${date.year}년 ${monthNames[date.month - 1]} ${date.day}일';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      
      if (diff.inMinutes < 1) {
        return '방금 전';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}분 전';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}시간 전';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}일 전';
      } else {
        return '${dateTime.month}월 ${dateTime.day}일';
      }
    } catch (e) {
      return dateTimeStr;
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
                        '타임캡슐',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_timeCapsule != null && _timeCapsule!['canOpen'] == true && _timeCapsule!['isOpened'] == false)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.yellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: _isOpening ? null : _openTimeCapsule,
                          child: _isOpening
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  '열기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                    : _timeCapsule == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '타임캡슐을 불러올 수 없습니다',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Container(
                                  margin: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        _buildHeader(),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Title
                                        Text(
                                          _timeCapsule!['title'],
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            height: 1.3,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Content
                                        if (_timeCapsule!['isOpened'] == true)
                                          _buildContent()
                                        else
                                          _buildLockedContent(),
                                      ],
                                    ),
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

  Widget _buildHeader() {
    final author = _timeCapsule!['author'] as Map<String, dynamic>;
    final isOpened = _timeCapsule!['isOpened'] as bool;
    final canOpen = _timeCapsule!['canOpen'] as bool;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isOpened 
                  ? Colors.green.withValues(alpha: 0.1)
                  : canOpen 
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
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
              size: 40,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Author and Date Info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF667eea).withValues(alpha: 0.1),
                child: Text(
                  author['nickname']?.substring(0, 1) ?? '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                      '작성: ${_formatDateTime(_timeCapsule!['createdAt'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '오픈: ${_formatDate(_timeCapsule!['openDate'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_timeCapsule!['openedAt'] != null)
                    Text(
                      '열림: ${_formatDateTime(_timeCapsule!['openedAt'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '타임캡슐이 열렸습니다!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _timeCapsule!['content'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedContent() {
    final canOpen = _timeCapsule!['canOpen'] as bool;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            canOpen ? Icons.vpn_key : Icons.lock,
            color: canOpen ? Colors.orange : Colors.grey.shade600,
            size: 48,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            canOpen 
                ? '타임캡슐을 열 수 있습니다!'
                : '아직 열 수 없는 타임캡슐입니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: canOpen ? Colors.orange : Colors.grey.shade700,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            canOpen 
                ? '상단의 "열기" 버튼을 눌러 내용을 확인해보세요.'
                : '설정된 날짜가 되면 자동으로 열 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}