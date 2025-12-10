import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/view_video.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class BlurVideoCard extends StatefulWidget {
  final ChatController chatController;
  final File videoFile;
  final Map<String, dynamic> msg;
  final String? receiverImage;
  final String receiverName;
  final String chatId;
  final String msgId;
  final String thumbnail;
  final bool hasThumbnail;
  final bool isView;
  final bool isMe;
  final bool isReaction;

  const BlurVideoCard({
    super.key,
    required this.videoFile,
    required this.msg,
    required this.receiverName,
    this.receiverImage,
    required this.chatId,
    required this.isView,
    required this.msgId,
    required this.chatController,
    required this.isMe,
    required this.isReaction,
    required this.thumbnail,
    required this.hasThumbnail,
  });

  @override
  State<BlurVideoCard> createState() => _BlurVideoCardState();
}

class _BlurVideoCardState extends State<BlurVideoCard> {
  bool _isTapped = false;
  bool _isLoading = true;
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  void checkThumbnail() {
    if (widget.hasThumbnail) {
      // setState(() {
      //   _thumbnailPath = widget.thumbnail;
      // });
      _thumbnailPath = widget.thumbnail;
    } else {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: widget.videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 0,
        maxWidth: 0,
        quality: 100,
      );
      if (!mounted) return;
      setState(() {
        _thumbnailPath = thumb;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Thumbnail generation error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Clean up the generated thumbnail file if it exists
    if (_thumbnailPath != null) {
      final file = File(_thumbnailPath!);
      if (file.existsSync()) {
        file.delete().then((_) {
          debugPrint("🧹 Deleted temp thumbnail file");
        });
      }
    }
    super.dispose();
  }

  void _onTapVideo() {
    if (_isTapped) return;
    setState(() => _isTapped = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (widget.isMe == true) {
        Get.to(() => ViewMedia(mediaUrl: widget.videoFile.path))?.then((_) {
          if (mounted) setState(() => _isTapped = false);
        });
      } else if (widget.isMe == false && widget.isReaction == true) {
        Get.to(() => ViewMedia(mediaUrl: widget.videoFile.path))?.then((_) {
          if (mounted) setState(() => _isTapped = false);
        });
      } else {
        widget.chatController.updateChatView(widget.msgId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPreviewScreen(
              videoUrl: widget.videoFile.path,
              countdownSeconds: 3,
              userProfile: widget.receiverImage ?? "",
              userName: widget.receiverName,
              chatId: widget.chatId,
              isInbox: true,
              postId: widget.msgId,
            ),
          ),
        ).then((_) {
          if (mounted) setState(() => _isTapped = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTapVideo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isLoading
                ? Container(
                    height: 260,
                    width: 180,
                    color: Colors.black12.withValues(alpha: .1),
                    child: Center(
                      child: SpinKitWave(
                        color: AppColors.primaryColor,
                        size: 30.0,
                      ),
                    ),
                  )
                : _thumbnailPath != null
                ? widget.hasThumbnail
                      ? ImageFiltered(
                          imageFilter: widget.isView || widget.isReaction
                              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                              : ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                  tileMode: TileMode.decal,
                                ),
                          child: Container(
                            height: 260,
                            width: 180,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(widget.thumbnail),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      : AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: 1.0,
                          child: ImageFiltered(
                            imageFilter: widget.isView
                                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                                : ImageFilter.blur(
                                    sigmaX: 20,
                                    sigmaY: 20,
                                    tileMode: TileMode.decal,
                                  ),
                            child: Image.file(
                              File(_thumbnailPath!),
                              height: 260,
                              width: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                : Container(
                    height: 260,
                    width: 180,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
          ),

          // ▶️ Play Button Overlay
          AnimatedOpacity(
            opacity: _isTapped ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
