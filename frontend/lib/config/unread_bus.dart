import 'package:flutter/foundation.dart';

class UnreadBus {
  // Total unread for the Chats tab badge.
  static final ValueNotifier<int> chats = ValueNotifier<int>(0);

  // Helper to set safely.
  static void setChats(int value) {
    chats.value = value < 0 ? 0 : value;
  }
}