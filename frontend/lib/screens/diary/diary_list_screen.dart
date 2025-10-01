import 'package:flutter/material.dart';

import '../../config/environment.dart';
import '../../services/diary_service.dart';
import 'diary_detail_screen.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  DiaryListScreenState createState() => DiaryListScreenState();
}

class DiaryListScreenState extends State<DiaryListScreen> {
  final DiaryService _diaryService = DiaryService();

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _diaries = [];

  bool _isLoading = false;

  bool _hasMore = true;

  int _currentPage = 0;

  final int _pageSize = 20;

  static const List<Color> _authorPalette = <Color>[
    Color(0xFFFF6B9A),
    Color(0xFF60A5FA),
  ];

  final Map<String, Color> _authorColors = {};

  @override
  void initState() {
    super.initState();

    _loadDiaries();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_isLoading && _hasMore) {
        _loadMoreDiaries();
      }
    }
  }

  Future<void> _loadDiaries() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final diaries = await _diaryService.getDiaries(page: 0, size: _pageSize);

      if (!mounted) return;

      setState(() {
        _diaries = diaries;

        _currentPage = 0;

        _hasMore = diaries.length == _pageSize;

        _isLoading = false;

        _assignAuthorColors();
      });
    } catch (error) {
      debugPrint('Load diaries error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('일기 목록을 불러오지 못했어요.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _loadMoreDiaries() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;

      final newDiaries =
          await _diaryService.getDiaries(page: nextPage, size: _pageSize);

      if (!mounted) return;

      setState(() {
        _diaries.addAll(newDiaries);

        _currentPage = nextPage;

        _hasMore = newDiaries.length == _pageSize;

        _isLoading = false;

        _assignAuthorColors();
      });
    } catch (error) {
      debugPrint('Load more diaries error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> refreshContent() async {
    await _loadDiaries();
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
        return '${date.month}월 ${date.day}일';
      }
    } catch (e) {
      return dateStr;
    }
  }

  String? _resolveImageUrl(dynamic rawUrl) {
    if (rawUrl == null) return null;

    final value = rawUrl.toString();

    if (value.isEmpty) return null;

    if (value.startsWith('http')) {
      return value;
    }

    return '${EnvironmentConfig.baseUrl}$value';
  }

  void _assignAuthorColors() {
    final uniqueKeys = <String>{};

    for (final diary in _diaries) {
      final author = diary['author'] as Map<String, dynamic>?;

      final key = _authorKey(author);

      if (key != null) {
        uniqueKeys.add(key);
      }
    }

    final sortedKeys = uniqueKeys.toList()..sort();

    _authorColors.clear();

    for (var i = 0; i < sortedKeys.length; i++) {
      final color = _authorPalette[i % _authorPalette.length];

      _authorColors[sortedKeys[i]] = color;
    }
  }

  String? _authorKey(Map<String, dynamic>? author) {
    if (author == null) return null;

    final id = author['id'];

    if (id != null) {
      return 'id:$id';
    }

    final email = (author['email'] as String?)?.trim();

    if (email != null && email.isNotEmpty) {
      return 'email:$email';
    }

    return null;
  }

  Color _colorForAuthor(Map<String, dynamic>? author) {
    final key = _authorKey(author);

    if (key == null) {
      return const Color(0xFFE5E7EB);
    }

    return _authorColors[key] ?? _authorPalette[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF4A90E2),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '우리의 일기',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '오늘 느낀 마음을 기록하고 서로의 하루를 확인해보세요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (_diaries.isEmpty && !_isLoading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                size: 44,
                                color: Color(0xFF4A90E2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '아직 작성된 일기가 없어요.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '따뜻했던 순간을 기록하면 이곳에서 바로 확인할 수 있어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _diaries.length) {
                              if (_hasMore && _isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF4A90E2),
                                    ),
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            }

                            final diary = _diaries[index];

                            return _buildDiaryCard(diary);
                          },
                          childCount: _diaries.length +
                              (_hasMore && _isLoading ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryCard(Map<String, dynamic> diary) {
    final author = (diary['author'] as Map<String, dynamic>?) ?? {};

    final nickname = (author['nickname'] as String?)?.trim();

    final displayName =
        (nickname == null || nickname.isEmpty) ? '익명' : nickname;

    final borderColor = _colorForAuthor(author);

    final imageUrl = _resolveImageUrl(diary['imageUrl']);

    final title = (diary['title'] as String?) ?? '';

    final content = (diary['content'] as String?) ?? '';

    final int commentCount =
        int.tryParse((diary['commentCount'] ?? '0').toString()) ?? 0;

    final diaryId = diary['id'] as int?;

    return GestureDetector(
      onTap: diaryId == null
          ? null
          : () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiaryDetailScreen(diaryId: diaryId),
                ),
              );

              if (mounted) {
                await refreshContent();
              }
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(
                                diary['diaryDate']?.toString() ?? ''),
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
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '댓글 $commentCount개',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
