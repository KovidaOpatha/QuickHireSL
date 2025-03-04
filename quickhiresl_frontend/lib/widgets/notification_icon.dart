import 'package:flutter/material.dart';

class NotificationIcon extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  final bool isLoading;

  const NotificationIcon({
    Key? key,
    required this.unreadCount,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: unreadCount > 0 ? Colors.blue : Colors.black,
            size: unreadCount > 0 ? 28 : 24, // Slightly larger when there are notifications
          ),
          onPressed: onTap,
        ),
        if (isLoading)
          const Positioned(
            right: 8,
            top: 8,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          )
        else if (unreadCount > 0)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
