import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/helpers/route.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:ree_social_media_app/services/api_service.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class SendMessageController extends GetxController {
  final api = ApiService();
  final messageController = Get.put(MessageController());
  final chatController = Get.put(ChatController());
  final userController = Get.put(UserController());

  final RxSet<String> selectedIds = <String>{}.obs;
  final RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    isLoading.value = true;

    try {
      // await GlobalCameraManager.dispose(); // optional

      if (userController.userInfo.value == null) {
        await userController.getInfo();
      }

      final currentUserId = userController.userInfo.value?.id
          ?.toString()
          .trim();
      if (currentUserId == null || currentUserId.isEmpty) {
        isLoading.value = false;
        return;
      }

      // Fetch chats first

      // Extract immediately
      final newFriends = _extractFriends(
        currentUserId,
        messageController.privateChats,
      );
      friends.assignAll(newFriends);

      // Now watch for live updates
      ever<List>(messageController.privateChats, (updatedChats) {
        final updatedFriends = _extractFriends(currentUserId, updatedChats);
        friends.assignAll(updatedFriends);
      });
    } catch (e) {
      Get.snackbar("Error", "Initialization failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _extractFriends(
    String currentUserId,
    List<dynamic> chats,
  ) {
    final List<Map<String, dynamic>> chatFriends = [];

    for (var chat in chats) {
      if (chat['type'] == 'private' && chat['members'] != null) {
        for (var member in chat['members']) {
          final memberId = member['_id']?.toString().trim();
          if (memberId != null && memberId != currentUserId) {
            chatFriends.add({
              '_id': memberId,
              'name': member['name'] ?? 'Unknown',
              'image': member['image'],
              'chatId': chat['_id'],
              'hasChat': true,
            });
          }
        }
      }
    }

    final uniqueFriends = {
      for (var f in chatFriends) f['_id']: f,
    }.values.toList();
    return uniqueFriends;
  }

  Future<void> sendMedia({
    required String filePath,
    required File? thumbnail,
    required bool isVideo,
  }) async {
    isLoading.value = true;

    // Ensure at least one friend is selected
    if (selectedIds.isEmpty) {
      Get.snackbar("Error", "Please select at least one friend.");
      isLoading.value = false; // Make sure loading state is reset
      return;
    }

    try {
      // Ensure .mp4 extension or rename .temp file properly
      final correctedPath = isVideo ? await ensureMp4File(filePath) : filePath;

      final file = File(correctedPath);

      // Check if the file exists at the corrected path
      if (!await file.exists()) {
        throw Exception("File not found at path: $correctedPath");
      }

      // Handle the case where thumbnail is null
      File? validThumbnail;
      if (thumbnail != null) {
        if (!await thumbnail.exists()) {
          throw Exception("Thumbnail not found at path: ${thumbnail.path}");
        }
        validThumbnail = thumbnail; // Only pass thumbnail if it's valid
      }

      // Send the media to multiple chats
      await chatController.sendMediaToMultipleChats(
        friends: friends,
        selectedIds: selectedIds,
        mediaFile: file,
        thumbnail: validThumbnail,
        contentType: isVideo ? 'video' : 'image',
      );

      // Navigate to message screen after sending
      Get.offAllNamed(AppRoutes.messageScreen);
    } catch (e) {
      debugPrint("Failed to send media: $e");
      // Handle error by showing a snackbar
      Get.snackbar(
        "Error",
        "Failed to send media: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false; // Reset loading state
    }
  }

  Future<void> sendMediaToSingleChat({
    required String chatId,
    required String filePath,
    required File? thumbnail,
    required bool isVideo,
    required bool isReaction,
  }) async {
    try {
      isLoading.value = true;

      // ✅ Fix temp extension or ensure valid .mp4 file
      final correctedPath = isVideo ? await ensureMp4File(filePath) : filePath;

      final file = File(correctedPath);
      if (!await file.exists()) {
        throw Exception("File not found at path: $correctedPath");
      }

      // ✅ Send media to single user chat
      await chatController.sendVideoToSingleChat(
        chatId: chatId,
        mediaFile: file,
        thumbnail: thumbnail,
        contentType: isVideo ? 'video' : 'image',
        isReaction: isReaction,
      );

      // Navigate to message screen after sending
      Get.offAllNamed(AppRoutes.messageScreen);
      // Get.back(); // Optionally close the current screen after sending
    } catch (e) {
      // Show error message if sending fails
      debugPrint("Failed to send media: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> ensureMp4File(String filePath) async {
    try {
      final file = File(filePath);

      // If file doesn’t exist, throw an error early
      if (!await file.exists()) {
        throw Exception("File not found at $filePath");
      }

      // If already ends with .mp4 and not .temp, just return
      if (filePath.toLowerCase().endsWith('.mp4') &&
          !filePath.toLowerCase().contains('.temp')) {
        return filePath;
      }

      // Otherwise, create a new .mp4 file in the same directory
      final newPath = p.join(
        p.dirname(filePath),
        '${p.basenameWithoutExtension(filePath)}.mp4',
      );

      // Rename (move) or copy the file
      final newFile = await file.rename(newPath);

      return newFile.path;
    } catch (e) {
      debugPrint('❗ Error converting file to .mp4: $e');
      rethrow;
    }
  }

  Future<void> reportStory(String id) async {
    isLoading.value = true;
    try {
      final response = await api.post("/complain/$id", {}, authReq: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          "Reported",
          "Story has been reported successfully.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryColor,
          colorText: Colors.white,
        );
        debugPrint("✅complained successfully");
      } else {
        debugPrint("❌ Failed to complain user: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error complaining: $e");
    } finally {
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.messageScreen);
    }
  }
}
