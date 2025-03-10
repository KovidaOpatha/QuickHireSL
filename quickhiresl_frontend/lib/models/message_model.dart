import 'package:flutter/material.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String messageType; // 'text', 'image', 'file'

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.messageType = 'text',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      attachmentUrl: json['attachmentUrl'],
      messageType: json['messageType'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'messageType': messageType,
    };
  }
}

class Conversation {
  final String id;
  final List<String> participants;
  final Message lastMessage;
  final DateTime updatedAt;
  final String? name; // For group chats
  final String? imageUrl;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
    this.name,
    this.imageUrl,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: Message.fromJson(json['lastMessage'] ?? {}),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      name: json['name'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants,
      'lastMessage': lastMessage.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}
