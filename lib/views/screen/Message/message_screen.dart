import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/chat_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/groupChat/group_chat.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:http/http.dart' as http;
import '../../../services/one_signal_manager.dart';
import '../../../services/shared_prefs_service.dart';
import '../../base/bottom_menu.dart';
import '../Notification/notification_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with WidgetsBindingObserver {
  final MessageController controller = Get.put(MessageController());
  final UserController userController = Get.put(UserController());
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );

  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _storyScrollController = ScrollController();

  bool _isFetchingMoreChats = false;
  bool _isFetchingMoreStories = false;
  Timer? _pollingTimer;

  // videoUrl -> localFilePath (for cached stories)
  Map<String, String> _cachedVideos = {};

  // which story is currently downloading/playing (for loader in play button)
  String? _loadingStoryId;

  // UI caches for stories and chats (prevent unnecessary UI refresh when data is identical)
  List<dynamic> _storiesUiCache = [];
  String _storiesSignature = "";

  List<dynamic> _chatsUiCache = [];
  String _chatsSignature = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadCachedVideos();
    notificationController.fetchNotifications();

    // Pagination listener for chats (only trigger when user is scrolling downward near the bottom)
    _chatScrollController.addListener(() {
      final position = _chatScrollController.position;

      if (position.userScrollDirection == ScrollDirection.reverse &&
          position.pixels >= position.maxScrollExtent - 50 &&
          !_isFetchingMoreChats &&
          !controller.isLoadingChats.value &&
          controller.hasMoreChats.value) {
        _loadMoreChats();
      }
    });

    // Pagination listener for stories (only trigger when truly at end edge)
    _storyScrollController.addListener(() {
      if (_storyScrollController.position.atEdge &&
          _storyScrollController.position.pixels != 0 &&
          !_isFetchingMoreStories &&
          controller.hasMoreStories.value) {
        _loadMoreStories();
      }
    });

    userController.setSubscriptionId();
    enablePushNotification();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  Future<void> _loadCachedVideos() async {
    try {
      final jsonStr = await SharedPrefsService.get('cached_story_videos');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(jsonStr);
        _cachedVideos = data.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      debugPrint('⚠️ Error loading cached videos: $e');
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      controller.fetchChats(loadMore: false, silent: true);
      controller.fetchStories(loadMore: false, silent: true);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void enablePushNotification() async {
    await SharedPrefsService.set('push_notifications_status', 'true');
    OneSignalHelper.requestPushPermission();
    OneSignalHelper.optIn();
  }

  Future<void> _loadMoreChats() async {
    if (_isFetchingMoreChats) return;
    _isFetchingMoreChats = true;
    await controller.fetchChats(loadMore: true, silent: true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _isFetchingMoreChats = false);
  }

  Future<void> _loadMoreStories() async {
    if (_isFetchingMoreStories) return;
    _isFetchingMoreStories = true;
    await controller.fetchStories(loadMore: true, silent: true);
    if (mounted) setState(() => _isFetchingMoreStories = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    GlobalVideoPlayerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
                          style: const TextStyle(
                            color: Color(0xFF413E3E),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            fontFamily: "LibreText",
                          ),
                        ),
                        _buildChatList(),
                        // if (_isFetchingMoreChats)
                        //   Center(
                        //     child: Padding(
                        //       padding: const EdgeInsets.all(12.0),
                        //       child: CircularProgressIndicator(
                        //         color: AppColors.primaryColor,
                        //       ),
                        //     ),
                        //   ),
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
                  style: const TextStyle(
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

  /// Stories Section (with cache-based update)
  Widget _buildStoriesSection() {
    return Obx(() {
      final rawStories = controller.stories;

      // Build a signature only from stable fields (id + updatedAt/createdAt)
      final newSignature = rawStories
          .map((s) {
            final map = s as Map<dynamic, dynamic>;
            final id = map["_id"]?.toString() ?? "";
            final updatedAt =
                map["updatedAt"]?.toString() ??
                map["createdAt"]?.toString() ??
                "";
            return "$id-$updatedAt";
          })
          .join("|");

      // Only update UI cache when signature changes (i.e., new data from API)
      if (newSignature != _storiesSignature) {
        _storiesSignature = newSignature;
        _storiesUiCache = List<dynamic>.from(rawStories);
      }

      // Filter out stories from the logged-in user using cached list
      final currentUserId = userController.userInfo.value!.id;
      final filteredStories = _storiesUiCache
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
                style: const TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: "LibreText",
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: Skeletonizer(
              enabled:
                  controller.isLoadingStories.value && _storiesUiCache.isEmpty,
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
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          )
                        : const SizedBox();
                  }

                  var story = filteredStories[index - 1];
                  final isVideo = story["contentType"] == "video";
                  // ignore: prefer_typing_uninitialized_variables
                  late final String mediaUrl;

                  if (Platform.isIOS) {
                    mediaUrl = (story["image_ios"] ?? "").isNotEmpty
                        ? story["image_ios"]
                        : story["video_ios"];
                  } else {
                    mediaUrl = (story["image"] ?? "").isNotEmpty
                        ? story["image"]
                        : story["video"];
                  }
                  debugPrint("=====> videoUrl: $mediaUrl");

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

  // Add Story Card
  Widget _buildAddStoryCard() {
    final image = userController.userInfo.value!.image;
    final userImage = userController.addBaseUrl(image.toString());
    final currentUserId = userController.userInfo.value!.id;
    final userName = userController.userInfo.value!.name ?? "";
    final hasImage =
        image != null &&
        image.toString().isNotEmpty &&
        image.toString() != "null";
    const double cardW = 100;
    const double cardH = 132;
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
      width: cardW,
      height: cardH,
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
        // image: DecorationImage(
        //   image: NetworkImage(userImage.toString()),
        //   fit: BoxFit.cover,
        // ),
      ),
      child: Stack(
        children: [
          ///Background (Image OR Initials)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              topLeft: Radius.circular(8),
            ),
            child: hasImage
                ? Image.network(
                    userImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsBackground(userName),
                  )
                : _initialsBackground(userName),
          ),
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

          // Right side (background image) tap to open user's own stories
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

  Widget _initialsBackground(String name) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Center(
        child: Text(
          getInitials(name),
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String getInitials(String name) {
    if (name.trim().isEmpty) return "";

    List<String> parts = name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildStoryCard(
    String mediaUrl,
    String name,
    String authorImage,
    bool isVideo,
    String authorId,
    String postId,
  ) {
    const double cardW = 100;
    const double cardH = 132;

    if (isVideo) {
      // Directly build the video story card (no FutureBuilder)
      return _buildVideoCardWidget(
        name,
        authorImage,
        authorId,
        mediaUrl,
        cardW,
        cardH,
        32,
        postId,
      );
    } else {
      // Directly build the image story card (no FutureBuilder)
      return _buildImageStoryWidget(
        mediaUrl,
        name,
        authorImage,
        authorId,
        postId,
      );
    }
  }

  /// Handles image story preview
  Widget _buildImageStoryWidget(
    String mediaUrl,
    String name,
    String image,
    String authorId,
    String postId,
  ) {
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
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            topLeft: Radius.circular(8),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              (image.isNotEmpty && image != 'null')
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade800,
                        child: Center(
                          child: Text(
                            getInitials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade800,
                      child: Center(
                        child: Text(
                          getInitials(name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
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

  Future<String> _downloadAndCacheVideo(String url) async {
    final file = await _downloadVideoToLocal(url);
    _cachedVideos[url] = file.path;
    try {
      final jsonStr = json.encode(_cachedVideos);
      await SharedPrefsService.set('cached_story_videos', jsonStr);
    } catch (e) {
      debugPrint('⚠️ Error saving cached videos: $e');
    }
    return file.path;
  }

  /// Video story card (uses author image + play button + loader state)
  Widget _buildVideoCardWidget(
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
      onTap: () async {
        setState(() => _loadingStoryId = postId);

        String playPath = videoUrl;

        try {
          if (_cachedVideos.containsKey(videoUrl)) {
            final localPath = _cachedVideos[videoUrl]!;
            final file = File(localPath);

            if (await file.exists()) {
              playPath = localPath;
            } else {
              playPath = await _downloadAndCacheVideo(videoUrl);
            }
          } else {
            playPath = await _downloadAndCacheVideo(videoUrl);
          }

          await Get.to(
            () => VideoPreviewScreen(
              videoUrl: playPath,
              countdownSeconds: 3,
              userProfile: image,
              userName: name,
              chatId: authorId,
              postId: postId,
            ),
          );
        } catch (e) {
          debugPrint('⚠️ Error downloading video story: $e');
          playPath = videoUrl;
        } finally {
          if (mounted) {
            setState(() => _loadingStoryId = null);
          }
        }
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
              // Background: author image (same as before)
              Image.network(
                image,
                fit: BoxFit.cover,
                // ignore: unnecessary_underscores
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white54),
                  ),
                ),
              ),

              // Center play button / loader
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _loadingStoryId == postId
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),

              // Bottom name bar (unchanged)
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

  /// Safe temp video downloader (now actually used)
  Future<File> _downloadVideoToLocal(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();

    // Try to detect extension from URL
    String extension = url.split('.').last.split('?').first;

    // If extension looks invalid, fallback by platform
    if (extension.length > 5 || extension.contains('/')) {
      extension = Platform.isIOS ? 'mov' : 'mp4';
    }

    final file = File(
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$extension",
    );

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Chats Section (with cache-based update)
  Widget _buildChatList() {
    final currentUserId = userController.userInfo.value?.id ?? "";

    return Obx(() {
      // Show skeleton only on first load
      if (controller.isLoadingChats.value && _chatsUiCache.isEmpty) {
        // Skeleton loading placeholder while chats are fetching
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

      final combined = [...controller.privateChats, ...controller.groupChats];

      // Build signature using chat id + lastMessage id/timestamp to detect real changes
      final newSignature = combined
          .map((chat) {
            final map = chat as Map<dynamic, dynamic>;
            final id = map["_id"]?.toString() ?? "";
            final last = map["lastMessage"] as Map<dynamic, dynamic>?;
            final lastId = last?["_id"]?.toString() ?? "";
            final lastUpdated =
                last?["updatedAt"]?.toString() ??
                last?["createdAt"]?.toString() ??
                "";
            return "$id-$lastId-$lastUpdated";
          })
          .join("|");

      if (newSignature != _chatsSignature) {
        _chatsSignature = newSignature;
        _chatsUiCache = List<dynamic>.from(combined);
      }

      // Work on a local copy to sort without touching controller lists
      final allChats = List<dynamic>.from(_chatsUiCache);

      allChats.sort((a, b) {
        final aTime =
            DateTime.tryParse(a["lastMessage"]?["createdAt"] ?? "") ??
            DateTime(1900);
        final bTime =
            DateTime.tryParse(b["lastMessage"]?["createdAt"] ?? "") ??
            DateTime(1900);
        return bTime.compareTo(aTime);
      });

      if (!controller.isRefreshingLoading.value && allChats.isEmpty) {
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
                      child: image.isEmpty || image == "null"
                          ? Text(
                              getInitials(name),
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
    } else {
      // CASE 2 — serverTime as String
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
                // Optimistically remove from UI caches
                _chatsUiCache.removeWhere((c) => c["_id"] == chatId);
                controller.privateChats.removeWhere((c) => c["_id"] == chatId);
                controller.groupChats.removeWhere((c) => c["_id"] == chatId);
                Get.back();

                setState(() {});
                final message = await controller.deleteChat(chatId);

                if (message != "success") {
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
