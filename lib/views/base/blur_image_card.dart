import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/view_video.dart';

class BlurImageCard extends StatefulWidget {
  final ChatController chatController;
  final String imageUrl;
  final String msgId;
  final String receiverName;
  final String? receiverImage;
  final String thumbnail;
  final bool hasThumbnail;
  final String chatId;
  final bool isView;
  final bool isMe;
  final bool isReaction;

  const BlurImageCard({
    super.key,
    required this.imageUrl,
    required this.receiverName,
    required this.chatId,
    this.receiverImage,
    required this.isView,
    required this.msgId,
    required this.chatController,
    required this.isMe,
    required this.isReaction,
    required this.thumbnail,
    required this.hasThumbnail,
  });

  @override
  State<BlurImageCard> createState() => _BlurImageCardState();
}

class _BlurImageCardState extends State<BlurImageCard> {
  bool _isLoaded = false;
  bool _isTapped = false;

  void _onTapImage() {
    if (!_isLoaded || _isTapped) return;
    setState(() => _isTapped = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (widget.isMe == true) {
        Get.to(() => ViewMedia(mediaUrl: widget.imageUrl))?.then((_) {
          if (mounted) setState(() => _isTapped = false);
        });
      } else if (widget.isMe == false && widget.isReaction == true) {
        widget.chatController.updateChatView(widget.msgId);

        Get.to(() => ViewMedia(mediaUrl: widget.imageUrl))?.then((_) {
          if (mounted) setState(() => _isTapped = false);
        });
      } else {
        widget.chatController.updateChatView(widget.msgId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPreviewScreen(
              videoUrl: widget.imageUrl,
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
      onTap: _onTapImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageFiltered(
              imageFilter: widget.isView || widget.isReaction
                  ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                  : ImageFilter.blur(
                      sigmaX: 20,
                      sigmaY: 20,
                      tileMode: TileMode.decal,
                    ),
              child: Image.network(
                widget.hasThumbnail ? widget.thumbnail : widget.imageUrl,
                // widget.imageUrl,
                height: 260,
                width: 180,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) setState(() => _isLoaded = true);
                    });
                    return child;
                  } else {
                    return Container(
                      height: 260,
                      width: 180,
                      color: Colors.black12.withValues(alpha: .1),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  }
                },
                errorBuilder: (_, _, _) => Container(
                  height: 260,
                  width: 180,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
