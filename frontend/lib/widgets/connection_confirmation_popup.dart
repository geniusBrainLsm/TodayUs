import 'package:flutter/material.dart';

/// A beautiful popup dialog for confirming partner connection
/// Shows partner information and allows user to approve or decline the connection
class ConnectionConfirmationPopup extends StatefulWidget {
  final String partnerName;
  final String partnerNickname;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const ConnectionConfirmationPopup({
    super.key,
    required this.partnerName,
    required this.partnerNickname,
    this.onApprove,
    this.onDecline,
  });

  @override
  State<ConnectionConfirmationPopup> createState() => _ConnectionConfirmationPopupState();

  /// Static method to show the connection confirmation popup
  static Future<bool?> show({
    required BuildContext context,
    required String partnerName,
    required String partnerNickname,
    VoidCallback? onApprove,
    VoidCallback? onDecline,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectionConfirmationPopup(
        partnerName: partnerName,
        partnerNickname: partnerNickname,
        onApprove: onApprove,
        onDecline: onDecline,
      ),
    );
  }
}

class _ConnectionConfirmationPopupState extends State<ConnectionConfirmationPopup> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced header with hearts decoration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B8A),
                    Color(0xFFFFB6C1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Enhanced heart animation area
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 40,
                        ),
                        // Floating mini hearts
                        Positioned(
                          top: 10,
                          right: 15,
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 12,
                          ),
                        ),
                        Positioned(
                          bottom: 15,
                          left: 10,
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '💕 커플 연결 요청',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사랑스러운 연결이 시작되려고 해요',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced content area
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Main message with enhanced styling
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: Color(0xFF2D3748),
                      ),
                      children: [
                        TextSpan(
                          text: '이 파트너와 ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: '연결',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B8A),
                          ),
                        ),
                        TextSpan(
                          text: '하시겠어요?',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Enhanced partner information card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B8A).withValues(alpha: 0.05),
                          const Color(0xFFFFB6C1).withValues(alpha: 0.02),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B8A).withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Enhanced partner avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF6B8A),
                                Color(0xFFFFB6C1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(45),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B8A).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Partner name with enhanced styling
                        Text(
                          widget.partnerName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3748),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Enhanced partner nickname
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF6B8A).withValues(alpha: 0.15),
                                const Color(0xFFFFB6C1).withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '@${widget.partnerNickname}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Enhanced info message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B8A).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.favorite_outline,
                            color: Color(0xFFFF6B8A),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '연결하면 함께 소중한 순간들을 기록하고\n나눠할 수 있어요 💕',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Enhanced action buttons
                  Row(
                    children: [
                      // Enhanced decline button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            color: Colors.white,
                          ),
                          child: TextButton(
                            onPressed: _isProcessing ? null : _handleDecline,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '생각해볼게요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6B8A),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Enhanced approve button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF6B8A),
                                Color(0xFFFFB6C1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B8A).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: _isProcessing ? null : _handleApprove,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isProcessing
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '네, 연결할게요!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handle approve action with loading state
  void _handleApprove() async {
    setState(() => _isProcessing = true);
    
    // Simulate processing time (remove in production)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.of(context).pop(true);
      widget.onApprove?.call();
    }
  }

  /// Handle decline action
  void _handleDecline() {
    Navigator.of(context).pop(false);
    widget.onDecline?.call();
  }

}