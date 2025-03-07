import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/job.dart';

class JobChatScreen extends StatefulWidget {
  final Job job;

  JobChatScreen({required this.job});

  @override
  _JobChatScreenState createState() => _JobChatScreenState();
}

class _JobChatScreenState extends State<JobChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/jobs/${widget.job.id}/chat'),
      );
      if (response.statusCode == 200) {
        setState(() {
          messages = jsonDecode(response.body)['messages'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching messages: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/jobs/${widget.job.id}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        final newMessage = jsonDecode(response.body);
        setState(() {
          messages.add(newMessage);
        });
        _messageController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.job.title),
            Text(
              widget.job.company,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: messages.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isCurrentUser =
                          message['sender']['_id'] == 'currentUserId';

                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['sender']['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentUser
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                message['content'],
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateTime.parse(message['timestamp'])
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isCurrentUser
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () => sendMessage(_messageController.text),
                  child: Icon(Icons.send),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
