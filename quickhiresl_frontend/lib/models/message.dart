import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool read;
  final String jobId;
  final String senderRole;
  final String senderName;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.read,
    required this.jobId,
    required this.senderRole,
    required this.senderName,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['sender_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      read: map['read'] ?? false,
      jobId: map['job_id'] ?? '',
      senderRole: map['sender_role'] ?? '',
      senderName: map['sender_name'] ?? '',
    );
  }
} 