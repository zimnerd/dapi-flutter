# Dating App WebSockets Chat Integration Guide
## For Flutter Developers

This document provides a comprehensive guide for integrating your Flutter app with the Dating App WebSocket chat system. The chat functionality supports private messaging between matches, group chats, read receipts, typing indicators, and presence status.

## WebSocket API Overview

The WebSocket communication is handled via Socket.IO, providing a real-time, bidirectional channel between your Flutter app and the server.

**Base URL**: `https://dapi.pulsetek.co.za:3000` (replace with your production URL)

## 1. Required Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  socket_io_client: ^2.0.0  # For Socket.IO integration
  jwt_decoder: ^2.0.1       # For working with JWT tokens
  cached_network_image: ^3.2.0  # For displaying profile/media images
```

## 2. WebSocket Connection & Authentication

Create a `ChatService` class to manage your WebSocket connections:

```dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class ChatService {
  // Socket instance
  IO.Socket? _socket;
  
  // Stream controllers for various events
  final _newMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _groupMessageController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream getters
  Stream<Map<String, dynamic>> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onReadReceipt => _readReceiptController.stream;
  Stream<Map<String, dynamic>> get onOnlineStatus => _onlineStatusController.stream;
  Stream<Map<String, dynamic>> get onGroupMessage => _groupMessageController.stream;
  
  // User info
  String? userId;
  String? userName;
  
  // Connection status
  bool get isConnected => _socket?.connected ?? false;
  
  // Initialize socket connection
  void init(String serverUrl) {
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _setupListeners();
  }
  
  // Set up event listeners
  void _setupListeners() {
    _socket?.on('connect', (_) {
      debugPrint('Socket connected');
    });
    
    _socket?.on('disconnect', (_) {
      debugPrint('Socket disconnected');
    });
    
    _socket?.on('error', (data) {
      debugPrint('Socket error: $data');
    });
    
    // Authentication responses
    _socket?.on('auth_success', (data) {
      userId = data['userId'];
      userName = data['name'];
      debugPrint('Authentication successful. User: $userId');
    });
    
    _socket?.on('auth_failed', (data) {
      debugPrint('Authentication failed: ${data['message']}');
    });
    
    // Message events
    _socket?.on('new_message', (data) {
      _newMessageController.add(data);
    });
    
    _socket?.on('user_typing', (data) {
      _typingController.add(data);
    });
    
    _socket?.on('messages_read', (data) {
      _readReceiptController.add(data);
    });
    
    // Group chat events
    _socket?.on('new_group_message', (data) {
      _groupMessageController.add(data);
    });
    
    _socket?.on('chatroom_created', (data) {
      debugPrint('Chatroom created: ${data['id']}');
    });
    
    _socket?.on('chatroom_joined', (data) {
      debugPrint('Joined chatroom: ${data['id']}');
    });
    
    // Presence/online status
    _socket?.on('user_presence_changed', (data) {
      _onlineStatusController.add(data);
    });
    
    _socket?.on('user_online', (data) {
      _onlineStatusController.add(data);
    });
  }
  
  // Connect and authenticate with JWT
  void connect(String token) {
    _socket?.connect();
    
    // Authenticate after connection
    _socket?.on('connect', (_) {
      // Emit authenticate event with JWT token
      _socket?.emit('authenticate', {'token': token});
    });
  }
  
  // Disconnect from socket
  void disconnect() {
    _socket?.disconnect();
  }
  
  // Dispose resources
  void dispose() {
    disconnect();
    _newMessageController.close();
    _typingController.close();
    _readReceiptController.close();
    _onlineStatusController.close();
    _groupMessageController.close();
  }
  
  // MARK: - Private Messaging API

  // Send a message to a match
  void sendMessage(String matchId, String content, {String? mediaUrl}) {
    if (!isConnected) return;
    
    _socket?.emit('private_message', {
      'matchId': matchId,
      'content': content,
      'mediaUrl': mediaUrl,
    });
  }
  
  // Load conversation history
  void loadConversation(String matchId, {int limit = 50, String? before}) {
    if (!isConnected) return;
    
    _socket?.emit('load_conversation', {
      'matchId': matchId,
      'limit': limit,
      'before': before,
    });
  }
  
  // Send typing indicator
  void sendTyping(String matchId) {
    if (!isConnected) return;
    
    _socket?.emit('typing', {'matchId': matchId});
  }
  
  // Mark messages as read
  void markMessagesAsRead(List<String> messageIds) {
    if (!isConnected) return;
    
    _socket?.emit('mark_read', {'messageIds': messageIds});
  }
  
  // Get unread message counts
  void getUnreadCounts() {
    if (!isConnected) return;
    
    _socket?.emit('get_unread_counts');
  }
  
  // MARK: - Group Chat API
  
  // Create a new chatroom
  void createChatroom(String name, List<String> members) {
    if (!isConnected) return;
    
    _socket?.emit('create_chatroom', {
      'name': name,
      'members': members,
    });
  }
  
  // Join a chatroom
  void joinChatroom(String roomId) {
    if (!isConnected) return;
    
    _socket?.emit('join_chatroom', {'roomId': roomId});
  }
  
  // Leave a chatroom
  void leaveChatroom(String roomId) {
    if (!isConnected) return;
    
    _socket?.emit('leave_chatroom', {'roomId': roomId});
  }
  
  // Get all chatrooms user is a member of
  void getChatrooms() {
    if (!isConnected) return;
    
    _socket?.emit('get_chatrooms');
  }
  
  // Send message to a group chat
  void sendGroupMessage(String roomId, String content, {String? mediaUrl}) {
    if (!isConnected) return;
    
    _socket?.emit('group_message', {
      'roomId': roomId,
      'content': content,
      'mediaUrl': mediaUrl,
    });
  }
  
  // Load group chat history
  void loadGroupConversation(String roomId, {int limit = 50, String? before}) {
    if (!isConnected) return;
    
    _socket?.emit('load_group_conversation', {
      'roomId': roomId,
      'limit': limit,
      'before': before,
    });
  }
  
  // MARK: - Presence API
  
  // Update user's presence status
  void updatePresence(String status) {
    if (!isConnected) return;
    
    // Valid statuses: 'online', 'away', 'busy', 'offline'
    _socket?.emit('update_presence', {'status': status});
  }
}
```

## 3. Using the Chat Service in Your App

### Initialize in your app

```dart
// In your app initialization (e.g., main.dart or during login)
final chatService = ChatService();

