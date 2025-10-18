import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/notification_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/helpers/generate_video_thumbnail.dart';
import 'package:ree_social_media_app/helpers/global_video_player_manager.dart';
import 'package:ree_social_media_app/services/api_service.dart';
import 'package:ree_social_media_app/services/camera_manager.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/see_all_story_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../base/bottom_menu.dart';
import '../Notification/notification_screen.dart';
import 'AllSubScreen/AllSubScreen/add_friends.dart';
import 'AllSubScreen/AllSubScreen/search_screen.dart';
import 'AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'AllSubScreen/chat_screen.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'groupChat/group_chat.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final MessageController controller = Get.put(MessageController());
  final UserController userController = Get.put(UserController());
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _storyScrollController = ScrollController();

  bool _isFetchingMoreChats = false;
  bool _isFetchingMoreStories = false;

  @override
  void initState() {
    super.initState();
    notificationController.fetchNotifications();

    /// Pagination listener for chats
    _chatScrollController.addListener(() {
      if (_chatScrollController.position.pixels >=
              _chatScrollController.position.maxScrollExtent - 200 &&
          !_isFetchingMoreChats &&
          controller.hasMoreChats.value) {
        _loadMoreChats();
      }
    });

    /// Pagination listener for stories
    _storyScrollController.addListener(() {
      if (_storyScrollController.position.pixels >=
              _storyScrollController.position.maxScrollExtent - 100 &&
          !_isFetchingMoreStories &&
          controller.hasMoreStories.value) {
        _loadMoreStories();
      }
    });
  }

  Future<void> _loadMoreChats() async {
    setState(() => _isFetchingMoreChats = true);
    await controller.fetchChats(loadMore: true);
    setState(() => _isFetchingMoreChats = false);
  }

  Future<void> _loadMoreStories() async {
    setState(() => _isFetchingMoreStories = true);
    await controller.fetchChats(loadMore: true);
    setState(() => _isFetchingMoreStories = false);
  }

