import 'package:flutter/material.dart';
import '../../services/board_service.dart';
import '../../services/board_comment_service.dart';

class BoardDetailScreen extends StatefulWidget {
  final int boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _board;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBoard();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadBoard() async {
    setState(() => _isLoading = true);

    try {
      final board = await BoardService.getBoardDetail(widget.boardId);

      if (mounted) {
        setState(() {
          _board = board;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('게시글 로드 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await BoardCommentService.getComments(widget.boardId);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      print('댓글 로드 오류: $e');
    }
  }

  Future<void> _createComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    try {
      await BoardCommentService.createComment(
        boardId: widget.boardId,
        content: _commentController.text.trim(),
      );

      _commentController.clear();
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 작성되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      final success = await BoardCommentService.deleteComment(
        boardId: widget.boardId,
        commentId: commentId,
      );

      if (success) {
        await _loadComments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 삭제되었습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteBoard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await BoardService.deleteBoard(widget.boardId);
      if (success && mounted) {
        Navigator.pop(context, true); // Return to list with refresh signal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_board == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('게시글을 찾을 수 없습니다'),
        ),
      );
    }

    final title = _board!['title']?.toString() ?? '';
    final content = _board!['content']?.toString() ?? '';
    final type = _board!['type']?.toString() ?? '';
    final viewCount = _board!['viewCount'] ?? 0;
    final pinned = _board!['pinned'] as bool? ?? false;
    final createdAt = _board!['createdAt']?.toString() ?? '';
    final author = _board!['author'] as Map<String, dynamic>?;
    final authorName = author?['nickname']?.toString() ?? '익명';

    Color typeColor;
    String typeText;
    switch (type) {
      case 'NOTICE':
        typeColor = Colors.red;
        typeText = '공지사항';
        break;
      case 'SUGGESTION':
        typeColor = Colors.blue;
        typeText = '건의사항';
        break;
      case 'FAQ':
        typeColor = Colors.green;
        typeText = 'FAQ';
        break;
      default:
        typeColor = Colors.grey;
        typeText = type;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          // Only show delete for own posts (you can add edit permission check)
          if (type == 'SUGGESTION')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteBoard();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (pinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '📌 고정',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (pinned) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '조회 $viewCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          authorName.isNotEmpty
                              ? authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),

            // Admin Reply Section
            if (_board!['adminReply'] != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '관리자 답변',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const Spacer(),
                        if (_board!['adminRepliedAt'] != null)
                          Text(
                            _formatDate(_board!['adminRepliedAt']),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _board!['adminReply'],
                      style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],

            // Comments Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '댓글',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_comments.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Comment Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: '댓글을 입력하세요',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _createComment,
                        icon: const Icon(Icons.send),
                        color: const Color(0xFF667eea),
                        iconSize: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Comments List
                  if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '첫 댓글을 작성해보세요!',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final author = comment['author'] as Map<String, dynamic>?;
                        final authorName = author?['nickname']?.toString() ?? '익명';
                        final commentContent = comment['content']?.toString() ?? '';
                        final createdAt = comment['createdAt']?.toString() ?? '';
                        final commentId = comment['id'] as int?;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF667eea).withOpacity(0.2),
                                  child: Text(
                                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF667eea),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onPressed: () {
                                    if (commentId != null) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('댓글 삭제'),
                                          content: const Text('이 댓글을 삭제하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteComment(commentId);
                                              },
                                              child: const Text(
                                                '삭제',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Text(
                                commentContent,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
