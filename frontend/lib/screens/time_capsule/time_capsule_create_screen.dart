import 'package:flutter/material.dart';
import '../../services/time_capsule_service.dart';

class TimeCapsuleCreateScreen extends StatefulWidget {
  const TimeCapsuleCreateScreen({super.key});

  @override
  State<TimeCapsuleCreateScreen> createState() => _TimeCapsuleCreateScreenState();
}

class _TimeCapsuleCreateScreenState extends State<TimeCapsuleCreateScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  
  final TimeCapsuleService _timeCapsuleService = TimeCapsuleService();
  bool _isLoading = false;
  DateTime? _selectedDate;
  String _selectedType = 'COUPLE';

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

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10년 후까지
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createTimeCapsule() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('제목을 입력해주세요.');
      return;
    }
    
    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('내용을 입력해주세요.');
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('오픈 날짜를 선택해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _timeCapsuleService.createTimeCapsule(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        openDate: _selectedDate!,
        type: _selectedType,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('타임캡슐이 생성되었습니다.'),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('타임캡슐 생성에 실패했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    return '${date.year}년 ${monthNames[date.month - 1]} ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
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
                              '타임캡슐 생성',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: _isLoading ? null : _createTimeCapsule,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      '생성',
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title Input
                              TextField(
                                controller: _titleController,
                                focusNode: _titleFocusNode,
                                decoration: const InputDecoration(
                                  hintText: '타임캡슐 제목을 입력하세요',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Type Selection
                              const Text(
                                '타임캡슐 타입',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedType = 'COUPLE';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _selectedType == 'COUPLE' 
                                              ? const Color(0xFF667eea).withValues(alpha: 0.1)
                                              : Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedType == 'COUPLE' 
                                                ? const Color(0xFF667eea)
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.favorite,
                                              color: _selectedType == 'COUPLE' 
                                                  ? const Color(0xFF667eea)
                                                  : Colors.grey.shade600,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '커플 타임캡슐',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedType == 'COUPLE' 
                                                    ? const Color(0xFF667eea)
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedType = 'PERSONAL';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _selectedType == 'PERSONAL' 
                                              ? const Color(0xFF667eea).withValues(alpha: 0.1)
                                              : Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedType == 'PERSONAL' 
                                                ? const Color(0xFF667eea)
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: _selectedType == 'PERSONAL' 
                                                  ? const Color(0xFF667eea)
                                                  : Colors.grey.shade600,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '개인 타임캡슐',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedType == 'PERSONAL' 
                                                    ? const Color(0xFF667eea)
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Date Selection
                              const Text(
                                '오픈 날짜',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              GestureDetector(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Color(0xFF667eea),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedDate != null 
                                            ? _formatDate(_selectedDate!)
                                            : '날짜를 선택하세요',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedDate != null 
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Content Input
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 200,
                                  maxHeight: 300,
                                ),
                                child: TextField(
                                  controller: _contentController,
                                  focusNode: _contentFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: '미래의 자신이나 연인에게 전하고 싶은 메시지를 작성하세요.\n\n설정한 날짜가 되면 타임캡슐이 열립니다 💝',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.6,
                                  ),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  textAlignVertical: TextAlignVertical.top,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade600,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '타임캡슐은 설정한 날짜가 되면 자동으로 열립니다. 한 번 생성하면 수정할 수 없으니 신중하게 작성해주세요.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
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
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}