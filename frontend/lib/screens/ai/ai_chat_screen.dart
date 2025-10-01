import 'package:flutter/material.dart';

import '../../services/ai_chat_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 파트너'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChatBubble(message: message),
                      );
                    },
                  ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.smart_toy, size: 64, color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text(
              'AI 파트너에게 무엇이든 물어보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              '''"7월 1일에는 어떤 추억이 있었어?"
"우리는 어떤 순간에 가장 행복했어?"''',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'AI 파트너에게 질문을 남겨보세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messages.add(_ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await AiChatService.sendMessage(text);
      _replaceLastWithResponse(response);
    } catch (error) {
      _replaceLastWithError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _replaceLastWithResponse(AiChatResponse response) {
    if (_messages.isEmpty) return;
    setState(() {
      _messages[_messages.length - 1] = _ChatMessage(
        text: response.reply,
        isUser: false,
        timestamp: DateTime.now(),
        references: response.references,
      );
    });
  }

  void _replaceLastWithError(Object error) {
    if (_messages.isEmpty) return;
    const errorMessage = '답변을 가져오지 못했어요. 잠시 후 다시 시도해 주세요.';
    setState(() {
      _messages[_messages.length - 1] = _ChatMessage(
        text: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = message.isUser
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade200;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: message.isLoading ? Colors.grey.shade200 : backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.isUser ? 16 : 4),
              bottomRight: Radius.circular(message.isUser ? 4 : 16),
            ),
          ),
          child: message.isLoading
              ? const _TypingIndicator()
              : Column(
                  crossAxisAlignment: message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                          color: textColor, fontSize: 15, height: 1.4),
                    ),
                    if (!message.isUser && message.references.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ReferenceList(references: message.references),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _ReferenceList extends StatelessWidget {
  final List<AiChatDiaryReference> references;

  const _ReferenceList({required this.references});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '참고한 일기',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        ...references.take(5).map((reference) {
          final subtitle = reference.diaryDate;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }),
        if (references.length > 5)
          Text(
            '외 ${references.length - 5}건',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
      ],
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
          child: FadeTransition(
            opacity: Tween(begin: 0.3, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(index * 0.2, 1, curve: Curves.easeInOut),
              ),
            ),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final List<AiChatDiaryReference> references;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    List<AiChatDiaryReference>? references,
  }) : references = references ?? const [];
}
