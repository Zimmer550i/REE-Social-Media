import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/services/one_signal_manager.dart';
import 'package:ree_social_media_app/services/socket_manager.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import '../models/multi_body.dart';
import '../services/api_service.dart';

class MessageController extends GetxController {
  final userController = Get.find<UserController>();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final chatController = Get.put(ChatController());

  final RxList<Map<String, dynamic>> privateChats =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> groupChats = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final isLoadingChats = false.obs;
  final isRefreshingLoading = false.obs;
  final chatPage = 1.obs;
  final hasMoreChats = true.obs;

  final stories = <dynamic>[].obs;
  final isLoadingStories = false.obs;
  final isLoading = false.obs;
  final storyPage = 1.obs;
  final hasMoreStories = true.obs;

  void _mergeStories(List newStories) {
    for (var story in newStories) {
      final index = stories.indexWhere((s) => s["_id"] == story["_id"]);
      if (index == -1) {
        stories.add(story);
      } else {
        final oldUpdated = stories[index]["updatedAt"];
        if (oldUpdated != story["updatedAt"]) {
          stories[index] = story;
        }
      }
    }
  }

  void _mergeChats(
    List<Map<String, dynamic>> incoming,
    RxList<Map<String, dynamic>> target,
  ) {
    for (var chat in incoming) {
      final index = target.indexWhere((c) => c["_id"] == chat["_id"]);
      if (index == -1) {
        target.add(chat);
      } else {
        final oldLast = target[index]["lastMessage"]?["_id"];
        final newLast = chat["lastMessage"]?["_id"];
        if (oldLast != newLast) {
          target[index] = chat;
        }
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchChats();
    fetchStories();
    SocketService.onGlobalMessage(_handleIncomingMessage);
  }

  void _handleIncomingMessage(dynamic data) {
    final String currentUserId = userController.userInfo.value?.id ?? '';

    if (data['sender'] == currentUserId) return;
    calculateUnreadMessages();
  }

  void calculateUnreadMessages() {
    final String currentUserId = userController.userInfo.value?.id ?? '';

    int total = 0;

    bool isUnread(Map<String, dynamic>? last) {
      if (last == null) return false;

      final sender = last["sender"];
      final read = last["read"];

      // Only count as unread if:
      // - sender is NOT current user
      // - read is explicitly false (not null, not 0, not missing)
      return sender != null &&
          sender != currentUserId &&
          read is bool &&
          read == false;
    }

    for (final Map<String, dynamic> chat in groupChats) {
      if (isUnread(chat["lastMessage"])) {
        total++;
      }
    }

    for (final Map<String, dynamic> chat in privateChats) {
      if (isUnread(chat["lastMessage"])) {
        total++;
      }
    }

    unreadCount.value = total;
    OneSignalHelper.setBadge(total);
    debugPrint("Total unread messages (calculated): $total");
  }

  Future<String?> getOrCreatePrivateChat(
    String userId,
    String name,
    String image,
  ) async {
    try {
      final Map<String, dynamic>? existingChat = _findChatByUserId(userId);

      if (existingChat != null) {
        return existingChat["_id"];
      }
      String? newChatId = await createChatAndSendReaction(name, image, userId);
      return newChatId;
    } catch (e) {
      debugPrint("❌ Error in getOrCreatePrivateChat: $e");
      return null;
    }
  }

  Map<String, dynamic>? _findChatByUserId(String userId) {
    try {
      return privateChats.firstWhere((chat) {
        final members = chat["members"] as List<dynamic>?;

        if (members == null) return false;

        return members.any((m) => m is Map && m["_id"] == userId);
      });
    } catch (_) {
      return null;
    }
  }

  Future<String?> createChatAndSendReaction(
    String name,
    String image,
    String memberId,
  ) async {
    isLoading.value = true;
    try {
      final response = await _api.post("/chat/create-private", {
        "member": memberId,
      }, authReq: true);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = body['data']['_id'];
        return chatId;
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error creating private chat: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStories({
    int limit = 20,
    bool loadMore = false,
    bool silent = false,
  }) async {
    if (isLoadingStories.value || (loadMore && !hasMoreStories.value)) return;

    if (!loadMore) {
      storyPage.value = 1;
      hasMoreStories.value = true;
    }

    if (!silent) isLoadingStories.value = true;

    try {
      final response = await _api.get(
        "/story/all-stories",
        queryParams: {
          "page": storyPage.value.toString(),
          "limit": limit.toString(),
        },
        authReq: true,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["success"] == true) {
          final List newStories = body["data"] ?? [];
          _mergeStories(newStories);

          final meta = body["meta"] ?? {};
          final totalPage = meta["totalPage"] ?? 1;
          hasMoreStories.value = storyPage.value < totalPage;
          if (hasMoreStories.value) storyPage.value++;
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching stories: $e");
    } finally {
      if (!silent) isLoadingStories.value = false;
    }
  }

  Future<void> fetchChats({bool loadMore = false, bool silent = false}) async {
    if (isLoadingChats.value || (loadMore && !hasMoreChats.value)) return;
    if (!silent) isLoadingChats.value = true;

    if (!loadMore) {
      chatPage.value = 1;
      hasMoreChats.value = true;
    }

    try {
      final response = await _api.get(
        "/chat/private-chat-list",
        queryParams: {"limit": "10", "page": chatPage.value.toString()},
        authReq: true,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["success"] == true) {
          final List data = body["data"] ?? [];

          final privates = data
              .where((c) => c['type'] == "private")
              .map((c) => Map<String, dynamic>.from(c))
              .toList();

          final groups = data
              .where((c) => c['type'] == "group")
              .map((c) => Map<String, dynamic>.from(c))
              .toList();
          _mergeChats(privates, privateChats);
          _mergeChats(groups, groupChats);

          calculateUnreadMessages();

          final meta = body['meta'] ?? {};
          final totalPage = meta['totalPage'] ?? 1;
          hasMoreChats.value = chatPage.value < totalPage;
          if (hasMoreChats.value) chatPage.value++;
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching chats: $e");
    } finally {
      if (!silent) isLoadingChats.value = false;
    }
  }

  Future<void> fetchAllStories() async {
    await fetchStories(loadMore: false);
  }

  Future<void> fetchAllChats() async {
    await fetchChats(loadMore: false);
  }

  String getLastMessage(Map<String, dynamic> chat) {
    final msg = chat["lastMessage"];
    final sender = msg?["sender"];
    final currentUserId = Get.find<UserController>().userInfo.value!.id;

    if (msg == null) return "";

    // Check if the current user sent the message
    if (sender == currentUserId) {
      switch (msg["contentType"]) {
        case "image":
          return "Photo";
        case "video":
          return "Video";
        default:
          return msg["message"] ?? "";
      }
    } else {
      // Current user received a video or photo
      switch (msg["contentType"]) {
        case "image":
          return "Sent a photo";
        case "video":
          return "Sent a video";
        default:
          return msg["message"] ?? "";
      }
    }
  }

  Future<void> refreshAll() async {
    isRefreshingLoading.value = true;
    chatPage.value = 1;
    storyPage.value = 1;
    hasMoreChats.value = true;
    hasMoreStories.value = true;
    privateChats.clear();
    groupChats.clear();
    stories.clear();

    await Future.wait([fetchChats(), fetchStories()]);
    isRefreshingLoading.value = false;
  }

  Future<void> createStory() async {
    final mediaType = await Get.bottomSheet<String>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.image, color: AppColors.primaryColor),
              title: const Text('Add Image Story'),
              onTap: () => Get.back(result: 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.deepPurple),
              title: const Text('Add Video Story'),
              onTap: () => Get.back(result: 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.redAccent),
              title: const Text('Cancel'),
              onTap: () => Get.back(result: null),
            ),
          ],
        ),
      ),
    );

    if (mediaType == null) return;

    try {
      XFile? pickedFile;
      if (mediaType == 'image') {
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      } else {
        pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile == null) return;

      final mediaFile = File(pickedFile.path);
      final uploadedUrl = await _uploadStoryMedia(mediaFile, mediaType);

      if (uploadedUrl != null) {
        Get.snackbar(
          "Success",
          "Your $mediaType story uploaded successfully!",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Upload Failed",
          "Could not upload your $mediaType story.",
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: AppColors.primaryColor,
        );
      }
    } catch (e) {
      debugPrint("❌ Error picking/uploading media: $e");
      Get.snackbar(
        "Error",
        "Something went wrong while uploading story.",
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: AppColors.primaryColor,
      );
    }
  }

  Future<String?> _uploadStoryMedia(File file, String type) async {
    try {
      final multipartBody = [MultipartBody(key: type, file: file)];
      final response = await _api.postMultipartData(
        "/story/create-story",
        {},
        multipartBody: multipartBody,
        authReq: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        debugPrint("✅ $type uploaded: ${resData['data']['contentType']}");
        return resData['data']['contentType'];
      } else {
        debugPrint("❗ Upload failed: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception during upload: $e");
      return null;
    }
  }

  Future<String> deleteChat(String chatId) async {
    try {
      isLoading.value = true;
      final res = await _api.delete("/chat/delete-chat/$chatId", authReq: true);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return "success";
      } else {
        return body["message"] ?? "Failed to delete chat";
      }
    } catch (e) {
      debugPrint(e.toString());
      return "Unexpected error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }
}