@override
void dispose() {
  GlobalCameraManager.dispose();
  GlobalVideoPlayerManager.dispose();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Obx(
        () => BottomMenu(
          0,
          messageCount: int.parse(
            notificationController.totalNotificationCount.toString(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildTopBar(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: _chatScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStoriesSection(),
                      const SizedBox(height: 24),
                      Text(
                        "Chats",
                        style: TextStyle(
                          color: Color(0xFF413E3E),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildChatList(),
                      if (_isFetchingMoreChats)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Bar
  Widget _buildTopBar() {
    return Row(
      children: [
        _logoBox(),
        const Spacer(),
        _iconButton(
          'assets/icons/add.svg',
          onTap: () {
            Get.to(() => AddFriendScreen());
          },
        ),
        const SizedBox(width: 12),
        _iconButton(
          'assets/icons/search.svg',
          onTap: () => Get.to(() => const SearchScreen()),
        ),
        const SizedBox(width: 12),
        _notificationButton(),
      ],
    );
  }

  Widget _notificationButton() {
    return Stack(
      children: [
        _iconButton(
          'assets/icons/notification.svg',
          onTap: () {
            Get.to(() => const NotificationScreen());
          },
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Obx(
                () => Text(
                  notificationController.totalNotificationCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoBox() {
    return SvgPicture.asset("assets/icons/re.svg", height: 35, width: 45);
  }

  Widget _iconButton(String asset, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC4C3C3), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: SvgPicture.asset(asset),
        ),
      ),
    );
  }

  /// Stories Section
  Widget _buildStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Get.to(() => SeeAllStoryScreen());
          },
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              "See All",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170, // taller cards
          child: Obx(() {
            return Skeletonizer(
              enabled: controller.isLoadingStories.value,
              enableSwitchAnimation: true,
              child: ListView.builder(
                controller: _storyScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: controller.stories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildAddStoryCard();

                  if (index > controller.stories.length) {
                    return _isFetchingMoreStories
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox();
                  }

                  var story = controller.stories[index - 1];
                  final isVideo = story["contentType"] == "video";
                  final mediaUrl = (story["image"] as String).isNotEmpty
                      ? "${ApiService().devUrl}${story["image"]}"
                      : "${ApiService().devUrl}${story["video"]}";

                  // handle author safely
                  String authorName = "User";
                  String? authorImage;
                  String? authorId;
                  if (story["author"] is Map) {
                    authorName = story["author"]["name"] ?? "User";
                    authorId = story["author"]["_id"] ?? "";
                    authorImage = userController.addBaseUrl(
                      story["author"]["image"],
                    );
                  } else if (story["author"] is String) {
                    authorName = "User";
                  }

                  return _buildStoryCard(
                    mediaUrl,
                    authorName,
                    authorImage.toString(),
                    isVideo,
                    authorId.toString(),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  /// ✅ Add Story Card
  Widget _buildAddStoryCard() {
    final image = userController.userInfo.value!.image;
    final userImage = userController.addBaseUrl(image.toString());
    return InkWell(
      onTap: () {
        controller.createStory();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 8),
        width: 100,
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            topLeft: Radius.circular(8),
          ),
          image: DecorationImage(
            image: NetworkImage(userImage.toString()),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Left overlay
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  topLeft: Radius.circular(8),
                ),
                child: Container(
                  width: 56, // ~half width overlay
                  color: AppColors.primaryColor.withValues(alpha: 0.56),
                ),
              ),
            ),

            // Text
            const Positioned(
              left: 10,
              top: 50,
              bottom: 0,
              child: Text(
                "Add\nStory",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),

            // Camera button
            Positioned(
              left: 15,
              bottom: 50,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SvgPicture.asset(
                    'assets/icons/camera.svg',
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(
    String mediaUrl,
    String name,
    String image,
    bool isVideo,
    String chatId,
  ) {
    const double cardW = 100;
    const double cardH = 132;

    return FutureBuilder<Widget>(
      future: isVideo
          ? _buildVideoThumbnailWidget(mediaUrl, name, image,chatId)
          : _buildImageStoryWidget(mediaUrl, name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: cardW,
            height: cardH,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: cardW,
            height: cardH,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        }
        return snapshot.data!;
      },
    );
  }

  /// Handles image story preview
  Future<Widget> _buildImageStoryWidget(String mediaUrl, String name) async {
    const double cardW = 100;
    const double cardH = 132;
    const double barH = 32;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: cardW,
      height: cardH,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          topLeft: Radius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: barH,
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
            ),
          ],
        ),
      ),
    );
  }

  /// Handles video story preview with thumbnail + play icon + navigation
  Future<Widget> _buildVideoThumbnailWidget(
    String videoUrl,
    String name,
    String image,
    String chatId,
  ) async {
    const double cardW = 100;
    const double cardH = 132;
    const double barH = 32;

    // ✅ Download video to local (same logic as _downloadVideoToLocal)
    final localVideo = await _downloadVideoToLocal(videoUrl);

    // ✅ Generate thumbnail
    final thumbPath = await generateVideoThumbnail(File(localVideo.path),context);
if (thumbPath != null) {
  debugPrint('Thumbnail saved at: $thumbPath');
}


    return InkWell(
      onTap: () {
        Get.to(
          () => VideoPreviewScreen(
            videoUrl: localVideo.path,
            countdownSeconds: 3,
            userProfile: image,
            userName: name,
            chatId: chatId,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: cardW,
        height: cardH,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            topLeft: Radius.circular(8),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              thumbPath != null
                  ? Image.file(File(thumbPath), fit: BoxFit.cover)
                  : Container(
                      color: Colors.black26,
                      child: Center(
                        child: SpinKitWave(
                          color: AppColors.primaryColor,
                          size: 30.0,
                        ),
                      ),
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: barH,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Download video file locally (same helper you already use)
  Future<File> _downloadVideoToLocal(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4",
    );
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  ///Chats Section
  Widget _buildChatList() {
    final currentUserId = userController.userInfo.value?.id ?? "";

    return Obx(() {
      if (controller.isLoadingChats.value) {
        // 🦴 Skeleton loading placeholder while chats are fetching
        return ListView.builder(
          itemCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  // Circle avatar skeleton
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 10,
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      // 🟢 When loading is false, show actual chat list
      final allChats = [...controller.privateChats, ...controller.groupChats];

      if (allChats.isEmpty) {
        return const Center(child: Text("No chats found"));
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: allChats.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(height: 1),
        itemBuilder: (context, index) {
          var chat = allChats[index];
          String name = chat["name"] ?? "Unknown";
          String image = chat["image"] ?? "";
          String chatId = chat["_id"] ?? "";

          if (chat["type"] == "private") {
            final members = chat["members"] as List? ?? [];
            final other = members.firstWhere(
              (m) => m["_id"] != currentUserId,
              orElse: () => null,
            );
            if (other != null) {
              name = other["name"] ?? name;
              image = other["image"] ?? image;
            }
          }

          final imageWithBaseUrl = userController.addBaseUrl(image);
          final lastMsg = controller.getLastMessage(chat);
          final lastTime = chat["lastMessage"]?["createdAt"] ?? "";

          String formattedTime = "";
          if (lastTime.isNotEmpty) {
            final dt = DateTime.tryParse(lastTime);
            if (dt != null) {
              final now = DateTime.now();
              if (dt.day == now.day &&
                  dt.month == now.month &&
                  dt.year == now.year) {
                formattedTime =
                    "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
              } else if (dt.difference(now).inDays == -1) {
                formattedTime = "Yesterday";
              } else {
                formattedTime = "${dt.day} ${_monthName(dt.month)} ${dt.year}";
              }
            }
          }

          // --- Chat UI ---
          final isPrivate = chat["type"] == "private";

          return InkWell(
            onTap: () {
              if (isPrivate) {
                Get.to(
                  () => ChatScreen(
                    chatId: chatId,
                    receiverName: name,
                    receiverImage: image,
                  ),
                );
              } else {
                Get.to(
                  () => GroupChatScreen(
                    chatId: chatId,
                    groupName: name,
                    groupImage: image,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,

                    backgroundColor: AppColors.primaryColor,
                    backgroundImage: image.isNotEmpty
                        ? NetworkImage(imageWithBaseUrl.toString())
                        : null,
                    child: image.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (chat["isOnline"] == true)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                lastMsg.contains("Video") ||
                                    lastMsg.contains("Image")
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color:
                                lastMsg.contains("Video") ||
                                    lastMsg.contains("Image")
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// Helper for month names
  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }
}
