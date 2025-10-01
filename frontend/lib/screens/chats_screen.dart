import 'dart:convert';
import 'package:chat_app/key.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ChatsScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverUsername;
  final IO.Socket? socket;
  final Set<String> onlineUserIds;

  const ChatsScreen({
    super.key,
    required this.socket,
    required this.senderId,
    required this.receiverId,
    required this.receiverUsername,
    required this.onlineUserIds,
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
  final Uuid uuid = const Uuid();

  bool _isReceiverOnline = false;

  @override
  void initState() {
    super.initState();
    _isReceiverOnline = widget.onlineUserIds.contains(widget.receiverId);

    widget.socket?.on('receiveMessage', (data) {
      final String incomingSenderId = data['senderId'];
      final String incomingReceiverId = data['receiverId'];
      final String? clientMessageId = data['clientMessageId'];

      if ((incomingSenderId == widget.senderId &&
              incomingReceiverId == widget.receiverId) ||
          (incomingSenderId == widget.receiverId &&
              incomingReceiverId == widget.senderId)) {
        final existingMessageIndex = _messages.indexWhere(
          (msg) =>
              msg['clientMessageId'] == clientMessageId &&
              msg['status'] == 'sending',
        );

        if (existingMessageIndex != -1) {
          setState(() {
            _messages[existingMessageIndex]['_id'] = data['_id'];
            _messages[existingMessageIndex]['createdAt'] =
                DateTime.parse(data['createdAt']).toLocal();
            _messages[existingMessageIndex]['status'] = 'sent';
          });
        } else {
          final newMessage = {
            '_id': data['_id'],
            'text': data['text'],
            'senderId': data['senderId'],
            'createdAt': DateTime.parse(data['createdAt']).toLocal(),
            'clientMessageId': clientMessageId,
            'status': 'received',
          };
          _messages.insert(0, newMessage);
          _listKey.currentState
              ?.insertItem(0, duration: const Duration(milliseconds: 300));
        }
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    widget.socket?.on('userOnline', (userId) {
      if (mounted && userId == widget.receiverId) {
        setState(() {
          _isReceiverOnline = true;
          print('Receiver ${widget.receiverUsername} is now online.');
        });
      }
    });

    widget.socket?.on('userOffline', (userId) {
      if (mounted && userId == widget.receiverId) {
        setState(() {
          _isReceiverOnline = false;
          print('Receiver ${widget.receiverUsername} is now offline.');
        });
      }
    });

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
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
        return;
      }

      final response = await http.get(
        Uri.parse(
            "$BACKEND_URL/api/messages/${widget.senderId}/${widget.receiverId}?page=$currentPage"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> fetchedMessages = data.map((msg) {
          return {
            '_id': msg['_id'],
            'text': msg['text'],
            'senderId': msg['senderId'],
            'createdAt': DateTime.parse(msg['createdAt']).toLocal(),
            'clientMessageId': msg['clientMessageId'],
            'status': 'sent',
          };
        }).toList();

        if (fetchedMessages.isEmpty && currentPage > 1) {
          return;
        }

        if (!_isHistoryLoaded) {
          _messages.addAll(fetchedMessages);
          setState(() {
            _isHistoryLoaded = true;
          });
        } else {
          final int oldLength = _messages.length;
          _messages.addAll(fetchedMessages);
          for (int i = 0; i < fetchedMessages.length; i++) {
            _listKey.currentState?.insertItem(oldLength + i,
                duration: const Duration(milliseconds: 300));
          }
        }
      } else {
        print(
            'Failed to load chat history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading chat history: $e');
    } finally {
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

  void _sendMessage() {
    final messageText = _controller.text.trim();
    if (messageText.isNotEmpty) {
      final String clientMessageId = uuid.v4();

      final optimisticMessage = {
        'text': messageText,
        'senderId': widget.senderId,
        'createdAt': DateTime.now().toLocal(),
        'clientMessageId': clientMessageId,
        'status': 'sending',
      };
      _messages.insert(0, optimisticMessage);
      _listKey.currentState
          ?.insertItem(0, duration: const Duration(milliseconds: 300));

      widget.socket?.emit('sendMessage', {
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
        'text': messageText,
        'clientMessageId': clientMessageId,
      });

      _controller.clear();
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'token');
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    widget.socket?.off('receiveMessage');
    widget.socket?.off('userOnline');
    widget.socket?.off('userOffline');
    _scrollController.dispose();
    _controller.dispose();
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.receiverUsername,
              style: const TextStyle(
                color: Color(0xFF412ad5),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isReceiverOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isHistoryLoaded == false && _messages.isEmpty)
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                initialItemCount: _messages.length,
                itemBuilder: (context, index, animation) {
                  if (isLoadingMore && index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF412ad5)),
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
                        mainAxisAlignment: isSentByMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isSentByMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person,
                                    color: Colors.black54, size: 20),
                              ),
                            ),
                          // FIX APPLIED HERE: Using Spacer() for sent messages
                          if (isSentByMe)
                            const Spacer(), // Pushes sent messages to the right
                          Flexible(
                            // Added an explicit flex value to control width
                            flex:
                                0, // This tells Flexible to only take the necessary space
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width *
                                    0.7, // Cap message bubble width
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? const Color(0xFF412ad5)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isSentByMe
                                      ? const Radius.circular(16)
                                      : const Radius.circular(4),
                                  bottomRight: isSentByMe
                                      ? const Radius.circular(4)
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isSentByMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['text'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isSentByMe
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('hh:mm a')
                                            .format(message['createdAt']),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSentByMe
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      if (isSentByMe)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 4.0),
                                          child: _getStatusIcon(messageStatus),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // FIX APPLIED HERE: Using Spacer() for received messages (after the Flexible)
                          if (!isSentByMe)
                            const Spacer(), // Pushes received messages to the left
                          // Removed the fixed SizedBox(width: 40) as Spacer() handles distribution
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
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
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
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
