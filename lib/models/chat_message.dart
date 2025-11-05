class ChatMessage {
  final String id;
  final String senderRole;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderRole,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['_id'],
      senderRole: json['senderRole'] ?? 'patient',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}