void initializeChat() {
  chatService.init('https://dapi.pulsetek.co.za:3000');
  
  // Connect with JWT token after login
  final token = 'your-jwt-token';  // Get this from your auth service
  chatService.connect(token);
}
```

### Listening for Messages

```dart
class MessageListScreen extends StatefulWidget {
  final String matchId;
  
  MessageListScreen({required this.matchId});
  
  @override
  _MessageListScreenState createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  final List<Message> messages = [];
  StreamSubscription? _messageSub;
  StreamSubscription? _typingSub;
  
  @override
  void initState() {
    super.initState();
    
    // Load conversation history
    chatService.loadConversation(widget.matchId);
    
    // Listen for new messages
    _messageSub = chatService.onNewMessage.listen((data) {
      if (data['match_id'] == widget.matchId) {
        setState(() {
          messages.add(Message.fromJson(data));
        });
      }
    });
    
    // Listen for typing indicators
    _typingSub = chatService.onTyping.listen((data) {
      if (data['matchId'] == widget.matchId) {
        // Show typing indicator
        setState(() {
          // Update UI to show that user is typing
        });
      }
    });
  }
  
  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }
  
  // UI implementation
  // ...
}
```

### Sending Messages

```dart
void _sendMessage() {
  final content = _messageController.text.trim();
  if (content.isNotEmpty) {
    chatService.sendMessage(widget.matchId, content);
    _messageController.clear();
  }
}

// For image messages
void _sendImageMessage(String imageUrl) {
  chatService.sendMessage(widget.matchId, "Sent an image", mediaUrl: imageUrl);
}
```

## 4. Group Chat Integration

### Creating a New Group Chat

```dart
void createNewGroupChat(String name, List<String> memberIds) {
  chatService.createChatroom(name, memberIds);
}
```

### Group Chat UI

```dart
class GroupChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  
  GroupChatScreen({required this.roomId, required this.roomName});
  
  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final List<GroupMessage> messages = [];
  StreamSubscription? _messageSub;
  
  @override
  void initState() {
    super.initState();
    
    // Load conversation history
    chatService.loadGroupConversation(widget.roomId);
    
    // Listen for new messages
    _messageSub = chatService.onGroupMessage.listen((data) {
      if (data['room_id'] == widget.roomId) {
        setState(() {
          messages.add(GroupMessage.fromJson(data));
        });
      }
    });
  }
  
  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }
  
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      chatService.sendGroupMessage(widget.roomId, content);
      _messageController.clear();
    }
  }
  
  // UI implementation
  // ...
}
```

## 5. Read Receipts and Message Status

```dart
// Mark messages as read when user views them
void markMessagesAsRead(List<String> messageIds) {
  chatService.markMessagesAsRead(messageIds);
}

// Show read receipts in UI
Widget buildMessageItem(Message message) {
  return ListTile(
    // Message content
    title: Text(message.content),
    
    // Read receipt indicator
    trailing: message.read 
      ? Icon(Icons.done_all, color: Colors.blue) 
      : Icon(Icons.done),
  );
}
```

## 6. Online Status and Presence

```dart
// Update user status
void updateUserStatus(String status) {
  // status can be: 'online', 'away', 'busy', 'offline'
  chatService.updatePresence(status);
}

