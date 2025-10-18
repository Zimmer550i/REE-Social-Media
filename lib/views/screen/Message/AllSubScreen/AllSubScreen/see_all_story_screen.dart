import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/helpers/generate_video_thumbnail.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class SeeAllStoryScreen extends StatelessWidget {
  SeeAllStoryScreen({super.key});
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    final MessageController homeController = Get.find<MessageController>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: Icon(Icons.arrow_back, color: AppColors.textColor),
                ),
                const SizedBox(width: 12),
                Text(
                  "All Stories",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// ✅ Stories grid
            Expanded(
              child: Obx(() {
                if (homeController.isLoadingStories.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (homeController.stories.isEmpty) {
                  return const Center(child: Text("No stories available"));
                }

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  padding: EdgeInsets.zero,
                  itemCount: homeController.stories.length,
                  itemBuilder: (context, index) {
                    final story = homeController.stories[index];
                    final type = story["contentType"];
                    final name = story["author"]?["name"] ?? "Unknown";
                    final userImage = userController.addBaseUrl(
                      story["author"]["image"],
                    );

                    // ✅ Determine media URL
                    String? mediaUrl;
                    if (type == "image" && (story["image"] ?? "").isNotEmpty) {
                      mediaUrl = userController.addBaseUrl(story["image"]);
                    } else if (type == "video" &&
                        (story["video"] ?? "").isNotEmpty) {
                      mediaUrl = userController.addBaseUrl(story["video"]);
                    }

                    if (mediaUrl == null || mediaUrl.isEmpty) {
                      return const Center(child: Icon(Icons.error));
                    }

                    return _buildStoryCard(
                      context,
                      mediaUrl,
                      name,
                      userImage.toString(),
                      type == "video",
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Handles both image & video stories
  Widget _buildStoryCard(
    BuildContext context,
    String mediaUrl,
    String name,
    String userImage,
    bool isVideo,
  ) {
    return FutureBuilder<Widget>(
      future: isVideo
          ? _buildVideoThumbnailCard(context, mediaUrl, name, userImage)
          : _buildImageCard(mediaUrl, name),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black12,
            ),
            child: Center(
              child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black26,
            ),
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        }
        return snap.data!;
      },
    );
  }

  /// 🖼️ Image story card
  Future<Widget> _buildImageCard(String mediaUrl, String name) async {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image)),
          ),
          _buildBottomNameBar(name),
        ],
      ),
    );
  }

  /// 🎬 Video story card (download + thumbnail + open preview)
  Future<Widget> _buildVideoThumbnailCard(
    BuildContext context,
    String videoUrl,
    String name,
    String userImage,
  ) async {
    // Download video locally for thumbnail
    final localVideo = await _downloadVideoToLocal(videoUrl);

    // Generate thumbnail
    final thumbPath = await generateVideoThumbnail(File(localVideo.path),context);
if (thumbPath != null) {
  print('Thumbnail saved at: $thumbPath');
}


    return InkWell(
      onTap: () => Get.to(
        () => VideoPreviewScreen(
          videoUrl: localVideo.path,
          countdownSeconds: 3,
          userProfile: userImage,
          userName: name,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbPath != null)
              Image.file(File(thumbPath), fit: BoxFit.cover)
            else
              Container(
                color: Colors.black26,
                child: const Center(child: Icon(Icons.error)),
              ),
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            _buildBottomNameBar(name),
          ],
        ),
      ),
    );
  }

  /// Bottom overlay name bar
  Widget _buildBottomNameBar(String name) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        color: Colors.black.withValues(alpha: 0.42),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 🧩 Helper: download remote video to temp folder
  Future<File> _downloadVideoToLocal(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4",
    );
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
