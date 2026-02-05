// ignore_for_file: library_prefixes
import 'dart:developer';
import 'package:ree_social_media_app/services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;
  static final auth = ApiService();

  static void connect(String token) {
    if (_socket != null && _socket!.connected) {
      log("⚠️ Socket already connected");
      return;
    }

    _socket = IO.io(
      'https://api.resocial.site',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setQuery({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) => log("✅ Socket connected"));
    _socket!.onReconnect((_) => log("🔄 Socket reconnected"));
    _socket!.onConnectError((err) => log("🚨 Connect error: $err"));
    _socket!.onError((err) => log("🚨 Error: $err"));
    _socket!.onDisconnect((_) => log("❌ Socket disconnected"));
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    log("👋 Socket disconnected and disposed");
  }

  static bool get isConnected => _socket?.connected ?? false;

  static void onChatMessage(
    String chatId,
    void Function(dynamic data) handler,
  ) {
    if (!isConnected) {
      log("⚠️ Cannot listen to chat, socket not connected");
      return;
    }

    final eventName = "receive-message:$chatId";
    _socket?.off(eventName);
    _socket?.on(eventName, (data) {
      log("📩 Message received on $eventName => $data");
      handler(data);
    });
    log("🟢 Subscribed to $eventName");
  }

  static void onGlobalMessage(void Function(dynamic data) handler) {
    _socket?.off("receive-message");
    _socket?.on("receive-message", (data) {
      log("📩 Global message => $data");
      handler(data);
    });
  }

  static void onTyping(String chatId, void Function(dynamic data) handler) {
    final eventName = "typing:$chatId";
    _socket?.off(eventName);
    _socket?.on(eventName, (data) {
      log("✍️ Typing event on $eventName => $data");
      handler(data);
    });
    log("🟡 Subscribed to typing:$chatId");
  }

  static void clearChatListeners(String chatId) {
    _socket?.off("receive-message:$chatId");
    _socket?.off("typing:$chatId");
    log("🛑 Cleared listeners for chat: $chatId");
  }

  static void clearAllListeners() {
    _socket?.clearListeners();
    log("🧹 Cleared all socket listeners");
  }

  static void sendText({
    required String chatId,
    required String senderId,
    required String message,
  }) {
    if (!isConnected) {
      log("⚠️ Cannot send text, socket not connected");
      return;
    }
    _socket!.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "message": message,
      "contentType": "text",
    });
    log("➡️ Sent text: $message to chat: $chatId");
  }

  static void sendImage({
    required String chatId,
    required String senderId,
    required String mediaUrl,
  }) {
    if (!isConnected) return;
    _socket!.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "media": mediaUrl,
      "contentType": "image",
    });
    log("➡️ Sent image: $mediaUrl to chat: $chatId");
  }

  static void sendVideo({
    required String chatId,
    required String senderId,
    required String mediaUrl,
    required String mediaIos,
  }) {
    if (!isConnected) return;
    _socket!.emit("send-message", {
      "chat": chatId,
      "sender": senderId,
      "media": mediaUrl,
      "media_ios": mediaIos,
      "contentType": "video",
    });
    log("➡️ Sent video: $mediaUrl to chat: $chatId");
  }

  static void sendTyping({
    required String chatId,
    required String senderId,
    required bool isTyping,
  }) {
    if (!isConnected) return;
    _socket!.emit("typing", {
      "chat": chatId,
      "sender": senderId,
      "isTyping": isTyping,
    });
    log("✍️ Typing [$isTyping] in chat: $chatId");
  }
}
