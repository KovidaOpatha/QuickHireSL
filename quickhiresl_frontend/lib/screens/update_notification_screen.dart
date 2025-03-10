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

class NotificationsPage extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'logo': 'https://upload.wikimedia.org/wikipedia/en/3/3f/Softlogic_Glomark_logo.png',
      'title': 'Keells Super cashier'
    },
    {
      'logo': 'https://seeklogo.com/images/K/keells-logo-92CC5B47D8-seeklogo.com.png',
      'title': 'Keells Super cashier'
    },
    {
      'logo': 'https://upload.wikimedia.org/wikipedia/en/3/3f/Softlogic_Glomark_logo.png',
      'title': 'Keells Super cashier'
    },
    {
      'logo': 'https://seeklogo.com/images/K/keells-logo-92CC5B47D8-seeklogo.com.png',
      'title': 'Keells Super cashier'
    },
    {
      'logo': 'https://upload.wikimedia.org/wikipedia/en/3/3f/Softlogic_Glomark_logo.png',
      'title': 'Keells Super cashier'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C2F38), // Dark background color
      appBar: AppBar(
        backgroundColor: Color(0xFF2C2F38),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Add back navigation
          },
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
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return NotificationCard(
            logoUrl: notifications[index]['logo']!,
            title: notifications[index]['title']!,
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String logoUrl;
  final String title;

  NotificationCard({
    required this.logoUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        contentPadding: EdgeInsets.all(16),
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
          ),
        ),
        onTap: () {
          // Action on tap
        },
      ),
    );
  }
}