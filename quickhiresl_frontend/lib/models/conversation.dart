import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String jobId;
  final String jobTitle;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.jobId,
    required this.jobTitle,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, String id) {
    return Conversation(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['last_message'] ?? '',
      lastMessageTime: (map['last_message_time'] as Timestamp).toDate(),
      unreadCount: map['unread_count'] ?? 0,
      jobId: map['job_id'] ?? '',
      jobTitle: map['job_title'] ?? '',
    );
  }
} 