import 'package:flutter/material.dart';
import '../../services/diary_service.dart';

class DiaryDetailScreen extends StatefulWidget {
  final int diaryId;

  const DiaryDetailScreen({
    super.key,
    required this.diaryId,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final DiaryService _diaryService = DiaryService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  Map<String, dynamic>? _diary;
  bool _isLoading = true;
  bool _isAddingComment = false;

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

    _loadDiary();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDiary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diary = await _diaryService.getDiary(widget.diaryId);
      
      if (mounted) {
        setState(() {
          _diary = diary;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    } catch (error) {
      print('Load diary error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().contains('권한이 없습니다')
                ? '일기에 접근할 권한이 없습니다.'
                : '일기를 불러오는데 실패했습니다.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글 내용을 입력해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAddingComment = true;
    });

    try {
      await _diaryService.addComment(
        diaryId: widget.diaryId,
        comment: _commentController.text.trim(),
      );

      _commentController.clear();
      _commentFocusNode.unfocus();
      
      // Reload diary to get updated comments
      await _loadDiary();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('댓글이 추가되었습니다.'),
            backgroundColor: Colors.green.shade400,
          ),
        );
      }
    } catch (error) {
      print('Add comment error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().contains('권한이 없습니다')
                ? '댓글을 추가할 권한이 없습니다.'
                : '댓글 추가에 실패했습니다.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingComment = false;
        });
      }
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
        return '${date.year}년 ${monthNames[date.month - 1]} ${date.day}일';
      }
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                margin: const EdgeInsets.all(20),
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
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '일기 상세',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Share or more options
                      },
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade700,
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
                          color: Color(0xFF4A90E2),
                        ),
                      )
                    : _diary == null
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '일기를 불러올 수 없습니다',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Column(
                                  children: [
                                    // Diary Content
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                                        child: CustomScrollView(
                                          controller: _scrollController,
                                          slivers: [
                                            // Diary Header
                                            SliverToBoxAdapter(
                                              child: _buildDiaryHeader(),
                                            ),
                                            
                                            // Diary Content
                                            SliverToBoxAdapter(
                                              child: _buildDiaryContent(),
                                            ),
                                            
                                            // AI Analysis
                                            if (_diary!['aiProcessed'] == true)
                                              SliverToBoxAdapter(
                                                child: _buildAiAnalysis(),
                                              ),
                                            
                                            // Comments Section
                                            SliverToBoxAdapter(
                                              child: _buildCommentsSection(),
                                            ),
                                            
                                            // Bottom padding
                                            const SliverToBoxAdapter(
                                              child: SizedBox(height: 100),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Comment Input
                                    _buildCommentInput(),
                                  ],
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

  Widget _buildDiaryHeader() {
    final author = _diary!['author'] as Map<String, dynamic>;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author and Date
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                child: Text(
                  author['nickname']?.substring(0, 1) ?? '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author['nickname'] ?? '익명',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDate(_diary!['diaryDate']),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Mood Emoji
              if (_diary!['moodEmoji'] != null && _diary!['moodEmoji'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _diary!['moodEmoji'],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Text(
            _diary!['title'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (if exists)
          if (_diary!['imageUrl'] != null && _diary!['imageUrl'].toString().isNotEmpty) ...[
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 300),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'http://localhost:8080${_diary!['imageUrl']}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
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
          ],
          
          // Content text
          Text(
            _diary!['content'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnalysis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
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
                color: const Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI 감정 분석',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (_diary!['aiEmotion'] != null && _diary!['aiEmotion'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '감정: ${_diary!['aiEmotion']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          if (_diary!['aiComment'] != null && _diary!['aiComment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _diary!['aiComment'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A90E2),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    final comments = _diary!['comments'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                '댓글 ${comments.length}개',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (comments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 32,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아직 댓글이 없어요\n첫 번째 댓글을 남겨보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: comments.map<Widget>((comment) {
                final commentMap = comment as Map<String, dynamic>;
                final isAiComment = commentMap['type'] == 'AI';
                final author = commentMap['author'] as Map<String, dynamic>?;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAiComment ? const Color(0xFF4A90E2).withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAiComment ? const Color(0xFF4A90E2).withValues(alpha: 0.2) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comment Header
                      Row(
                        children: [
                          if (isAiComment)
                            const Icon(
                              Icons.smart_toy,
                              size: 16,
                              color: Color(0xFF4A90E2),
                            )
                          else
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                              child: Text(
                                author?['nickname']?.substring(0, 1) ?? '?',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            isAiComment ? 'AI' : (author?['nickname'] ?? '익명'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isAiComment ? const Color(0xFF4A90E2) : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDateTime(commentMap['createdAt']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Comment Content
                      Text(
                        commentMap['content'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isAiComment ? const Color(0xFF4A90E2) : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isAddingComment ? null : _addComment,
              icon: _isAddingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}