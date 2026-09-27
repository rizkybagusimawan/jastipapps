class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String message;
  final String createdAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.message,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderRole: json['senderRole'],
      senderName: json['senderName'],
      message: json['message'],
      createdAt: json['createdAt'],
      isMine: json['isMine'] ?? false,
    );
  }
}
