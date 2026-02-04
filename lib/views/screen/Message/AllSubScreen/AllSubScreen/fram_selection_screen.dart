import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import 'package:video_player_hdr/video_player_hdr.dart';
import 'package:ree_social_media_app/controllers/send_message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_loading.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../Camera/AllSubScreen/send_message_with_friend_screen.dart';

class FrameSelectionScreen extends StatefulWidget {
  final String frontVideoUrl;
  final File? thumbnail;
  final String userProfile;
  final String userName;
  final String? chatId;
  final bool? isInbox;

  const FrameSelectionScreen({
    super.key,
    required this.userProfile,
    required this.userName,
    required this.frontVideoUrl,
    this.isInbox = false,
    this.chatId,
    this.thumbnail,
  });

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final sendMessageController = Get.put(SendMessageController());
  final ScrollController _scrollController = ScrollController();
  final List<String> _thumbnailPaths = [];
  bool _isInitialized = false;
  int _selectedFrameIndex = 0;
  final double _thumbnailWidth = 60.0;

  Duration? _videoDuration;

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    // await _requestPermissions();
    await _loadVideoDuration();
    await _generateThumbnails();
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _loadVideoDuration() async {
    final controller = widget.frontVideoUrl.startsWith('http')
        ? VideoPlayerHdrController.networkUrl(Uri.parse(widget.frontVideoUrl))
        : VideoPlayerHdrController.file(File(widget.frontVideoUrl));

    await controller.initialize();
    _videoDuration = controller.value.duration;
    await controller.dispose();
  }

  Future<void> _generateThumbnails() async {
    if (_videoDuration == null) return;

    _thumbnailPaths.clear();

    final totalSeconds = _videoDuration!.inSeconds;
    debugPrint("🎞 Generating thumbnails for $totalSeconds seconds...");

    for (int i = 0; i <= totalSeconds; i++) {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.frontVideoUrl,
        imageFormat: ImageFormat.PNG,
        timeMs: i * 1000,
        maxHeight: 0,
        maxWidth: 0,
        quality: 100,
        thumbnailPath:
            '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_$i.png',
      );

      if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
        _thumbnailPaths.add(thumbnailPath);
      }
    }

    debugPrint("Generated ${_thumbnailPaths.length} thumbnails.");

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,

        body: Center(
          child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildAppBarTitle(),
      ),
      body: Column(
        children: [
          // Big preview
          Expanded(
            child: _thumbnailPaths.isEmpty
                ? const Center(child: Text("No frames available"))
                : Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Image.file(
                        File(_thumbnailPaths[_selectedFrameIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() => Row(
    children: [
      ReBack(onTap: () => Get.back()),
      const SizedBox(width: 12),
      CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primaryColor,
        backgroundImage: widget.userProfile.isEmpty
            ? null
            : NetworkImage(widget.userProfile),
        child: widget.userProfile.isEmpty
            ? Text(
                widget.userName[0].toUpperCase(),
                style: TextStyle(fontFamily: "LibreText"),
              )
            : null,
      ),
      const SizedBox(width: 12),
      Text(
        widget.userName,
        style: const TextStyle(
          color: Color(0xFF413E3E),
          fontSize: 24,
          fontFamily: "LibreText",
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _buildBottomControls() => Container(
    color: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    child: SafeArea(
      child: Row(
        children: [
          _buildFrameSelector(),
          SizedBox(width: 12),
          IconButton(
            onPressed: () => Get.offAllNamed(AppRoutes.messageScreen),
            icon: SvgPicture.asset(
              'assets/icons/delete2.svg',
              // ignore: deprecated_member_use
              color: AppColors.primaryColor,
              height: 24,
            ),
          ),
          SizedBox(width: 12),
          Obx(
            () => InkWell(
              onTap: _handleFrameAndSend,
              child: sendMessageController.isLoading.value
                  ? CustomLoading()
                  : SvgPicture.asset(
                      'assets/icons/send.svg',
                      // ignore: deprecated_member_use
                      color: AppColors.primaryColor,
                      height: 24,
                    ),
            ),
          ),
          Spacer(),
        ],
      ),
    ),
  );

  Widget _buildFrameSelector() {
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width / 1.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: _thumbnailPaths.length,
          itemBuilder: (_, i) {
            final isSelected = i == _selectedFrameIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedFrameIndex = i),
              child: Container(
                width: _thumbnailWidth,
                // margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  // borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  // borderRadius: BorderRadius.circular(0),
                  child: Image.file(
                    File(_thumbnailPaths[i]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleFrameAndSend() async {
    final selectedFrame = _thumbnailPaths[_selectedFrameIndex];
    if (widget.isInbox == true || widget.chatId!.isNotEmpty) {
      await sendMessageController.sendMediaToSingleChat(
        thumbnail: widget.thumbnail!,
        chatId: widget.chatId.toString(),
        filePath: selectedFrame,
        isVideo: false,
        isReaction: true,
      );
    } else {
      await Get.to(
        () => SendMessageWithFriendScreen(
          filePath: selectedFrame,
          thumbnail: widget.thumbnail!,
          isVideo: false,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    }
  }
}
