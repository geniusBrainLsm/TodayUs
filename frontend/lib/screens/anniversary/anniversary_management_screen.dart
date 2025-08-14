import 'package:flutter/material.dart';
import '../../services/anniversary_service.dart';
import '../../services/milestone_service.dart';
import '../../services/custom_anniversary_service.dart';
import 'custom_anniversary_form_screen.dart';

class AnniversaryManagementScreen extends StatefulWidget {
  const AnniversaryManagementScreen({super.key});

  @override
  State<AnniversaryManagementScreen> createState() => _AnniversaryManagementScreenState();
}

class _AnniversaryManagementScreenState extends State<AnniversaryManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  DateTime? _anniversaryDate;
  List<Map<String, dynamic>> _milestones = [];
  List<Map<String, dynamic>> _customAnniversaries = [];
  bool _isLoading = true;

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

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final anniversaryData = await AnniversaryService.getAnniversary();
      final milestones = await MilestoneService.getAllMilestones();
      final customAnniversaries = await CustomAnniversaryService.getUpcomingCustomAnniversaries();

      if (mounted) {
        setState(() {
          _anniversaryDate = anniversaryData?['anniversaryDate'] as DateTime?;
          _milestones = milestones;
          _customAnniversaries = customAnniversaries;
          _isLoading = false;
        });
        
        _fadeController.forward();
      }
    } catch (e) {
      print('Error loading anniversary data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editAnniversary() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _anniversaryDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      try {
        bool success;
        
        if (_anniversaryDate != null) {
          success = await AnniversaryService.updateAnniversary(selectedDate);
        } else {
          success = await AnniversaryService.saveAnniversary(selectedDate);
        }
        
        if (mounted) {
          if (success) {
            setState(() {
              _anniversaryDate = selectedDate;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('만난 날이 설정되었습니다'),
                backgroundColor: const Color(0xFF667eea),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            
            // Reload milestones
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('설정 중 오류가 발생했습니다'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('설정 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '기념일 관리',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            )
          : AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: CustomScrollView(
                    slivers: [
                      // Anniversary Setup Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildAnniversarySetupCard(),
                        ),
                      ),
                      
                      // Custom Anniversaries Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '나만의 기념일',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addCustomAnniversary,
                                icon: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Color(0xFF667eea),
                                ),
                                label: const Text(
                                  '추가',
                                  style: TextStyle(
                                    color: Color(0xFF667eea),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (_customAnniversaries.isNotEmpty) ...[
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final anniversary = _customAnniversaries[index];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                child: _buildCustomAnniversaryCard(anniversary),
                              );
                            },
                            childCount: _customAnniversaries.length,
                          ),
                        ),
                      ] else ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.celebration_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '아직 등록된 기념일이 없어요',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '특별한 날을 추가해보세요',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      // Milestones Section
                      if (_anniversaryDate != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                            child: Text(
                              '연애 기념일',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                        
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final milestone = _milestones[index];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                child: _buildMilestoneCard(milestone),
                              );
                            },
                            childCount: _milestones.length,
                          ),
                        ),
                      ],
                      
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnniversarySetupCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.pink.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '우리의 만난 날',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (_anniversaryDate != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.pink.shade100,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    MilestoneService.formatMilestoneDate(_anniversaryDate!),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'D+${AnniversaryService.calculateDaysSince(_anniversaryDate!)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '함께한 소중한 시간',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.pink.shade500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editAnniversary,
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.pink.shade600,
                ),
                label: Text(
                  '만난 날 수정',
                  style: TextStyle(
                    color: Colors.pink.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.pink.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아직 만난 날이 설정되지 않았어요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '특별한 날을 설정하면\n다양한 기념일을 확인할 수 있어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _editAnniversary,
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        '만난 날 설정하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final isPassed = milestone['isPassed'] as bool;
    final isToday = milestone['isToday'] as bool;
    final title = milestone['title'] as String;
    final date = milestone['date'] as DateTime;
    final daysUntil = milestone['daysUntil'] as int;
    final type = milestone['type'] as String;
    
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.black87;
    Color iconColor = const Color(0xFF667eea);
    
    if (isToday) {
      cardColor = const Color(0xFF667eea).withValues(alpha: 0.1);
      borderColor = const Color(0xFF667eea);
      textColor = const Color(0xFF667eea);
      iconColor = const Color(0xFF667eea);
    } else if (isPassed) {
      cardColor = Colors.grey.shade50;
      textColor = Colors.grey.shade600;
      iconColor = Colors.grey.shade400;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isToday ? [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                MilestoneService.getMilestoneIcon(milestone),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  MilestoneService.formatMilestoneDate(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    MilestoneService.getDaysUntilString(daysUntil),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 사용자 기념일 추가
  Future<void> _addCustomAnniversary() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CustomAnniversaryFormScreen(),
      ),
    );

    if (result == true) {
      _loadData(); // 데이터 새로고침
    }
  }

  // 사용자 기념일 수정
  Future<void> _editCustomAnniversary(Map<String, dynamic> anniversary) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CustomAnniversaryFormScreen(anniversary: anniversary),
      ),
    );

    if (result == true) {
      _loadData(); // 데이터 새로고침
    }
  }

  // 사용자 기념일 삭제
  Future<void> _deleteCustomAnniversary(Map<String, dynamic> anniversary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기념일 삭제'),
        content: Text('${anniversary['title']} 기념일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CustomAnniversaryService.deleteCustomAnniversary(anniversary['id']);
      
      if (success) {
        _loadData(); // 데이터 새로고침
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('기념일이 삭제되었습니다'),
              backgroundColor: const Color(0xFF667eea),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('삭제 중 오류가 발생했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 사용자 기념일 카드 빌드
  Widget _buildCustomAnniversaryCard(Map<String, dynamic> anniversary) {
    final isToday = anniversary['isToday'] as bool? ?? false;
    final daysUntil = anniversary['daysUntil'] as int? ?? 0;
    final title = anniversary['title'] as String;
    final emoji = anniversary['emoji'] as String? ?? '🎉';
    final nextOccurrence = DateTime.parse(anniversary['nextOccurrence']);
    final yearsCount = anniversary['yearsCount'] as int? ?? 0;
    
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.black87;
    Color iconColor = const Color(0xFF667eea);
    
    if (isToday) {
      cardColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade800;
      iconColor = Colors.amber.shade600;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isToday ? [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  CustomAnniversaryService.formatCustomAnniversaryDate(nextOccurrence),
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
                
                if (yearsCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${yearsCount}주년',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        CustomAnniversaryService.getCustomAnniversaryDaysUntil(daysUntil),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // 수정/삭제 버튼
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editCustomAnniversary(anniversary);
                        } else if (value == 'delete') {
                          _deleteCustomAnniversary(anniversary);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('수정'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}