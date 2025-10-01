import 'dart:convert';

import 'package:chat_app/key.dart';
import 'package:chat_app/screens/chats_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  IO.Socket? socket;
  String? _userToken;
  String? _currentUserId;
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> filteredList = [];
  final TextEditingController searchController = TextEditingController();
  bool _isLoading = false;
  Set<String> _onlineUserIds = {}; // Set to store IDs of online users

  @override
  void initState() {
    super.initState();
    _initialize();
    searchController.addListener(_filterUsers);
  }

  Future<void> _initialize() async {
    await _loadUserToken();
    if (_userToken != null) {
      _connectSocket();
      await _fetchUsers('');
    }
  }

  Future<void> _loadUserToken() async {
    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
      return;
    }
    setState(() {
      _userToken = token;
      _currentUserId = _decodeToken(token)['id'];
    });
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return json.decode(payload);
  }

  Future<void> _fetchUsers(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$BACKEND_URL/api/users'),
          headers: {
            'Authorization': 'Bearer $_userToken',
            'Content-Type': 'application/json'
          });
      if (response.statusCode == 200) {
        final List users = json.decode(response.body);
        final List otherUsers =
            users.where((user) => user['_id'] != _currentUserId).toList();
        setState(() {
          userList = otherUsers.cast<Map<String, dynamic>>();
          _filterUsers();
        });
        await _fetchLatestMessages();
      } else {
        Fluttertoast.showToast(
            msg: 'Failed to load users: ${response.statusCode}',
            gravity: ToastGravity.BOTTOM);
        print(
            'Failed to load users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error fetching users: $e', gravity: ToastGravity.BOTTOM);
      print('Error fetching users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLatestMessages() async {
    if (filteredList.isEmpty || _currentUserId == null) return;

    try {
      for (var user in filteredList) {
        final response = await http.get(
            Uri.parse(
                '$BACKEND_URL/api/messages/$_currentUserId/${user['_id']}/latest'),
            headers: {
              'Authorization': 'Bearer $_userToken',
              'Content-Type': 'application/json'
            });

        if (response.statusCode == 200) {
          final dynamic latestMessageData = json.decode(response.body);
          setState(() {
            user['latestMessage'] = latestMessageData != null
                ? latestMessageData['text']
                : 'No messages yet';
            user['timestamp'] = latestMessageData != null
                ? latestMessageData['createdAt']
                : null;
          });
        }
      }
      setState(() {});
    } catch (e) {
      print('Error fetching latest message $e');
    }
  }

  void _connectSocket() {
    socket = IO.io(
        BACKEND_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());

    socket?.connect();

    socket?.onConnect((_) {
      print('Connected to socket server');
      if (_currentUserId != null) {
        socket?.emit('joinRoom', _currentUserId);
        print('Emitted joinRoom for user: $_currentUserId');
      }
    });

    socket?.onDisconnect((_) => print('Disconnected from socket server'));
    socket?.on('connect_error', (data) => print('Connect error: $data'));
    socket?.onError((data) => print('Socket error: $data'));

    socket?.on('initialOnlineUsers', (data) {
      if (mounted) {
        setState(() {
          _onlineUserIds = Set<String>.from(data);
          print('Initial online users: $_onlineUserIds');
        });
      }
    });

    socket?.on('userOnline', (userId) {
      if (mounted) {
        setState(() {
          _onlineUserIds.add(userId);
          print('User online: $userId');
        });
      }
    });

    socket?.on('userOffline', (userId) {
      if (mounted) {
        setState(() {
          _onlineUserIds.remove(userId);
          print('User offline: $userId');
        });
      }
    });
  }

  void _filterUsers() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      filteredList = userList
          .where(
            (user) =>
                user['email'].toString().toLowerCase().contains(query) ||
                user['fullName'].toString().toLowerCase().contains(query),
          )
          .toList();
    });
  }

  void _startChat(String receiverId, String receiverFullName) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatsScreen(
                  senderId: _currentUserId!,
                  receiverId: receiverId,
                  receiverUsername: receiverFullName,
                  socket: socket,
                  onlineUserIds:
                      _onlineUserIds, // <-- NEW: Pass the set of online user IDs
                )));
  }

  String _formatTimeStamp(String? timestamp) {
    if (timestamp == null) return '';
    final dateUtc = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now().toLocal();
    final difference = now.difference(dateUtc);

    if (difference.inDays > 7) return DateFormat('MM/dd/yyyy').format(dateUtc);
    if (difference.inDays >= 1) return '${difference.inDays}d ago';
    if (difference.inHours >= 1) return '${difference.inHours}h ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void dispose() {
    socket?.off('initialOnlineUsers');
    socket?.off('userOnline');
    socket?.off('userOffline');
    socket?.disconnect();
    searchController.removeListener(_filterUsers);
    searchController.dispose();
    super.dispose();
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String fullName = user['fullName'] ?? 'Unknown User';
    final String userId = user['_id'] ?? '';
    final bool isOnline = _onlineUserIds.contains(userId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 0.3, horizontal: 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        title: Row(
          children: [
            Text(
              fullName,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        subtitle: Text(
          user['latestMessage'] ?? 'Tap to chat',
          style: const TextStyle(color: Colors.black87),
        ),
        trailing: user['timestamp'] != null
            ? Text(
                _formatTimeStamp(user['timestamp']),
                style: const TextStyle(color: Colors.black87, fontSize: 12),
              )
            : null,
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => _startChat(userId, fullName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: SizedBox(
              height: 40.0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.2),
                    border: InputBorder.none,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 20.0,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 45),
                  ),
                  style: const TextStyle(fontSize: 14.0),
                ),
              ),
            ),
          ),
          _isLoading
              ? const LinearProgressIndicator()
              : Expanded(
                  child: filteredList.isEmpty
                      ? const Center(
                          child: Text(
                            'No user found',
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) =>
                              _buildUserCard(filteredList[index]),
                        ))
        ],
      ),
    );
  }
}
