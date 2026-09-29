import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String? message;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    this.message,
    this.imageUrl,
    required this.createdAt,
    this.readAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      senderId: json['senderId'].toString(),
      senderRole: json['senderRole'] ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      message: json['message'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isMine: json['mine'] ?? json['isMine'] ?? false,
    );
  }

  bool get hasText => message != null && message!.trim().isNotEmpty;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}
