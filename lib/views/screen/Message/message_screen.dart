import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/notification_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/helpers/global_video_player_manager.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/show_snackbar.dart';
import 'package:ree_social_media_app/views/screen/Contact/contact_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/see_all_story_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../base/bottom_menu.dart';
import '../Notification/notification_screen.dart';
import 'AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'AllSubScreen/chat_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
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
  final Map<String, String?> _thumbCache = {};
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
    userController.setSubscriptionId();
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
    // GlobalCameraManager.dispose();
    GlobalVideoPlayerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Obx(
        () => BottomMenu(0, messageCount: controller.unreadCount.value),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          color: AppColors.primaryColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
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
      ),
    );
  }

  /// Top Bar
  Widget _buildTopBar() {
    return Row(
      children: [
        _logoBox(),
        const Spacer(),
        InkWell(
          onTap: () => Get.to(() => const ContactScreen()),
          child: _iconButton(
            'assets/icons/add.svg',
            onTap: () => Get.to(() => const ContactScreen()),
          ),
        ),
        // const SizedBox(width: 12),
        // _iconButton(
        //   'assets/icons/search.svg',
        //   onTap: () => Get.to(() => const SearchScreen()),
        // ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => Get.to(() => const NotificationScreen()),
          child: _notificationButton(),
        ),
      ],
    );
  }

  Widget _notificationButton() {
    return Stack(
      children: [
        _iconButton(
          'assets/icons/notification.svg',
          onTap: () => Get.to(() => const NotificationScreen()),
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
    return Obx(() {
      // Filter out stories from the logged-in user
      final currentUserId = userController.userInfo.value!.id;
      final filteredStories = controller.stories
          .where(
            (story) =>
                story["author"] != null &&
                (story["author"] is Map
                    ? story["author"]["_id"] != currentUserId
                    : true),
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Get.to(() => SeeAllStoryScreen(stories: filteredStories));
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
            height: 170,
            child: Skeletonizer(
              enabled: controller.isLoadingStories.value,
              enableSwitchAnimation: true,
              child: ListView.builder(
                controller: _storyScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: filteredStories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildAddStoryCard();

                  if (index > filteredStories.length) {
                    return _isFetchingMoreStories
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          )
                        : const SizedBox();
                  }

                  var story = filteredStories[index - 1];
                  final isVideo = story["contentType"] == "video";
                  final mediaUrl = story["image"].isNotEmpty
                      ? story["image"]
                      : story["video"];

                  // handle author safely
                  String authorName = "User";
                  String? authorImage;
                  String? authorId;

                  if (story["author"] is Map) {
                    authorName = story["author"]["name"] ?? "User";
                    authorId = story["author"]["_id"] ?? "";
                    authorImage = story["author"]["image"];
                  } else if (story["author"] is String) {
                    authorName = "User";
                  }

                  return _buildStoryCard(
                    mediaUrl,
                    authorName,
                    authorImage.toString(),
                    isVideo,
                    authorId.toString(),
                    story["_id"],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  //Add Story Card
  Widget _buildAddStoryCard() {
    final image = userController.userInfo.value!.image;
    final userImage = userController.addBaseUrl(image.toString());
    final currentUserId = userController.userInfo.value!.id;
    final myStories = controller.stories
        .where(
          (story) =>
              story["author"] != null &&
              (story["author"] is Map
                  ? story["author"]["_id"] == currentUserId
                  : false),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 8),
      width: 100,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          topLeft: Radius.circular(8),
        ),

        border: Border.all(
          color: myStories.isNotEmpty
              ? AppColors.primaryColor
              : Colors.transparent,
          width: myStories.isNotEmpty ? 5 : 0,
        ),
        image: DecorationImage(
          image: NetworkImage(userImage.toString()),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Left overlay with "Add Story" and camera button
          Align(
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                topLeft: Radius.circular(4),
              ),
              child: Container(
                width: 56,
                color: AppColors.primaryColor.withValues(alpha: 0.56),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 10,
                      top: 40,
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
                    Positioned(
                      left: 10,
                      bottom: 60,
                      child: InkWell(
                        onTap: () => Get.offAndToNamed(AppRoutes.cameraScreen),
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
                              // ignore: deprecated_member_use
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ Right side (background image) tap to open user's own stories
          Positioned.fill(
            left: 56, // only make the RIGHT side tappable
            child: InkWell(
              onTap: () {
                if (myStories.isEmpty) {
                  Get.snackbar(
                    "No Stories",
                    "You haven't added any stories yet.",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                Get.to(
                  () => SeeAllStoryScreen(stories: myStories, isMe: true),
                )?.then((value) {
                  // This code runs when the user comes back
                  controller.refreshAll();
                });
              },
              child: Container(
                color: Colors.transparent, // needed for tap detection
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(
    String mediaUrl,
    String name,
    String image,
    bool isVideo,
    String authorId,
    String postId,
  ) {
    const double cardW = 100;
    const double cardH = 132;

    return FutureBuilder<Widget>(
      future: isVideo
          ? _buildVideoThumbnailWidget(mediaUrl, name, image, authorId, postId)
          : _buildImageStoryWidget(mediaUrl, name, image, authorId, postId),
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
  Future<Widget> _buildImageStoryWidget(
    String mediaUrl,
    String name,
    String image,
    String authorId,
    String postId,
  ) async {
    const double cardW = 100;
    const double cardH = 132;
    const double barH = 32;

    return InkWell(
      onTap: () {
        Get.to(
          () => VideoPreviewScreen(
            videoUrl: mediaUrl,
            countdownSeconds: 3,
            userProfile: image,
            userName: name,
            postId: postId,
            chatId: authorId,
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
              Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
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
      ),
    );
  }

  /// Handles video story preview with thumbnail + play icon + navigation
  Future<Widget> _buildVideoThumbnailWidget(
    String videoUrl,
    String name,
    String image,
    String authorId,
    String postId,
  ) async {
    const double cardW = 100;
    const double cardH = 132;
    const double barH = 32;

    try {
      // 1. Use cached thumbnail if available
      if (_thumbCache.containsKey(videoUrl)) {
        final cachedThumb = _thumbCache[videoUrl];
        return _buildVideoCardWidget(
          cachedThumb,
          name,
          image,
          authorId,
          videoUrl,
          cardW,
          cardH,
          barH,
          postId,
        );
      }

      // 2. Download video locally
      final localVideo = await _downloadVideoToLocal(videoUrl);

      // 3. Generate thumbnail safely
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: localVideo.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 0,
        maxWidth: 0,
        quality: 100,
      );

      // 4. Cache result for reuse
      _thumbCache[videoUrl] = thumbPath;

      // 5. Clean up temp video to free memory
      if (await localVideo.exists()) {
        await localVideo.delete();
      }

      // 6. Build widget
      return _buildVideoCardWidget(
        thumbPath,
        name,
        image,
        authorId,
        videoUrl,
        cardW,
        cardH,
        barH,
        postId,
      );
    } catch (e) {
      debugPrint("⚠️ Thumbnail generation error: $e");
      return Container(
        width: cardW,
        height: cardH,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Extracted reusable card builder (cleaner)
  Widget _buildVideoCardWidget(
    String? thumbPath,
    String name,
    String image,
    String authorId,
    String videoUrl,
    double cardW,
    double cardH,
    double barH,
    String postId,
  ) {
    return InkWell(
      onTap: () {
        Get.to(
          () => VideoPreviewScreen(
            videoUrl: videoUrl,
            countdownSeconds: 3,
            userProfile: image,
            userName: name,
            chatId: authorId,
            postId: postId,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: cardW,
        height: cardH,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
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

  ///Safe temp video downloader
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
        //Skeleton loading placeholder while chats are fetching
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

      final allChats = [...controller.privateChats, ...controller.groupChats];

      allChats.sort((a, b) {
        final aTime =
            DateTime.tryParse(a["lastMessage"]?["createdAt"] ?? "") ??
            DateTime(1900);
        final bTime =
            DateTime.tryParse(b["lastMessage"]?["createdAt"] ?? "") ??
            DateTime(1900);
        return bTime.compareTo(aTime);
      });

      if (allChats.isEmpty) {
        return const Center(child: Text("No chats found"));
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: allChats.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, _) => const SizedBox(height: 1),
        itemBuilder: (context, index) {
          var chat = allChats[index];
          String name = chat["name"] ?? "Unknown";
          if (name == "group chat") name = "Group Chat";
          String image = chat["image"] ?? "";
          String chatId = chat["_id"] ?? "";
          String userId = "";

          if (chat["type"] == "private") {
            final members = chat["members"] as List? ?? [];
            final other = members.firstWhere(
              (m) => m["_id"] != currentUserId,
              orElse: () => null,
            );
            if (other != null) {
              name = other["name"] ?? name;
              image = other["image"] ?? image;
              userId = other["_id"] ?? "";
            }
          }

          final imageWithBaseUrl = userController.addBaseUrl(image);
          final lastMsg = controller.getLastMessage(chat);
          final lastTime = chat["lastMessage"]?["createdAt"];
          String formattedTime = '';
          if (lastTime != null) formattedTime = formatServerTime(lastTime);

          // --- Chat UI ---
          final isPrivate = chat["type"] == "private";

          return Slidable(
            key: const ValueKey(0),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  backgroundColor: const Color(0xFFFE4A49),
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                  onPressed: (BuildContext context) =>
                      confirm(context, allChats, index, chatId),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                if (isPrivate) {
                  Get.to(
                    () => ChatScreen(
                      chatId: chatId,
                      receiverid: userId,
                      receiverName: name,
                      receiverImage: image,
                    ),
                  );
                } else {
                  Get.to(() => GroupChatScreen(chatId: chatId));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                              const SizedBox(width: 8),
                              if (chat['lastMessage'] != null) ...[
                                if (chat["lastMessage"]["read"] == false &&
                                    chat["lastMessage"]["sender"] !=
                                        currentUserId)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: chat["lastMessage"] == null
                                  ? FontWeight.normal
                                  : chat["lastMessage"]["read"] == false &&
                                        chat["lastMessage"]["sender"] !=
                                            currentUserId
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  lastMsg.contains("Video") ||
                                      lastMsg.contains("Image")
                                  ? Colors.black
                                  : Colors.black.withValues(alpha: 0.6),
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
            ),
          );
        },
      );
    });
  }

  String formatServerTime(dynamic serverTime) {
    if (serverTime == null) return "";

    late DateTime parsedTime;

    // CASE 1 — already DateTime
    if (serverTime is DateTime) {
      parsedTime = serverTime;
    }
    // CASE 2 — serverTime as String
    else {
      String timeStr = serverTime.toString().trim();

      if (!timeStr.contains('-') &&
          timeStr.contains(':') &&
          timeStr.length <= 5) {
        final today = DateTime.now();
        timeStr = "${today.toIso8601String().split('T')[0]}T$timeStr:00";
      }
      parsedTime = DateTime.parse(timeStr);
    }
    final DateTime localTime = parsedTime.toLocal();

    return _formatLocalTime(localTime);
  }

  String _formatLocalTime(DateTime localTime) {
    final now = DateTime.now();
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('d MMM yyyy');

    if (localTime.year == now.year &&
        localTime.month == now.month &&
        localTime.day == now.day) {
      return timeFormat.format(localTime);
    }

    if (now.difference(localTime).inDays == 1) {
      return "Yesterday";
    }
    return dateFormat.format(localTime);
  }

  void confirm(
    BuildContext context,
    List<dynamic> allChats,
    int index,
    String chatId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFC4C3C3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to delete?",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _dialogActions(
              context,
              onYes: () async {
                allChats.removeAt(index);
                final message = await controller.deleteChat(chatId);
                if (message == "success") {
                  // Get.back();
                  Get.offAll(() => MessageScreen());
                } else {
                  Get.back();
                  showSnackBar("ERROR $message", true);
                }
              },
            ),
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

  /// Helper for month names
  String monthName(int month) {
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
