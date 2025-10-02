import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'screens/diary/diary_list_screen.dart';
import 'screens/diary/diary_write_screen.dart';
import 'screens/ai/ai_chat_screen.dart';
import 'screens/store/store_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/diary_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _hasTodayDiary = false;
  final DiaryService _diaryService = DiaryService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 스크린 초기화 - 홈스크린에 콜백 전달
    _screens = [
      HomeScreen(onDiaryStateChanged: _checkTodayDiary),
      const DiaryListScreen(),
      const AiChatScreen(),
      const StoreScreen(),
      const ProfileScreen(),
    ];

    _checkTodayDiary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 포그라운드로 돌아올 때 일기 상태 업데이트
    if (state == AppLifecycleState.resumed) {
      _checkTodayDiary();
    }
  }

  /// 오늘 일기 존재 여부 확인
  Future<void> _checkTodayDiary() async {
    try {
      final hasTodayDiary = await _diaryService.hasTodayDiary();
      if (mounted) {
        setState(() {
          _hasTodayDiary = hasTodayDiary;
        });
      }
    } catch (e) {
      print('오늘 일기 확인 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.black87,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: '일기',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy_outlined),
                activeIcon: Icon(Icons.smart_toy),
                label: 'AI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined),
                activeIcon: Icon(Icons.store),
                label: '상점',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '프로필',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _currentIndex == 1 && !_hasTodayDiary // 일기 탭에서만 & 오늘 일기가 없을 때만 보이도록
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => const DiaryWriteScreen(),
                      ),
                    )
                        .then((result) {
                      // 일기 작성 화면에서 돌아왔을 때 상태 업데이트
                      if (result is Map && result['diaryCreated'] == true) {
                        print('🟢 MainLayout: 일기 작성 완료 - 상태 업데이트');
                      }
                      _checkTodayDiary();
                    });
                  },
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.edit),
                )
              : null,
    );
  }
}
