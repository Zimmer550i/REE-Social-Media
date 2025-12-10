import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/view_video.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class SeeAllStoryScreen extends StatefulWidget {
  final List<dynamic> stories;
  final bool? isMe;
  const SeeAllStoryScreen({
    super.key,
    required this.stories,
    this.isMe = false,
  });

  @override
  State<SeeAllStoryScreen> createState() => _SeeAllStoryScreenState();
}

class _SeeAllStoryScreenState extends State<SeeAllStoryScreen> {
  final UserController userController = Get.put(UserController());
  late List<dynamic> storiesList;

  @override
  void initState() {
    super.initState();
    storiesList = List.from(widget.stories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ReBack(onTap: () => Get.back()),
                  const SizedBox(width: 12),
                  Text(
                    widget.isMe == true ? "My Stories" : "All Stories",
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
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    // ✅ Match the 4:3 aspect ratio visually
                    childAspectRatio: 3 / 4,
                  ),
                  padding: EdgeInsets.zero,
                  itemCount: storiesList.length,
                  itemBuilder: (context, index) {
                    final story = storiesList[index];
                    final type = story["contentType"];
                    final storyId = story["_id"];
                    final name = story["author"]?["name"] ?? "Unknown";
                    final authorId = story["author"]?["_id"] ?? "Unknown";

                    final userImage = userController.addBaseUrl(
                      story["author"]?["image"] ?? "",
                    );

                    // ✅ Determine media URL safely
                    String? mediaUrl;
                    if (type == "image" && (story["image"] ?? "").isNotEmpty) {
                      mediaUrl = userController.addBaseUrl(story["image"]);
                    } else if (type == "video" &&
                        (story["video"] ?? "").isNotEmpty) {
                      mediaUrl = userController.addBaseUrl(story["video"]);
                    }

                    if (mediaUrl == null || mediaUrl.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      );
                    }

                    // ✅ Each story item now keeps 4:3 ratio visually consistent
                    return _buildStoryCard(
                      context,
                      mediaUrl,
                      name,
                      userImage.toString(),
                      type == "video",
                      storyId,
                      index,
                      authorId,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Updated _buildStoryCard to include index
  Widget _buildStoryCard(
    BuildContext context,
    String mediaUrl,
    String name,
    String userImage,
    bool isVideo,
    String storyId,
    int index,
    String authorId,
  ) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: FutureBuilder<Widget>(
        future: isVideo
            ? _buildVideoThumbnailCard(
                context,
                mediaUrl,
                name,
                userImage,
                storyId,
                index,
                authorId,
              )
            : _buildImageCard(
                context,
                mediaUrl,
                name,
                userImage,
                storyId,
                index,
                authorId,
              ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black26,
              ),
              child: const Center(child: Icon(Icons.error, color: Colors.red)),
            );
          }
          return snap.data!;
        },
      ),
    );
  }

  /// 🖼️ Image story card
  Future<Widget> _buildImageCard(
    BuildContext context,
    String mediaUrl,
    String name,
    String userImage,
    String storyId,
    int index,
    String authorId,
  ) async {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: InkWell(
        onTap: () {
          if (widget.isMe == false) {
            Get.to(
              () => VideoPreviewScreen(
                videoUrl: mediaUrl,
                countdownSeconds: 3,
                userProfile: userImage,
                userName: name,
                chatId: authorId,
                postId: storyId,
              ),
            );
          } else {
            Get.to(() => ViewMedia(mediaUrl: mediaUrl));
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
              _buildBottomNameBar(name),
              if (widget.isMe == true)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    onPressed: () {
                      _confirm(
                        context,
                        onYes: () async {
                          await userController.deleteStory(storyId);
                          setState(() {
                            storiesList.removeAt(index);
                          });
                          Get.back(); // close dialog
                        },
                      );
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Widget> _buildVideoThumbnailCard(
    BuildContext context,
    String videoUrl,
    String name,
    String userImage,
    String storyId,
    int index,
    String authorId,
  ) async {
    final localVideo = await _downloadVideoToLocal(videoUrl);
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: localVideo.path,
      imageFormat: ImageFormat.JPEG,
      quality: 100,
      maxHeight: 0,
      maxWidth: 0,
    );

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: InkWell(
        onTap: () {
          if (widget.isMe == false) {
            Get.to(
              () => VideoPreviewScreen(
                videoUrl: localVideo.path,
                countdownSeconds: 3,
                userProfile: userImage,
                userName: name,
                chatId: authorId,
                postId: storyId,
              ),
            );
          } else {
            Get.to(() => ViewMedia(mediaUrl: localVideo.path));
          }
        },
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

              // ▶️ Play button overlay
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

              // 🗑️ Delete button for your own stories
              if (widget.isMe == true)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    onPressed: () {
                      _confirm(
                        context,
                        onYes: () async {
                          await userController.deleteStory(storyId);
                          setState(() {
                            storiesList.removeAt(index);
                          });
                          Get.back(); // close dialog
                        },
                      );
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context, {required VoidCallback onYes}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFC4C3C3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want delete this story?",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _dialogActions(context, onYes: onYes),
          ],
        ),
      ),
    );
  }

  Widget _dialogActions(BuildContext context, {required VoidCallback onYes}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onYes,
            style: OutlinedButton.styleFrom(
              overlayColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // No action taken if 'No' is pressed
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              overlayColor: Colors.white,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("No", style: TextStyle(color: Color(0xFF676565))),
          ),
        ),
      ],
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
