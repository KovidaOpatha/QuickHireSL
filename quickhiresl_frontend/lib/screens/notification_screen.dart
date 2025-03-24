import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Use the notification service to get notifications instead of direct HTTP call
      final fetchedNotifications = await _notificationService.getNotifications();
      
      setState(() {
        notifications = fetchedNotifications;
        isLoading = false;
      });
      
      print('Loaded ${notifications.length} notifications');
      
      // For debugging, print the first notification if available
      if (notifications.isNotEmpty) {
        print('First notification: ${notifications[0]}');
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return DateFormat('MMM d, yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error parsing date: $e');
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.black, size: 16),
              label: const Text("Mark All Read",
                  style: TextStyle(color: Colors.black)),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF98C9C5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final bool isUnread = !(notification['read'] ?? false);
                        return Dismissible(
                          key: Key(notification['_id']),
                          onDismissed: (direction) =>
                              _markAsRead(notification['_id']),
                          background: Container(
                            color: Colors.green,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                          child: Card(
                            elevation: isUnread ? 2 : 0,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isUnread 
                                ? BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1)
                                : BorderSide.none,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                // Mark notification as read when tapped
                                if (notification['_id'] != null && notification['read'] == false) {
                                  try {
                                    await _notificationService.markAsRead(notification['_id']);
                                    // Refresh notifications after marking as read
                                    _loadNotifications();
                                  } catch (e) {
                                    print('Error marking notification as read: $e');
                                  }
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isUnread 
                                    ? Theme.of(context).primaryColor.withOpacity(0.05)
                                    : Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        _getNotificationIcon(notification['type']),
                                        color: Theme.of(context).primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification['title'] ?? 'Notification',
                                                  style: TextStyle(
                                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification['message'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getTimeAgo(notification['createdAt']),
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'application':
        return Icons.work;
      case 'message':
        return Icons.message;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }
}