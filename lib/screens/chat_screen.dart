import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medichelp/models/chat_message.dart';
import 'package:medichelp/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String? patientId;
  final bool isDoctorView;
  final String title;

  const ChatScreen({
    super.key,
    this.patientId,
    required this.isDoctorView,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _doctorName;
  String? _patientName;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getChatMessages(
        patientId: widget.isDoctorView ? widget.patientId : null,
      );
      final doctor = data['doctor'] as Map<String, dynamic>?;
      final patient = data['patient'] as Map<String, dynamic>?;
      final messagesJson = data['messages'] as List<dynamic>? ?? [];

      final parsedMessages = messagesJson
          .map(
            (json) => ChatMessage.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      setState(() {
        _messages
          ..clear()
          ..addAll(parsedMessages);
        _doctorName = doctor?['name'] as String?;
        _patientName = patient?['name'] as String?;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить чат: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final response = await ApiService.sendChatMessage(
        text,
        patientId: widget.isDoctorView ? widget.patientId : null,
      );
      final message = ChatMessage.fromJson(response);
      setState(() {
        _messages.add(message);
        _messageController.clear();
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatTitle = widget.isDoctorView
        ? (_patientName ?? widget.title)
        : (_doctorName ?? widget.title);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          chatTitle,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                widget.isDoctorView ? 'Врач' : 'Пациент',
                style: GoogleFonts.lato(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _messages.isEmpty
                        ? _buildEmptyView()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isOwn = widget.isDoctorView
                                  ? message.senderRole == 'doctor'
                                  : message.senderRole == 'patient';
                              return _buildMessageBubble(message, isOwn);
                            },
                          ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'Ошибка загрузки',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Пока нет сообщений',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isDoctorView
                  ? 'Напишите пациенту, чтобы уточнить самочувствие и ход лечения.'
                  : 'Задайте вопрос врачу или расскажите о самочувствии.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isOwn) {
    final alignment = isOwn ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor =
        isOwn ? const Color(0xFF007BFF) : Colors.white;
    final textColor = isOwn ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isOwn ? 18 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.lato(
                color: textColor,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(message.createdAt),
              style: GoogleFonts.lato(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Введите сообщение...',
                  hintStyle: GoogleFonts.lato(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF007BFF)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                enabled: !_isSending,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _isSending
                    ? Colors.grey.shade400
                    : const Color(0xFF007BFF),
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$day.$month $hours:$minutes';
  }
}
