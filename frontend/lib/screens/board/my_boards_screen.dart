import 'package:flutter/material.dart';
import '../../services/board_service.dart';
import 'board_detail_screen.dart';

class MyBoardsScreen extends StatefulWidget {
  const MyBoardsScreen({super.key});

  @override
  State<MyBoardsScreen> createState() => _MyBoardsScreenState();
}

class _MyBoardsScreenState extends State<MyBoardsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myBoards = [];

  @override
  void initState() {
    super.initState();
    _loadMyBoards();
  }

  Future<void> _loadMyBoards() async {
    setState(() => _isLoading = true);

    try {
      final response = await BoardService.getMyBoards(page: 0, size: 50);
      final content = (response['content'] as List?) ?? [];

      if (mounted) {
        setState(() {
          _myBoards = content.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('내 글 로드 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내 글을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 글 보기'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myBoards.isEmpty
              ? const Center(
                  child: Text(
                    '작성한 글이 없습니다',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyBoards,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myBoards.length,
                    itemBuilder: (context, index) {
                      return _buildBoardCard(_myBoards[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildBoardCard(Map<String, dynamic> board) {
    final title = board['title']?.toString() ?? '';
    final type = board['type']?.toString() ?? '';
    final viewCount = board['viewCount'] ?? 0;
    final createdAt = board['createdAt']?.toString() ?? '';
    final boardId = board['id'] as int?;

    Color typeColor;
    String typeText;
    switch (type) {
      case 'NOTICE':
        typeColor = Colors.red;
        typeText = '공지';
        break;
      case 'SUGGESTION':
        typeColor = Colors.blue;
        typeText = '건의';
        break;
      case 'FAQ':
        typeColor = Colors.green;
        typeText = 'FAQ';
        break;
      default:
        typeColor = Colors.grey;
        typeText = type;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          if (boardId != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BoardDetailScreen(boardId: boardId),
              ),
            );
            if (result == true) {
              _loadMyBoards();
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeText,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '조회 $viewCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(createdAt),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 7) {
        return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
      } else if (diff.inDays > 0) {
        return '${diff.inDays}일 전';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}시간 전';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
