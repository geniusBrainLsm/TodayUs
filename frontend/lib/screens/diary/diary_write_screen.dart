import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/diary_service.dart';
import '../../services/diary_image_service.dart';
import '../../services/api_service.dart';

class DiaryWriteScreen extends StatefulWidget {
  const DiaryWriteScreen({super.key});

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  
  bool _isLoading = false;
  String _selectedMood = '';
  File? _selectedImage;
  String? _uploadedImageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<Map<String, String>> _moodOptions = [
    {'emoji': '😊', 'label': '행복해요'},
    {'emoji': '🥰', 'label': '사랑스러워요'},
    {'emoji': '😌', 'label': '평온해요'},
    {'emoji': '😔', 'label': '우울해요'},
    {'emoji': '😠', 'label': '화나요'},
    {'emoji': '😰', 'label': '불안해요'},
    {'emoji': '🤔', 'label': '복잡해요'},
    {'emoji': '😴', 'label': '피곤해요'},
  ];

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

  Future<void> _selectImage() async {
    // 바로 갤러리에서 이미지 선택
    await _pickImageFromSource(ImageSource.gallery);
  }


  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final imageFile = File(image.path);
        
        // 파일 유효성 검증
        if (!DiaryImageService.validateImageFile(imageFile)) {
          _showErrorSnackBar('유효하지 않은 이미지 파일입니다. (최대 10MB, jpg/png/gif/webp만 허용)');
          return;
        }

        setState(() {
          _selectedImage = imageFile;
        });

        _showSuccessSnackBar('사진이 선택되었습니다! 📸');
      }
    } catch (e) {
      print('Error selecting image: $e');
      _showErrorSnackBar('이미지 선택 중 오류가 발생했습니다.');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _saveDiary() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('제목을 입력해주세요.');
      return;
    }
    
    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('일기 내용을 입력해주세요.');
      return;
    }
    
    // 로그인 상태 확인
    final authToken = await ApiService.getAuthToken();
    if (authToken == null) {
      print('🔴 No auth token found');
      _showErrorSnackBar('로그인이 필요합니다. 다시 로그인해주세요.');
      return;
    } else {
      print('🟢 Auth token found: ${authToken.substring(0, 20)}...');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final diaryService = DiaryService();
      
      // 이미지가 선택된 경우 먼저 업로드 (S3로)
      String? imageUrl;
      if (_selectedImage != null) {
        // 파일 유효성 검증
        if (!DiaryImageService.validateImageFile(_selectedImage!)) {
          throw Exception('유효하지 않은 이미지 파일입니다. (최대 10MB, jpg/png/gif/webp만 허용)');
        }
        
        imageUrl = await DiaryImageService.uploadDiaryImage(_selectedImage!);
        setState(() {
          _uploadedImageUrl = imageUrl;
        });
      }
      
      await diaryService.createDiary(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        diaryDate: DateTime.now(),
        moodEmoji: _selectedMood,
        imageUrl: imageUrl,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // 성공 시 true 반환
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('일기가 저장되었습니다.'),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      print('Diary save error: $error');
      if (mounted) {
        _showErrorSnackBar(error.toString().contains('이미 해당 날짜에') 
            ? '이미 오늘 작성한 일기가 있습니다.'
            : '일기 저장에 실패했습니다.');
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildImageSection() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: _selectImage,
              child: Container(
                width: double.infinity,
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '사진을 추가해보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '탭하여 갤러리에서 선택',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
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
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '일기 작성',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${now.year}년 ${monthNames[now.month - 1]} ${now.day}일 (${weekdays[now.weekday - 1]})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: _isLoading ? null : _saveDiary,
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
                                      '저장',
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
                                hintText: '오늘은 어떤 하루였나요?',
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
                            
                            const SizedBox(height: 16),
                            
                            // Mood Selection
                            const Text(
                              '오늘의 기분',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Container(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _moodOptions.length,
                                itemBuilder: (context, index) {
                                  final mood = _moodOptions[index];
                                  final isSelected = _selectedMood == mood['emoji'];
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMood = isSelected ? '' : mood['emoji']!;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? const Color(0xFF667eea).withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: isSelected 
                                              ? const Color(0xFF667eea)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            mood['emoji']!,
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            mood['label']!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected 
                                                  ? const Color(0xFF667eea)
                                                  : Colors.grey.shade600,
                                              fontWeight: isSelected 
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Image Selection
                            const Text(
                              '사진 추가',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            _buildImageSection(),
                            
                            const SizedBox(height: 24),
                            
                            // Content Input
                            Container(
                              constraints: const BoxConstraints(
                                minHeight: 200,
                                maxHeight: 400,
                              ),
                              child: TextField(
                                controller: _contentController,
                                focusNode: _contentFocusNode,
                                decoration: const InputDecoration(
                                  hintText: '오늘 있었던 일들을 자유롭게 적어보세요.\n\nAI가 당신의 감정을 분석하고 따뜻한 코멘트를 남겨드릴게요 💕',
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
                            
                            // Bottom Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.grey.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'AI가 일기를 분석하여 감정 이모지와 개인화된 코멘트를 작성해드릴게요',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 키보드를 위한 여백
                            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 100 : 20),
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