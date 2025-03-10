import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class MessageDetailsScreen extends StatelessWidget {
  final Message message;
  final String senderName;
  final String? senderImageUrl;

  const MessageDetailsScreen({
    Key? key,
    required this.message,
    required this.senderName,
    this.senderImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSenderInfo(),
            SizedBox(height: 24),
            _buildMessageContent(),
            SizedBox(height: 24),
            _buildMessageMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: senderImageUrl != null
              ? NetworkImage(senderImageUrl!)
              : null,
          child: senderImageUrl == null
              ? Text(
                  senderName.isNotEmpty ? senderName[0] : '?',
                  style: TextStyle(fontSize: 24),
                )
              : null,
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sender ID: ${message.senderId}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageContent() {
    if (message.messageType == 'image' && message.attachmentUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.attachmentUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
          if (message.content.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Caption:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ],
      );
    } else if (message.messageType == 'file' && message.attachmentUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: Colors.blue,
                  size: 36,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to download',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    // Download functionality would go here
                  },
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildMessageMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        _buildDetailRow('Message ID', message.id),
        _buildDetailRow('Sent to', message.receiverId),
        _buildDetailRow(
          'Sent at',
          '${message.timestamp.toLocal().toString().split('.')[0]}',
        ),
        _buildDetailRow('Read status', message.isRead ? 'Read' : 'Unread'),
        _buildDetailRow('Message type', message.messageType),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
