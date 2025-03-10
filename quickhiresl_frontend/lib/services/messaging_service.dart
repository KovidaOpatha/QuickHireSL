import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class MessagingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<Conversation>> getConversations() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversation_id', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
    required String jobId,
    required String jobTitle,
  }) async {
    if (currentUserId == null) return;

    final conversationId = [currentUserId, receiverId]..sort();
    final timestamp = FieldValue.serverTimestamp();

    // Get sender details
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    // Update conversation
    await _firestore.collection('conversations').doc(conversationId.join('_')).set({
      'participants': conversationId,
      'last_message': content,
      'last_message_time': timestamp,
      'job_id': jobId,
      'job_title': jobTitle,
      'unread_count': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Create message
    await _firestore.collection('messages').add({
      'conversation_id': conversationId.join('_'),
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp,
      'read': false,
      'job_id': jobId,
      'sender_name': userData['name'],
      'sender_role': userData['role'],
    });

    notifyListeners();
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    
    final messages = await _firestore
        .collection('messages')
        .where('conversation_id', isEqualTo: conversationId)
        .where('receiver_id', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'read': true});
    }

    batch.update(
      _firestore.collection('conversations').doc(conversationId),
      {'unread_count': 0},
    );

    await batch.commit();
    notifyListeners();
  }

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (currentUserId != null && token != null) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .update({'fcm_token': token});
      }
    }
  }

  Future<void> sendMessageForJob({
    required String receiverId,
    required String content,
    required String jobId,
    required String jobTitle,
  }) async {
    if (currentUserId == null) return;

    try {
      // Get or create conversation
      final conversationRef = _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .where('job_id', isEqualTo: jobId);

      final conversationSnapshot = await conversationRef.get();
      String conversationId;

      if (conversationSnapshot.docs.isEmpty) {
        // Create new conversation
        final newConversationRef = await _firestore
            .collection('conversations')
            .add({
          'participants': [currentUserId, receiverId],
          'job_id': jobId,
          'job_title': jobTitle,
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
          'unread_count': 1,
          'updated_at': FieldValue.serverTimestamp(),
        });
        conversationId = newConversationRef.id;
      } else {
        conversationId = conversationSnapshot.docs[0].id;
        // Update existing conversation
        await conversationSnapshot.docs[0].reference.update({
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
          'unread_count': FieldValue.increment(1),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Get sender details
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Create message
      await _firestore.collection('messages').add({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'job_id': jobId,
        'sender_name': userData['name'],
        'sender_role': userData['role'],
      });

      // Send notification if possible
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      final receiverData = receiverDoc.data();
      
      if (receiverData != null && receiverData['fcm_token'] != null) {
        await _messaging.sendMessage(
          to: receiverData['fcm_token'],
          data: {
            'jobId': jobId,
            'jobTitle': jobTitle,
            'conversationId': conversationId,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );
      }

      notifyListeners();
    } catch (error) {
      print('Error sending message: $error');
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (currentUserId == null) return;

    try {
      final messageDoc = await _firestore.collection('messages').doc(messageId).get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      
      // Check if user is authorized to delete the message
      if (messageData['sender_id'] != currentUserId) {
        throw Exception('Unauthorized to delete this message');
      }

      await messageDoc.reference.delete();
      notifyListeners();
    } catch (error) {
      print('Error deleting message: $error');
      rethrow;
    }
  }

  // Add this method to handle job-specific conversations
  Stream<List<Conversation>> getJobConversations(String jobId) {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .where('job_id', isEqualTo: jobId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
} 