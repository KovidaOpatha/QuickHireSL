import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';
import '../services/user_service.dart';
import '../models/direct_message.dart';
import '../services/direct_message_service.dart';

class DirectMessageScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final String? jobId;
  final String jobTitle;

  const DirectMessageScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    this.jobId,
    required this.jobTitle,
  }) : super(key: key);

  @override
  _DirectMessageScreenState createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _storage = FlutterSecureStorage();
  final UserService _userService = UserService();
  final DirectMessageService _directMessageService = DirectMessageService();
  
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  Timer? _messageTimer;
  String? userId;
  String? userName;
  String? userAvatar;
  String? _successfulEndpoint; // Track which endpoint works
  bool _usingServiceAPI = false; // Track if we're using the service

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchMessages();
    // Poll for new messages every 5 seconds
    _messageTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) _fetchMessages();
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    userId = await _storage.read(key: 'user_id');
    userName = await _storage.read(key: 'user_name');

    // Try to load user profile to get avatar
    try {
      final userProfileResult = await _userService.getUserProfile();
      if (userProfileResult['success'] && userProfileResult['data'] != null) {
        userAvatar = userProfileResult['data']['profileImage'];
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _fetchMessages() async {
    try {
      // First try using the DirectMessageService
      try {
        final token = await _storage.read(key: 'jwt_token');
        if (token == null || userId == null) {
          setState(() => isLoading = false);
          return;
        }
        
        List<DirectMessage> serviceMessages = await _directMessageService.getMessages(
          widget.receiverId,
          jobId: widget.jobId
        );
        
        if (serviceMessages.isNotEmpty || _usingServiceAPI) {
          _usingServiceAPI = true;
          setState(() {
            messages = serviceMessages.map((dm) => dm.toJson()).toList();
            isLoading = false;
          });
          
          if (messages.isNotEmpty) {
            _scrollToBottom();
          }
          return;
        }
      } catch (serviceError) {
        print('Error using DirectMessageService: $serviceError');
        // Fall back to old implementation
      }
      
      // If service failed or returned empty, continue with existing implementation
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || userId == null) {
        setState(() => isLoading = false);
        return;
      }

      // If we have a jobId, use a job-specific direct message endpoint
      if (widget.jobId != null) {
        try {
          final jobDirectMessageEndpoint = '${Config.apiUrl}/messages/job/${widget.jobId}/${widget.receiverId}';
          final response = await http.get(
            Uri.parse(jobDirectMessageEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          print('Trying job-specific direct message endpoint: $jobDirectMessageEndpoint, status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (mounted) {
              List<Map<String, dynamic>> messagesList = [];
              
              // Handle different response formats
              if (data is List) {
                messagesList = List<Map<String, dynamic>>.from(data);
              } else if (data is Map && data.containsKey('messages')) {
                messagesList = List<Map<String, dynamic>>.from(data['messages'] ?? []);
              } else if (data is Map && data.containsKey('result')) {
                var result = data['result'];
                if (result is List) {
                  messagesList = List<Map<String, dynamic>>.from(result);
                } else if (result is Map && result.containsKey('messages')) {
                  messagesList = List<Map<String, dynamic>>.from(result['messages'] ?? []);
                }
              }
              
              setState(() {
                messages = messagesList;
                isLoading = false;
              });
              
              _successfulEndpoint = jobDirectMessageEndpoint;
              
              // Scroll to bottom after messages are loaded
              if (messages.isNotEmpty) {
                _scrollToBottom();
              }
            }
            return;
          }
        } catch (e) {
          print('Error fetching job-specific direct messages: $e');
          // Continue with regular user-based messages as fallback
        }
      }

      // If we already know a successful endpoint, use only that one
      if (_successfulEndpoint != null) {
        try {
          final response = await http.get(
            Uri.parse(_successfulEndpoint!),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (mounted) {
              List<Map<String, dynamic>> messagesList = [];
              
              // Handle different response formats
              if (data is List) {
                messagesList = List<Map<String, dynamic>>.from(data);
              } else if (data is Map && data.containsKey('messages')) {
                messagesList = List<Map<String, dynamic>>.from(data['messages'] ?? []);
              } else if (data is Map && data.containsKey('result')) {
                var result = data['result'];
                if (result is List) {
                  messagesList = List<Map<String, dynamic>>.from(result);
                } else if (result is Map && result.containsKey('messages')) {
                  messagesList = List<Map<String, dynamic>>.from(result['messages'] ?? []);
                }
              }
              
              // Filter messages by jobId if it's provided
              if (widget.jobId != null) {
                messagesList = messagesList.where((msg) => 
                  msg['jobId'] == widget.jobId
                ).toList();
              }
              
              setState(() {
                messages = messagesList;
                isLoading = false;
              });
              
              // Scroll to bottom after messages are loaded
              if (messages.isNotEmpty) {
                _scrollToBottom();
              }
            }
            return;
          }
        } catch (e) {
          print('Error with known endpoint $_successfulEndpoint: $e');
          // If the known endpoint fails, reset it and try all endpoints
          _successfulEndpoint = null;
        }
      }

      // Try direct message endpoints
      final List<String> possibleEndpoints = [
        '${Config.apiUrl}/messages/${widget.receiverId}',
        '${Config.apiUrl}/messages/direct/${widget.receiverId}',
        '${Config.apiUrl}/messages/conversation/${widget.receiverId}'
      ];
      
      http.Response? successfulResponse;
      String usedEndpoint = '';
      
      // Try each endpoint until we get a success
      for (String endpoint in possibleEndpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          print('Trying endpoint: $endpoint, status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            successfulResponse = response;
            usedEndpoint = endpoint;
            // Remember the successful endpoint for future use
            _successfulEndpoint = endpoint;
            break;
          }
        } catch (innerError) {
          print('Error with endpoint $endpoint: $innerError');
          // Continue to next endpoint
        }
      }
      
      if (successfulResponse != null) {
        print('Successfully fetched messages using endpoint: $usedEndpoint');
        final data = jsonDecode(successfulResponse.body);
        if (mounted) {
          List<Map<String, dynamic>> messagesList = [];
          
          // Handle different response formats
          if (data is List) {
            // Direct list of messages
            messagesList = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data.containsKey('messages')) {
            // Messages wrapped in an object
            messagesList = List<Map<String, dynamic>>.from(data['messages'] ?? []);
          } else if (data is Map && data.containsKey('result')) {
            // Another possible format
            var result = data['result'];
            if (result is List) {
              messagesList = List<Map<String, dynamic>>.from(result);
            } else if (result is Map && result.containsKey('messages')) {
              messagesList = List<Map<String, dynamic>>.from(result['messages'] ?? []);
            }
          }
          
          // Filter messages by jobId if it's provided
          if (widget.jobId != null) {
            messagesList = messagesList.where((msg) => 
              msg['jobId'] == widget.jobId
            ).toList();
          }
          
          setState(() {
            messages = messagesList;
            isLoading = false;
          });
          
          // Scroll to bottom after messages are loaded
          if (messages.isNotEmpty) {
            _scrollToBottom();
          }
        }
      } else {
        // If all attempts failed, show empty conversation
        print('No existing messages found after trying multiple endpoints - starting new conversation');
        if (mounted) {
          setState(() {
            messages = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Exception fetching messages: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || userId == null) return;

    try {
      // Create a temporary message to show immediately in the UI
      final String currentTime = DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now());
      final Map<String, dynamic> tempMessage = {
        "content": content,
        "sender": {
          "_id": userId!,
          "name": userName ?? "You",
          "avatar": userAvatar ?? "assets/avatar.png",
        },
        "receiver": {
          "_id": widget.receiverId,
          "name": widget.receiverName,
          "avatar": widget.receiverAvatar ?? "assets/avatar.png",
        },
        "jobId": widget.jobId,
        "timestamp": currentTime,
        "isRead": false,
        "messageType": "direct"
      };

      // Add temporary message to UI and clear input field for immediate feedback
      setState(() {
        messages.add(tempMessage);
      });
      _messageController.clear();
      _scrollToBottom();

      // First try using the DirectMessageService if we're using it
      if (_usingServiceAPI) {
        try {
          final message = await _directMessageService.sendMessage(
            receiverId: widget.receiverId,
            content: content,
            jobId: widget.jobId,
            jobTitle: widget.jobTitle,
          );

          setState(() {
            if (messages.isNotEmpty) {
              messages.removeLast(); // Remove temp message
            }
            messages.add(message.toJson());
          });
          
          _fetchMessages(); // Refresh to ensure we have latest state
          return; // Exit early - message was sent successfully
        } catch (serviceError) {
          print('Error sending message via service: $serviceError');
          // Fall back to old implementation
          setState(() {
            if (messages.isNotEmpty) {
              messages.removeLast(); // Remove the temporary message if it failed
            }
          });
        }
      }

      // Proceed with existing implementation if service approach failed
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      // Data format for sending message
      final Map<String, dynamic> messageData = {
        "content": content,
        "receiverId": widget.receiverId,
        "jobId": widget.jobId,
        "jobTitle": widget.jobTitle,
        "messageType": "direct"
      };

      // Track if any attempt was successful
      bool sendSuccess = false;
      String lastErrorMessage = "Failed to send message";
      
      // Determine the best endpoint to use
      String endpointToUse = '${Config.apiUrl}/messages'; // Default endpoint
      
      // Use the known successful endpoint if available
      if (_successfulEndpoint != null && _successfulEndpoint!.contains('/messages/')) {
        // If we have a successful endpoint for fetching, extract the base path for sending
        // Example: /messages/userId -> /messages
        final endpointParts = _successfulEndpoint!.split('/');
        if (endpointParts.length >= 3) {
          endpointToUse = '${Config.apiUrl}/${endpointParts[1]}'; // Use the messages part
        }
      }
      
      // Send the message to the chosen endpoint
      try {
        final response = await http.post(
          Uri.parse(endpointToUse),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(messageData),
        );
        
        print("Sending message to endpoint $endpointToUse: ${response.statusCode}");
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          final newMessage = jsonDecode(response.body);
          setState(() {
            if (messages.isNotEmpty) {
              messages.removeLast(); // Remove temp message
            }
            messages.add(newMessage);
          });
          
          sendSuccess = true;
          print("Message sent successfully to $endpointToUse");
        } else {
          lastErrorMessage = "Error sending to $endpointToUse: ${response.statusCode}";
          print(lastErrorMessage);
          print("Response body: ${response.body}");
          
          // Only if the main endpoint fails, try one fallback endpoint
          if (!sendSuccess) {
            final fallbackEndpoint = '${Config.apiUrl}/messages/direct';
            
            try {
              final fallbackResponse = await http.post(
                Uri.parse(fallbackEndpoint),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(messageData),
              );
              
              print("Trying fallback endpoint $fallbackEndpoint: ${fallbackResponse.statusCode}");
              
              if (fallbackResponse.statusCode == 201 || fallbackResponse.statusCode == 200) {
                final newMessage = jsonDecode(fallbackResponse.body);
                setState(() {
                  if (messages.isNotEmpty) {
                    messages.removeLast(); // Remove temp message
                  }
                  messages.add(newMessage);
                });
                
                sendSuccess = true;
                print("Message sent successfully to fallback endpoint $fallbackEndpoint");
              } else {
                lastErrorMessage = "Error sending to fallback endpoint: ${fallbackResponse.statusCode}";
                print(lastErrorMessage);
              }
            } catch (e) {
              print("Error with fallback endpoint: $e");
            }
          }
        }
      } catch (e) {
        print("Error with primary endpoint $endpointToUse: $e");
        
        // Try fallback if primary fails with exception
        final fallbackEndpoint = '${Config.apiUrl}/messages/direct';
        
        try {
          final fallbackResponse = await http.post(
            Uri.parse(fallbackEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(messageData),
          );
          
          print("Trying fallback after exception: $fallbackEndpoint: ${fallbackResponse.statusCode}");
          
          if (fallbackResponse.statusCode == 201 || fallbackResponse.statusCode == 200) {
            final newMessage = jsonDecode(fallbackResponse.body);
            setState(() {
              if (messages.isNotEmpty) {
                messages.removeLast();
              }
              messages.add(newMessage);
            });
            
            sendSuccess = true;
            print("Message sent successfully to fallback endpoint");
          }
        } catch (fallbackError) {
          print("Error with fallback endpoint: $fallbackError");
        }
      }
      
      // Handle failure if no endpoint worked
      if (!sendSuccess) {
        setState(() {
          if (messages.isNotEmpty) {
            messages.removeLast(); // Remove the temporary message
          }
        });
        
        // Force refresh messages to ensure we're showing the latest state
        _fetchMessages();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lastErrorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Make sure we have the latest messages after successful send
        _fetchMessages();
      }
    } catch (e) {
      // Remove the temporary message if there was an error
      setState(() {
        if (messages.isNotEmpty) {
          messages.removeLast();
        }
      });

      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.receiverAvatar != null)
              CircleAvatar(
                backgroundImage: NetworkImage(widget.receiverAvatar!),
                radius: 20,
                backgroundColor: Colors.grey[200],
                onBackgroundImageError: (_, __) {
                  // Fallback if image fails to load
                },
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                child: Text(widget.receiverName[0].toUpperCase()),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.jobTitle,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          
                          // Handle different message formats
                          bool isMe = false;
                          String messageContent = '';
                          DateTime timestamp = DateTime.now();
                          String avatarUrl = '';
                          
                          // Check if using sender object format
                          if (message.containsKey('sender') && message['sender'] is Map) {
                            final sender = message['sender'] as Map<String, dynamic>;
                            isMe = sender['_id'] == userId;
                            messageContent = message['content'] ?? '';
                            avatarUrl = isMe ? (userAvatar ?? '') : (widget.receiverAvatar ?? '');
                            if (isMe && userAvatar != null) {
                              avatarUrl = _userService.getFullImageUrl(userAvatar!);
                            }
                            if (message.containsKey('timestamp')) {
                              timestamp = DateTime.parse(message['timestamp']).toLocal();
                            }
                          } 
                          // Check if using senderId format
                          else if (message.containsKey('senderId')) {
                            isMe = message['senderId'] == userId;
                            messageContent = message['content'] ?? '';
                            avatarUrl = isMe ? (userAvatar ?? '') : (widget.receiverAvatar ?? '');
                            if (isMe && userAvatar != null) {
                              avatarUrl = _userService.getFullImageUrl(userAvatar!);
                            }
                            if (message.containsKey('timestamp')) {
                              timestamp = DateTime.parse(message['timestamp']).toLocal();
                            }
                          }
                          
                          final String formattedTime = DateFormat('h:mm a').format(timestamp);
                          final bool hasAvatar = avatarUrl.isNotEmpty && !avatarUrl.startsWith('assets/');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  hasAvatar
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(avatarUrl),
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          onBackgroundImageError: (_, __) {
                                            // Fallback if image fails to load
                                          },
                                        )
                                      : CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          child: Text(
                                            widget.receiverName[0].toUpperCase(),
                                            style: TextStyle(color: Colors.grey[800]),
                                          ),
                                        ),
                                  SizedBox(width: 8),
                                ],
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        messageContent,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMe) ...[
                                  SizedBox(width: 8),
                                  hasAvatar
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(avatarUrl),
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          onBackgroundImageError: (_, __) {
                                            // Fallback if image fails to load
                                          },
                                        )
                                      : CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          child: Icon(Icons.person, size: 16, color: Colors.grey[800]),
                                        ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
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
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        sendMessage(_messageController.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 