import 'dart:convert';
import 'package:chat_app/key.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/videocall_screen.dart'; // Exports AgoraVideoCallScreen
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class ChatsScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverUsername;
  final IO.Socket? socket;
  final Set<String> onlineUserIds;
  final VoidCallback? onClosed;

  const ChatsScreen({
    super.key,
    required this.socket,
    required this.senderId,
    required this.receiverId,
    required this.receiverUsername,
    required this.onlineUserIds,
    this.onClosed,
  });

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool isLoadingMore = false;
  bool _isHistoryLoaded = false;
  int currentPage = 1;
  bool _isReceiverOnline = false;
  bool _navigatingToCall = false;

  @override
  void initState() {
    super.initState();
    _isReceiverOnline = widget.onlineUserIds.contains(widget.receiverId);

    widget.socket?.on('message:received', _onSocketMessageReceived);
    widget.socket?.on('getOnlineUsers', _onOnlineUsers);

    _loadChatHistory();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoadingMore &&
          _messages.isNotEmpty) {
        _loadMoreMessages();
      }
    });
  }

  void _startVideoCall() {
    if (_navigatingToCall || !mounted) return;
    setState(() => _navigatingToCall = true);

    final ts = DateTime.now().millisecondsSinceEpoch.toString().substring(4);
    final id1 = widget.senderId.substring(0, 8);
    final id2 = widget.receiverId.substring(0, 8);
    final callId = 'call_${id1}_${id2}_$ts';

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => AgoraVideoCallScreen(
          callId: callId,
          currentUserId: widget.senderId,
          currentUserName: 'Client',
          targetUserId: widget.receiverId,
          targetUserName: widget.receiverUsername,
        ),
      ),
    )
        .whenComplete(() {
      if (mounted) setState(() => _navigatingToCall = false);
    });
  }

  void _onSocketMessageReceived(dynamic data) {
    try {
      final String incomingSenderId =
          data['senderId'] is Map ? data['senderId']['_id'] : data['senderId'].toString();
      final String incomingReceiverId =
          data['receiverId'] is Map ? data['receiverId']['_id'] : data['receiverId'].toString();

      final bool isBetweenCurrentPair =
          (incomingSenderId == widget.senderId && incomingReceiverId == widget.receiverId) ||
          (incomingSenderId == widget.receiverId && incomingReceiverId == widget.senderId);

      if (!isBetweenCurrentPair) return;

      final newMessage = {
        '_id': data['_id'],
        'text': data['text'] ?? '',
        'senderId': incomingSenderId,
        'createdAt': DateTime.parse(data['createdAt']).toLocal(),
        'status': 'received',
      };

      setState(() {
        _messages.insert(0, newMessage);
        _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
      });

      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      // ignore malformed event
    }
  }

  void _onOnlineUsers(dynamic data) {
    if (!mounted) return;
    final Set<String> onlineUsers = Set<String>.from(data);
    setState(() {
      _isReceiverOnline = onlineUsers.contains(widget.receiverId);
    });
  }

  Future<void> _loadChatHistory() async {
    if (!_isHistoryLoaded) {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse("$BACKEND_URL/api/messages/${widget.receiverId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> fetchedMessages = data.map((msg) {
          return {
            '_id': msg['_id'],
            'text': msg['text'] ?? '',
            'senderId': msg['senderId'] is Map ? msg['senderId']['_id'] : msg['senderId'],
            'createdAt': DateTime.parse(msg['createdAt']).toLocal(),
            'status': 'sent',
          };
        }).toList();

        if (fetchedMessages.isEmpty && currentPage > 1) {
          return;
        }

        if (!_isHistoryLoaded) {
          setState(() {
            _messages.addAll(fetchedMessages.reversed);
            _isHistoryLoaded = true;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_scrollController.hasClients && _messages.isNotEmpty) {
              _scrollController.jumpTo(0.0);
            }
          });
        } else {
          final int oldLength = _messages.length;
          setState(() {
            _messages.addAll(fetchedMessages.reversed);
          });
          for (int i = 0; i < fetchedMessages.length; i++) {
            _listKey.currentState?.insertItem(
              oldLength + i,
              duration: const Duration(milliseconds: 300),
            );
          }
        }
      }
    } catch (_) {
      // swallow network errors for UX
    } finally {
      if (!mounted) return;
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (isLoadingMore) return;
    setState(() {
      isLoadingMore = true;
    });

    currentPage++;
    await _loadChatHistory();
  }

  void _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty) return;

    final optimisticMessage = {
      'text': messageText,
      'senderId': widget.senderId,
      'createdAt': DateTime.now().toLocal(),
      'status': 'sending',
    };

    setState(() {
      _messages.insert(0, optimisticMessage);
      _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
    });

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final token = await _storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('$BACKEND_URL/api/messages/send/${widget.receiverId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': messageText}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          final index = _messages.indexWhere((msg) => msg['status'] == 'sending');
          if (index != -1) {
            _messages[index] = {
              '_id': data['_id'],
              'text': data['text'],
              'senderId': data['senderId'] is Map ? data['senderId']['_id'] : data['senderId'],
              'createdAt': DateTime.parse(data['createdAt']).toLocal(),
              'status': 'sent',
            };
          }
        });
      } else {
        setState(() {
          _messages.removeWhere((msg) => msg['status'] == 'sending');
        });
      }
    } catch (_) {
      setState(() {
        _messages.removeWhere((msg) => msg['status'] == 'sending');
      });
    }
  }

  @override
  void dispose() {
    widget.socket?.off('message:received', _onSocketMessageReceived);
    widget.socket?.off('getOnlineUsers', _onOnlineUsers);
    _scrollController.dispose();
    _controller.dispose();
    widget.onClosed?.call();
    super.dispose();
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return const Icon(Icons.access_time, size: 12, color: Colors.white70);
      case 'sent':
        return const Icon(Icons.done, size: 12, color: Colors.white70);
      case 'read':
        return const Icon(Icons.done_all, size: 12, color: Colors.white);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF412ad5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                if (_isReceiverOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.receiverUsername,
                  style: const TextStyle(
                    color: Color(0xFF412ad5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isReceiverOnline ? 'Online' : 'Offline',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFF412ad5)),
            onPressed: _startVideoCall,
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!_isHistoryLoaded && _messages.isEmpty)
            const LinearProgressIndicator(
              color: Color(0xFF412ad5),
              backgroundColor: Color(0xFFE8E8E8),
            )
          else if (_isHistoryLoaded && _messages.isEmpty && !isLoadingMore)
            const Expanded(
              child: Center(
                child: Text(
                  'Start a new conversation!',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            )
          else
            Expanded(
              child: AnimatedList(
                key: _listKey,
                reverse: true,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                initialItemCount: _messages.length,
                itemBuilder: (context, index, animation) {
                  if (isLoadingMore && index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF412ad5)),
                      ),
                    );
                  }

                  final message = _messages[index];
                  final isSentByMe = message['senderId'] == widget.senderId;
                  final String messageStatus = message['status'] ?? 'sent';

                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment:
                            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isSentByMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, color: Colors.black54, size: 20),
                              ),
                            ),
                          if (isSentByMe) const Spacer(),
                          Flexible(
                            flex: 0,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSentByMe ? const Color(0xFF412ad5) : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      isSentByMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight:
                                      isSentByMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['text'] ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isSentByMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('hh:mm a').format(message['createdAt']),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSentByMe ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                      if (isSentByMe)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: _getStatusIcon(messageStatus),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isSentByMe) const Spacer(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: const Color(0xFFE8E8E8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF412ad5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
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
