import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import '../models/multi_body.dart';
import '../services/api_service.dart';
import 'message_controller.dart';

class CreateStoryController extends GetxController {
  final MessageController messageController = Get.put(MessageController());
  final UserController userController = Get.find<UserController>();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  var isLoading = false.obs;

  Future<void> addStory({
    String? imagePath,
    String? videoPath,
    String? caption,
  }) async {
    isLoading.value = true;

    try {
      String? mediaType;
      File? mediaFile;

      final currentUserId = userController.userInfo.value!.id;

      // Wait a tiny bit to ensure messageController.stories is ready
      await Future.delayed(const Duration(seconds: 3));

      final myStories = messageController.stories
          .where(
            (story) =>
                story["author"] != null &&
                (story["author"] is Map
                    ? story["author"]["_id"] == currentUserId
                    : false),
          )
          .toList();

      if (myStories.isNotEmpty) {
        Get.offAllNamed(AppRoutes.messageScreen);
        Get.snackbar(
          "Limit Reached",
          "You have already uploaded your Story for the day 🙂",
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: AppColors.primaryColor,
        );
        return;
      }

      // ↓ Continue with the rest of the story upload logic

      if (imagePath != null) {
        mediaType = 'image';
        mediaFile = File(imagePath);
      } else if (videoPath != null) {
        mediaType = 'video';
        mediaFile = File(videoPath);
      } else {
        mediaType = await _showMediaPickerSheet();
        if (mediaType == null) return;

        XFile? pickedFile;
        if (mediaType == 'image') {
          pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        } else {
          pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
        }

        if (pickedFile == null) return;
        mediaFile = File(pickedFile.path);
      }

      if (!(await mediaFile.exists())) {
        isLoading.value = false;
        Get.snackbar("Error", "No valid media file selected.");
        return;
      }

      if (mediaType == 'video') {
        mediaFile = await _ensureMp4Format(mediaFile);
      }

      await _uploadStoryMedia(mediaFile, mediaType, caption);

      Get.offAndToNamed(AppRoutes.messageScreen);
    } catch (e) {
      debugPrint("❌ Error creating story: $e");
      Get.snackbar(
        "Error",
        "Something went wrong while uploading story.",
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: AppColors.primaryColor,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🧱 Media picker bottom sheet
  Future<String?> _showMediaPickerSheet() async {
    return await Get.bottomSheet<String>(
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
  }

  Future<File> _ensureMp4Format(File file) async {
    final currentExt = p.extension(file.path).toLowerCase();
    if (currentExt == '.mp4') return file;

    final newPath = p.setExtension(file.path, '.mp4');
    final newFile = await file.copy(newPath);

    debugPrint('🎥 Renamed video to .mp4 → $newPath');
    return newFile;
  }

  Future<void> _uploadStoryMedia(
    File file,
    String type,
    String? caption,
  ) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      debugPrint('📡 Uploading $type with MIME type: $mimeType');

      final multipartBody = [MultipartBody(key: type, file: file)];

      final response = await _api.postMultipartData(
        "/story/create-story",
        {"caption": caption},
        multipartBody: multipartBody,
        authReq: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        try {
          Get.snackbar(
            "Upload Failed",
            "Could not upload story. Please try again.",
            snackPosition: SnackPosition.BOTTOM,
            colorText: Colors.white,
            backgroundColor: AppColors.primaryColor,
          );
        } catch (_) {
          Get.snackbar(
            "Upload Failed",
            "Server error: ${response.statusCode}",
            snackPosition: SnackPosition.BOTTOM,
            colorText: Colors.white,
            backgroundColor: AppColors.primaryColor,
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Exception during upload: $e");
      Get.snackbar(
        "Error",
        "Could not upload story. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: AppColors.primaryColor,
      );
    }
  }
}
