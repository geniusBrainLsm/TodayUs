import 'package:flutter/material.dart';
import '../../services/board_service.dart';
import 'board_detail_screen.dart';
import 'board_write_screen.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allBoards = [];
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _pinnedNotices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load pinned notices
      final pinned = await BoardService.getPinnedNotices();

      // Load all boards
      final allResponse = await BoardService.getBoards(page: 0, size: 50);
      final allContent = (allResponse['content'] as List?) ?? [];

      // Load notices
      final noticesResponse =
          await BoardService.getBoardsByType(type: 'NOTICE', page: 0, size: 50);
      final noticesContent = (noticesResponse['content'] as List?) ?? [];

      // Load suggestions
      final suggestionsResponse = await BoardService.getBoardsByType(
          type: 'SUGGESTION', page: 0, size: 50);
      final suggestionsContent = (suggestionsResponse['content'] as List?) ?? [];

      if (mounted) {
        setState(() {
          _pinnedNotices = pinned.cast<Map<String, dynamic>>();
          _allBoards = allContent.cast<Map<String, dynamic>>();
          _notices = noticesContent.cast<Map<String, dynamic>>();
          _suggestions = suggestionsContent.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('게시판 로드 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시판을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시판'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '공지사항'),
            Tab(text: '건의사항'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBoardList(_allBoards, showPinned: true),
                _buildBoardList(_notices),
                _buildBoardList(_suggestions),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BoardWriteScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text('건의하기'),
        backgroundColor: const Color(0xFF667eea),
      ),
    );
  }

  Widget _buildBoardList(List<Map<String, dynamic>> boards,
      {bool showPinned = false}) {
    if (boards.isEmpty && _pinnedNotices.isEmpty) {
      return const Center(
        child: Text(
          '게시글이 없습니다',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: (showPinned ? _pinnedNotices.length : 0) + boards.length,
        itemBuilder: (context, index) {
          // Show pinned notices first
          if (showPinned && index < _pinnedNotices.length) {
            return _buildBoardCard(_pinnedNotices[index], isPinned: true);
          }

          final adjustedIndex =
              showPinned ? index - _pinnedNotices.length : index;
          return _buildBoardCard(boards[adjustedIndex]);
        },
      ),
    );
  }

  Widget _buildBoardCard(Map<String, dynamic> board, {bool isPinned = false}) {
    final title = board['title']?.toString() ?? '';
    final type = board['type']?.toString() ?? '';
    final viewCount = board['viewCount'] ?? 0;
    final createdAt = board['createdAt']?.toString() ?? '';
    final author = board['author'] as Map<String, dynamic>?;
    final authorName = author?['nickname']?.toString() ?? '익명';
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
      elevation: isPinned ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPinned
            ? const BorderSide(color: Color(0xFFFF6B6B), width: 2)
            : BorderSide.none,
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
              _loadData();
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
                  if (isPinned)
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
                  if (isPinned) const SizedBox(width: 8),
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
              Row(
                children: [
                  Text(
                    authorName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
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
