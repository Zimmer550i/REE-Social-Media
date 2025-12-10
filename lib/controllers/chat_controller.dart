import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/groupChat/group_details_screen.dart';
import 'package:uuid/uuid.dart';
import '../models/multi_body.dart';
import '../services/api_service.dart';
import '../services/socket_manager.dart';
import '../views/screen/Message/AllSubScreen/chat_screen.dart';

class ChatController extends GetxController {
  final userCtrl = Get.find<UserController>();
  final api = ApiService();

  /// Reactive State
  final RxBool isLoading = false.obs;
  final RxBool isPaginating = false.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final ImagePicker _picker = ImagePicker();
  late ScrollController scrollController;

  /// Pagination
  int _currentPage = 1;
  final int _limit = 15;
  bool _hasMore = true;

  /// Session data
  String _chatId = '';
  late String _currentUserId;
  late String token;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  void disconnect() {
    SocketService.clearChatListeners(_chatId);
    // SocketService.disconnect();
  }

  Future<bool> blockUser(String userId, String? chatId) async {
    isLoading.value = true;
    try {
      final response = await api.post("/user/block/$userId", {}, authReq: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ User blocked successfully");
        if (chatId!.isNotEmpty) {
          Get.find<MessageController>().deleteChat(chatId);
        }
        return true;
      } else {
        debugPrint("❌ Failed to block user: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error blocking user: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> reportUser(String id, String? chatId) async {
    isLoading.value = true;
    try {
      final response = await api.post("/complain/$id", {}, authReq: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ User complained successfully");
        if (chatId!.isNotEmpty) {
          Get.find<MessageController>().deleteChat(chatId);
        }
        return true;
      } else {
        debugPrint("❌ Failed to complain user: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error complaining: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==============================
  // CHAT FLOW
  // ==============================

  Future<void> initChat({
    required String chatId,
    required String currentUserId,
    required String token,
  }) async {
    _chatId = chatId;
    _currentUserId = currentUserId;
    this.token = token;

    /// 1️⃣ Fetch initial messages
    await fetchMessages();

    /// 2️⃣ Connect to socket
    SocketService.connect(token);

    /// 3️⃣ Delay a bit to ensure connection is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      /// ✅ Listen for messages only for this chat
      SocketService.onChatMessage(_chatId, (data) {
        final msg = _mapMessage(data, _currentUserId);

        if (msg["isMe"]) {
          final idx = messages.indexWhere(
            (m) => m["temp"] == true && m["message"] == msg["message"],
          );
          if (idx != -1) {
            messages[idx] = msg;
          } else {
            messages.insert(0, msg);
          }
        } else {
          messages.insert(0, msg);
        }
        _scrollToBottom();
      });

      /// ✍️ Typing listener
      SocketService.onTyping(_chatId, (data) {
        debugPrint("✍️ Typing: $data");
      });
    });

    SocketService.onGlobalMessage((data) {
      final msg = _mapMessage(data, _currentUserId);
      if (msg["chatId"] == _chatId) {
        messages.insert(0, msg);
        _scrollToBottom();
      }
    });
  }

  // ==============================
  // CREATE CHATS
  // ==============================

  Future<void> createPrivateChat(
    String name,
    String image,
    String memberId,
  ) async {
    isLoading.value = true;
    try {
      final response = await api.post("/chat/create-private", {
        "member": memberId,
      }, authReq: true);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = body['data']['_id'];
        Get.to(
          () => ChatScreen(
            chatId: chatId,
            receiverName: name,
            receiverImage: image,
            receiverid: memberId,
          ),
        );
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating private chat: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createGroupChat(List<String> memberIds) async {
    isLoading.value = true;
    try {
      final response = await api.post("/chat/create-group", {
        "members": memberIds,
      }, authReq: true);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = body['data']['_id'];
        Get.to(() => GroupDetailsScreen(chatId: chatId, isCreated: true));
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating groupChat chat: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMessages() async {
    _resetPagination();
    await _fetchPage(appendBottom: true);
    _scrollToBottom();
  }

  Future<void> loadOlder() async {
    if (!_hasMore || isPaginating.value) return;
    await _fetchPage(appendBottom: false);
  }

  Future<void> _fetchPage({bool appendBottom = true}) async {
    try {
      if (_currentPage == 1) {
        isLoading.value = true;
      } else {
        isPaginating.value = true;
      }

      final res = await api.get(
        "/chat/chat-inbox/$_chatId?limit=$_limit&page=$_currentPage",
        authReq: true,
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List rawMessages = body['data'] ?? [];

        if (rawMessages.isEmpty) {
          _hasMore = false;
        } else {
          final mapped = rawMessages
              .map<Map<String, dynamic>>((m) => _mapMessage(m, _currentUserId))
              .toList();

          if (appendBottom) {
            messages.insertAll(0, mapped);
            _scrollToBottom();
          } else {
            messages.addAll(mapped);
          }

          _currentPage++;
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching messages: $e");
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }

  void _resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    messages.clear();
  }

  void sendText(String text) {
    final tempId = const Uuid().v4();

    SocketService.sendText(
      chatId: _chatId,
      senderId: _currentUserId,
      message: text,
    );

    messages.insert(0, {
      "_id": tempId,
      "isMe": true,
      "type": "text",
      "message": text,
      "media": "",
      "time":
          "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
      "temp": true,
    });
    _scrollToBottom();
  }

  Future<String?> uploadMedia(File file, {String type = "image"}) async {
    final multipartBody = [MultipartBody(key: type, file: file)];
    final response = await api.postMultipartData(
      "/message/upload",
      {},
      multipartBody: multipartBody,
      authReq: true,
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['mediaUrl'];
    } else {
      debugPrint("❗ Upload failed: ${response.body}");
      return null;
    }
  }

  Future<void> pickAndSendImage() async {
    isLoading.value = true;
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final mediaUrl = await uploadMedia(File(file.path), type: "image");
    if (mediaUrl != null) {
      SocketService.sendImage(
        chatId: _chatId,
        senderId: _currentUserId,
        mediaUrl: mediaUrl,
      );

      // 👇 Add this manually so UI updates immediately
      messages.insert(0, {
        "_id": const Uuid().v4(),
        "isMe": true,
        "type": "image",
        "media": mediaUrl,
        "message": "",
        "time":
            "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        "temp": true,
      });
      _scrollToBottom();
    }

    isLoading.value = false;
  }

  Future<void> pickAndSendVideo() async {
    isLoading.value = true;
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final mediaUrl = await uploadMedia(File(file.path), type: "video");
    if (mediaUrl != null) {
      SocketService.sendVideo(
        chatId: _chatId,
        senderId: _currentUserId,
        mediaUrl: mediaUrl,
      );

      // 👇 Add this manually so UI updates immediately
      messages.insert(0, {
        "_id": const Uuid().v4(),
        "isMe": true,
        "type": "video",
        "media": mediaUrl,
        "message": "",
        "time":
            "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        "temp": true,
      });
      _scrollToBottom();
    }

    isLoading.value = false;
  }

  Future<void> pickAndSendMedia() async {
    // Bottom sheet: choose Image or Video
    await showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image, color: AppColors.primaryColor),
                title: const Text("Select Image"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickAndSendImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: AppColors.primaryColor),
                title: const Text("Select Video"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickAndSendVideo();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.redAccent),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void sendTyping(bool isTyping) {
    SocketService.sendTyping(
      chatId: _chatId,
      senderId: _currentUserId,
      isTyping: isTyping,
    );
  }

  Future<void> sendMediaToMultipleChats({
    required List<Map<String, dynamic>> friends,
    required Set<String> selectedIds,
    required File mediaFile,
    required File? thumbnail,
    required String contentType,
  }) async {
    if (selectedIds.isEmpty) {
      debugPrint("⚠️ No friends selected to send media.");
      return;
    }

    try {
      isLoading.value = true;

      final senderId = userCtrl.userInfo.value?.id;
      if (senderId == null) {
        debugPrint("⚠️ Missing user ID.");
        return;
      }

      // 🔄 Loop over all selected friends
      for (final friend in friends) {
        if (!selectedIds.contains(friend['_id'])) continue;

        final chatId = friend['chatId'];
        if (chatId == null) {
          debugPrint("⚠️ No chatId found for ${friend['name']}");
          continue;
        }

        debugPrint("🚀 Sending $contentType to ${friend['name']}...");

        // Prepare the body with JSON data
        final body = {
          "data": jsonEncode({
            "senderId": senderId,
            "chatIds": [chatId],
            "contentType": contentType,
          }),
        };

        // Prepare the multipart files (image/video and thumbnail)
        final multipartFiles = <MultipartBody>[];

        if (contentType == 'video') {
          multipartFiles.add(MultipartBody(key: 'video', file: mediaFile));
        } else if (contentType == 'image') {
          multipartFiles.add(MultipartBody(key: 'image', file: mediaFile));
        }

        // Add the thumbnail file (if provided)
        if (thumbnail != null && await thumbnail.exists()) {
          debugPrint("📤 Adding thumbnail for ${friend['name']}");
          multipartFiles.add(MultipartBody(key: 'thumbnail', file: thumbnail));
        } else {
          debugPrint("❌ No valid thumbnail provided for ${friend['name']}");
        }

        // API call to send data
        final response = await api.postMultipartData(
          "/message/send-message",
          body,
          multipartBody: multipartFiles,
          authReq: true,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          debugPrint("✅ Sent to ${friend['name']}: ${responseData['message']}");
        } else {
          debugPrint(
            "❌ Failed to send to ${friend['name']}: ${response.statusCode}",
          );
          debugPrint("📦 Body: ${response.body}");
        }
      }

      debugPrint(
        "🎉 Successfully sent $contentType to ${selectedIds.length} friends!",
      );
      Get.back();
    } catch (e, s) {
      debugPrint("❌ Error sending media: $e");
      debugPrintStack(stackTrace: s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendVideoToSingleChat({
    required String chatId,
    required File mediaFile,
    required File? thumbnail,
    required String contentType,
    bool isReaction = false,
  }) async {
    try {
      isLoading.value = true;

      // Ensure media file exists
      if (!await mediaFile.exists()) {
        debugPrint("❌ Media file is invalid or doesn't exist.");
        return;
      }

      // // Ensure thumbnail exists if provided (no need to check explicitly in multiple places)
      // if (thumbnail != null && !await thumbnail.exists()) {
      //   debugPrint("❌ Thumbnail file is invalid or doesn't exist.");
      //   return;
      // }

      final senderId = userCtrl.userInfo.value?.id;

      if (senderId == null) {
        debugPrint("⚠️ Missing user ID.");
        return;
      }

      debugPrint("🚀 Sending $contentType to chatId: $chatId...");

      // Prepare the body with JSON data
      final body = {
        "data": jsonEncode({
          "senderId": senderId,
          "reaction": isReaction,
          "chatIds": [chatId],
          "contentType": contentType,
        }),
      };

      // Prepare the multipart files (video/image and optional thumbnail)
      final multipartFiles = <MultipartBody>[
        MultipartBody(
          key: contentType == 'video' ? 'video' : 'image',
          file: mediaFile,
        ),
      ];

      // Add the thumbnail file only if it exists
      if (thumbnail != null) {
        multipartFiles.add(MultipartBody(key: 'thumbnail', file: thumbnail));
      }
      final response = await api.postMultipartData(
        "/message/send-message",
        body,
        multipartBody: multipartFiles,
        authReq: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        debugPrint("✅ ${responseData['message']}");
        debugPrint("📦 Response Data: ${responseData['data']}");
      } else {
        debugPrint("❌ Failed: ${response.statusCode}");
        debugPrint("📦 Body: ${response.body}");
      }
    } catch (e, s) {
      debugPrint("❌ Exception while sending $contentType: $e");
      debugPrintStack(stackTrace: s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateChatView(String messageId) async {
    try {
      isLoading.value = true;
      final endpoint = "/message/view-status/$messageId";
      final response = await api.patch(endpoint, {}, authReq: true);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Chat view updated successfully: $data");
      } else {
        debugPrint("❌ Failed to update chat view: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Exception in updateChatView: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _mapMessage(dynamic m, String currentUserId) {
    final createdAt = DateTime.tryParse(m['createdAt'] ?? '');

    final isMe = m["sender"] is Map
        ? m["sender"]["_id"] == currentUserId
        : m["sender"] == currentUserId;

    return {
      "_id": m["_id"] ?? "",
      "isMe": isMe,
      "type": m["contentType"] ?? "text",
      "message": m["message"] ?? "",
      "media": m["media"] ?? "",
      "thumbnail": m["thumbnail"] ?? "",
      "time": createdAt,
      "temp": false,
      "view": m["view"],
      "reaction": m["reaction"],
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
