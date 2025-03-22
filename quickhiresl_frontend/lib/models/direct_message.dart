class DirectMessage {
  final String id;
  final Map<String, dynamic> sender;
  final Map<String, dynamic> receiver;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? jobId;
  final String? jobTitle;
  final String messageType;

  DirectMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.jobId,
    this.jobTitle,
    this.messageType = 'direct', // Default to 'direct' for backward compatibility
  });

  String get senderId => sender['_id'] ?? '';
  String get receiverId => receiver['_id'] ?? '';

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    // Handle different possible formats
    Map<String, dynamic> senderData = {};
    if (json['sender'] is Map) {
      senderData = json['sender'];
    } else if (json['senderId'] != null) {
      senderData = {
        '_id': json['senderId'],
        'name': json['senderName'] ?? 'Unknown',
        'avatar': json['senderAvatar'],
      };
    }

    Map<String, dynamic> receiverData = {};
    if (json['receiver'] is Map) {
      receiverData = json['receiver'];
    } else if (json['receiverId'] != null) {
      receiverData = {
        '_id': json['receiverId'],
        'name': json['receiverName'] ?? 'Unknown',
        'avatar': json['receiverAvatar'],
      };
    }

    return DirectMessage(
      id: json['_id'] ?? json['id'] ?? '',
      sender: senderData,
      receiver: receiverData,
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      jobId: json['jobId'],
      jobTitle: json['jobTitle'],
      messageType: json['messageType'] ?? 'direct',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'messageType': messageType,
    };
  }
} 