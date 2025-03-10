import 'package:flutter/material.dart';

void main() {
  runApp(NotificationScreen());
}

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [
    {
      'logo': 'https://upload.wikimedia.org/wikipedia/en/3/3f/Softlogic_Glomark_logo.png',
      'title': 'Keells Super cashier',
      'isFavorite': false,
      'isMuted': false,
    },
    {
      'logo': 'https://seeklogo.com/images/K/keells-logo-92CC5B47D8-seeklogo.com.png',
      'title': 'Keells Super cashier',
      'isFavorite': false,
      'isMuted': false,
    },
    {
      'logo': 'https://upload.wikimedia.org/wikipedia/en/3/3f/Softlogic_Glomark_logo.png',
      'title': 'Keells Super cashier',
      'isFavorite': false,
      'isMuted': false,
    },
    {
      'logo': 'https://seeklogo.com/images/K/keells-logo-92CC5B47D8-seeklogo.com.png',
      'title': 'Keells Super cashier',
      'isFavorite': false,
      'isMuted': false,
    },
    {
      'logo': 'https://upload.wikimedia.org/wikipedia/en/3/3f/Softlogic_Glomark_logo.png',
      'title': 'Keells Super cashier',
      'isFavorite': false,
      'isMuted': false,
    },
  ];

  void removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  void toggleFavorite(int index) {
    setState(() {
      notifications[index]['isFavorite'] = !notifications[index]['isFavorite'];
    });
  }

  void toggleMute(int index) {
    setState(() {
      notifications[index]['isMuted'] = !notifications[index]['isMuted'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C2F38),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C2F38),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: UniqueKey(),
                  onDismissed: (direction) {
                    removeNotification(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Notification deleted"),
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: NotificationCard(
                    logoUrl: notification['logo'],
                    title: notification['title'],
                    isFavorite: notification['isFavorite'],
                    isMuted: notification['isMuted'],
                    onFavoriteToggle: () => toggleFavorite(index),
                    onMuteToggle: () => toggleMute(index),
                  ),
                );
              },
            ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String logoUrl;
  final String title;
  final bool isFavorite;
  final bool isMuted;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onMuteToggle;

  NotificationCard({
    required this.logoUrl,
    required this.title,
    required this.isFavorite,
    required this.isMuted,
    required this.onFavoriteToggle,
    required this.onMuteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isMuted ? 0.5 : 1.0, // Dim card if muted
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[200],
              image: DecorationImage(
                image: NetworkImage(logoUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isMuted ? Colors.grey : Colors.black, // Grey text if muted
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Favorite button
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: onFavoriteToggle,
              ),
              // Mute/Unmute button
              IconButton(
                icon: Icon(
                  isMuted ? Icons.notifications_off : Icons.notifications_active,
                  color: isMuted ? Colors.grey : Colors.blue,
                ),
                onPressed: onMuteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}