// Display user online status
StreamBuilder<Map<String, dynamic>>(
  stream: chatService.onOnlineStatus,
  builder: (context, snapshot) {
    final isOnline = snapshot.hasData && 
                    snapshot.data?['userId'] == matchUserId &&
                    snapshot.data?['status'] == 'online';
    
    return Row(
      children: [
        CircleAvatar(
          radius: 5,
          backgroundColor: isOnline ? Colors.green : Colors.grey,
        ),
        SizedBox(width: 8),
        Text(isOnline ? 'Online' : 'Offline'),
      ],
    );
  },
)
```

## 7. Message and Chat Room Data Models

Here are some suggested data models to use with the chat system:

```dart
class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final DateTime sentAt;
  bool read;
  
  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.sentAt,
    this.read = false,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      matchId: json['match_id'],
      senderId: json['sender_id'],
      content: json['content'],
      mediaUrl: json['media_url'],
      sentAt: DateTime.parse(json['sent_at']),
      read: json['read'] ?? false,
    );
  }
  
  bool get isCurrentUser => senderId == chatService.userId;
}

class GroupMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final DateTime sentAt;
  
  GroupMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.sentAt,
  });
  
  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      content: json['content'],
      mediaUrl: json['media_url'],
      sentAt: DateTime.parse(json['sent_at']),
    );
  }
  
  bool get isCurrentUser => senderId == chatService.userId;
}

class ChatRoom {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final List<String> members;
  
  ChatRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.members,
  });
  
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      members: List<String>.from(json['members']),
    );
  }
}
```

## 8. Handling Errors and Reconnection

```dart
// Add to your ChatService class:

// Reconnection strategy
void handleReconnection() {
  _socket?.on('connect_error', (error) {
    debugPrint('Connection error: $error');
    // Try to reconnect after delay
    Future.delayed(Duration(seconds: 3), () {
      if (!isConnected) {
        debugPrint('Attempting to reconnect...');
        _socket?.connect();
      }
    });
  });
  
  _socket?.on('reconnect', (attempt) {
    debugPrint('Reconnected after $attempt attempts');
    // Re-authenticate after reconnection
    if (chatService.userId != null) {
      // Re-authenticate with stored token
      _socket?.emit('authenticate', {'token': 'your-stored-token'});
    }
  });
}

// Error handling
StreamController<String> _errorController = StreamController<String>.broadcast();
Stream<String> get onError => _errorController.stream;

// Add this to _setupListeners()
_socket?.on('error', (data) {
  String errorMessage = 'Unknown error';
  if (data is Map && data.containsKey('message')) {
    errorMessage = data['message'];
  } else if (data is String) {
    errorMessage = data;
  }
  _errorController.add(errorMessage);
  debugPrint('Socket error: $errorMessage');
});
```

## 9. Tips for Best Performance

1. **Optimize WebSocket Usage**:
   - Only connect when necessary (after login)
   - Disconnect when the app goes to background
   - Reconnect when the app comes to foreground

2. **Message Pagination**:
   - Load messages in batches (use the `limit` parameter)
   - Implement "load more" for older messages using the `before` parameter

3. **Media Handling**:
   - Use a separate HTTP endpoint to upload images/files
   - Only send URLs via WebSocket, not actual files
   - Optimize images before uploading

4. **UI Performance**:
   - Use Flutter's ListView.builder for message lists
   - Implement "lazy loading" for media attachments
   - Cache messages locally for offline access

## 10. Testing WebSocket Connection

Use this simple Flutter widget to test your WebSocket connection:

```dart
class WebSocketTester extends StatefulWidget {
  @override
  _WebSocketTesterState createState() => _WebSocketTesterState();
}

class _WebSocketTesterState extends State<WebSocketTester> {
  String _status = 'Disconnected';
  String _message = '';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize chat service
    chatService.init('https://dapi.pulsetek.co.za:3000');
    
    // Add listeners
    chatService._socket?.on('connect', (_) {
      setState(() {
        _status = 'Connected';
      });
    });
    
    chatService._socket?.on('disconnect', (_) {
      setState(() {
        _status = 'Disconnected';
      });
    });
    
    // Auth listeners
    chatService._socket?.on('auth_success', (data) {
      setState(() {
        _message = 'Authenticated as: ${data['userId']}';
      });
    });
    
    chatService._socket?.on('auth_failed', (data) {
      setState(() {
        _message = 'Auth failed: ${data['message']}';
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebSocket Tester')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text(_message, style: TextStyle(fontSize: 16)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                chatService.connect('your-jwt-token');
              },
              child: Text('Connect'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                chatService.disconnect();
              },
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 11. Debugging WebSockets

To debug WebSocket communication:

1. Enable debug logging:
```dart
IO.Socket socket = IO.io('https://dapi.pulsetek.co.za:3000', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
  'logger': true,    // Enable logging
  'debug': true,     // Enable debug output
});
```

2. Log all incoming and outgoing events:
```dart
// Log outgoing events
void emit(String event, dynamic data) {
  debugPrint('⬆️ EMIT: $event: $data');
  _socket?.emit(event, data);
}

// In _setupListeners, add a general event catcher
_socket?.onAny((event, data) {
  debugPrint('⬇️ RECEIVED: $event: $data');
});
```

For further assistance or bug reports, please contact the backend development team. 