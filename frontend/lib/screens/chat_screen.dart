import 'dart:convert';
import 'package:chat_app/key.dart';
import 'package:chat_app/screens/chats_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/config/unread_bus.dart';
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
  Set<String> _onlineUserIds = {};

  // NEW: unread tracking
  final Map<String, int> _unreadByUser = {};
  String? _activeChatUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
    searchController.addListener(_filterUsers);
  }

  Future<void> _initialize() async {
    await _loadUserToken();
    if (_userToken != null) {
      await _restoreUnreadFromDisk();
      _connectSocket();
      await _fetchUsers('');
    }
  }

  Future<void> _restoreUnreadFromDisk() async {
    try {
      final raw = await _storage.read(key: 'unreadByUser');
      if (raw == null) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      _unreadByUser.clear();
      decoded.forEach((k, v) {
        if (v is int) _unreadByUser[k] = v;
      });
      _publishUnreadTotal();
      setState(() {});
    } catch (_) {/* ignore */}
  }

  Future<void> _persistUnreadToDisk() async {
    try {
      await _storage.write(key: 'unreadByUser', value: jsonEncode(_unreadByUser));
    } catch (_) {/* ignore */}
  }

  void _publishUnreadTotal() {
    final total = _unreadByUser.values.fold<int>(0, (a, b) => a + b);
    UnreadBus.setChats(total);
  }

  Future<void> _loadUserToken() async {
    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }
    setState(() {
      _userToken = token;
      _currentUserId = _decodeToken(token)['userId'];
    });
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return json.decode(payload);
  }

  Future<void> _fetchUsers(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/messages/users'),
        headers: {
          'Authorization': 'Bearer $_userToken',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final List users = json.decode(response.body);
        final List otherUsers = users.where((user) => user['_id'] != _currentUserId).toList();

        setState(() {
          userList = otherUsers.cast<Map<String, dynamic>>();
          _filterUsers();
        });

        await _fetchLatestMessages();
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to load users: ${response.statusCode}',
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error fetching users: $e',
        gravity: ToastGravity.BOTTOM,
      );
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
          Uri.parse('$BACKEND_URL/api/messages/${user['_id']}'),
          headers: {
            'Authorization': 'Bearer $_userToken',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          final List messages = json.decode(response.body);
          if (messages.isNotEmpty) {
            final latestMessage = messages.last;
            setState(() {
              user['latestMessage'] = latestMessage['text'] ?? 'No messages yet';
              user['timestamp'] = latestMessage['createdAt'];
            });
          }
        }
      }
      _sortConversations();
      setState(() {});
    } catch (_) {/* ignore */}
  }

  void _sortConversations() {
    // Sort by timestamp (most recent first)
    filteredList.sort((a, b) {
      final aTime = a['timestamp'];
      final bTime = b['timestamp'];
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
    });
    
    // Also sort userList to maintain consistency
    userList.sort((a, b) {
      final aTime = a['timestamp'];
      final bTime = b['timestamp'];
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
    });
  }

  void _connectSocket() {
    socket = IO.io(
      BACKEND_URL,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _userToken})
          .disableAutoConnect()
          .build(),
    );

    socket?.connect();

    socket?.onConnect((_) {
      // connected
    });

    socket?.onDisconnect((_) {});

    socket?.on('connect_error', (data) {});

    socket?.onError((data) {});

    socket?.on('getOnlineUsers', (data) {
      if (mounted) {
        setState(() {
          _onlineUserIds = Set<String>.from(data);
        });
      }
    });

    // NEW: Handle incoming messages in real-time
    socket?.on('message:received', (data) {
      try {
        final String incomingSenderId =
            data['senderId'] is Map ? data['senderId']['_id'] : data['senderId'].toString();
        final String incomingReceiverId =
            data['receiverId'] is Map ? data['receiverId']['_id'] : data['receiverId'].toString();

        // Determine the other participant relative to current user
        final String otherId =
            incomingSenderId == _currentUserId ? incomingReceiverId : incomingSenderId;

        // Update the user's latest message and timestamp
        final userIndex = userList.indexWhere((user) => user['_id'] == otherId);
        if (userIndex != -1) {
          setState(() {
            userList[userIndex]['latestMessage'] = data['text'] ?? 'No messages yet';
            userList[userIndex]['timestamp'] = data['createdAt'];
            
            // If not currently viewing this chat, increment unread
            if (otherId != _activeChatUserId && otherId != _currentUserId) {
              _unreadByUser[otherId] = (_unreadByUser[otherId] ?? 0) + 1;
              _publishUnreadTotal();
              _persistUnreadToDisk();
            }
            
            // Re-filter and sort to move this conversation to the top
            _filterUsers();
            _sortConversations();
          });
        }
      } catch (_) {/* ignore */}
    });
  }

  void _filterUsers() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      filteredList = userList.where((user) {
        final email = user['email']?.toString().toLowerCase() ?? '';
        final name = user['fullName']?.toString().toLowerCase() ?? '';
        return email.contains(query) || name.contains(query);
      }).toList();
    });
  }

  void _startChat(String receiverId, String receiverFullName) {
    // Reset unread for this peer and mark as active
    setState(() {
      _activeChatUserId = receiverId;
      _unreadByUser[receiverId] = 0;
      _publishUnreadTotal();
    });
    _persistUnreadToDisk();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatsScreen(
          senderId: _currentUserId!,
          receiverId: receiverId,
          receiverUsername: receiverFullName,
          socket: socket,
          onlineUserIds: _onlineUserIds,
          onClosed: () {
            // Clear active chat; future messages count as unread again
            setState(() {
              _activeChatUserId = null;
            });
          },
        ),
      ),
    );
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
    socket?.off('getOnlineUsers');
    socket?.off('message:received');
    socket?.disconnect();
    searchController.removeListener(_filterUsers);
    searchController.dispose();
    super.dispose();
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String fullName = user['fullName'] ?? 'Unknown User';
    final String userId = user['_id'] ?? '';
    final bool isOnline = _onlineUserIds.contains(userId);
    final int unread = _unreadByUser[userId] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 0.3, horizontal: 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fullName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black87),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user['timestamp'] != null)
              Text(
                _formatTimeStamp(user['timestamp']),
                style: const TextStyle(color: Colors.black87, fontSize: 12),
              ),
            if (unread > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
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
                            style: TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) =>
                              _buildUserCard(filteredList[index]),
                        ),
                ),
        ],
      ),
    );
  }
}