import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/message_model.dart';

class MessagingNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Singleton pattern
  static final MessagingNotificationService _instance = MessagingNotificationService._internal();
  
  factory MessagingNotificationService() {
    return _instance;
  }
  
  MessagingNotificationService._internal();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize the plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        if (payload != null) {
          // Handle notification tap
          debugPrint('Notification payload: $payload');
          // Navigate to specific chat screen based on payload
        }
      },
    );
    
    _isInitialized = true;
  }
  
  Future<void> showMessageNotification(Message message, String senderName) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Define notification details
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'messaging_channel',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    IOSNotificationDetails iOSPlatformChannelSpecifics =
        IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Show notification
    await _notificationsPlugin.show(
      message.hashCode,
      senderName,
      message.messageType == 'text'
          ? message.content
          : message.messageType == 'image'
              ? 'Sent you an image'
              : 'Sent you a file',
      platformChannelSpecifics,
      payload: message.id,
    );
  }
  
  // Method to handle incoming messages and determine if notification should be shown
  void handleNewMessage(Message message, String senderName, bool isAppInForeground) {
    // Only show notification if app is not in foreground
    if (!isAppInForeground) {
      showMessageNotification(message, senderName);
    }
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
