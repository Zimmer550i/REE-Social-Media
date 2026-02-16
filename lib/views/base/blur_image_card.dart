import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  final String? caption;
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
    required this.hasThumbnail, this.caption,
  });

  @override
  State<BlurImageCard> createState() => _BlurImageCardState();
}

class _BlurImageCardState extends State<BlurImageCard> {
  bool _isLoaded = false;
  bool _isNavigating = false;
  bool _isTapped = false;

  void _onTapImage() {
    if (!_isLoaded || _isTapped || _isNavigating) return;
    setState(() {
      _isTapped = true;
      _isNavigating = true;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (widget.isMe == true) {
        Get.to(() => ViewMedia(mediaUrl: widget.imageUrl,caption: widget.caption,))?.then((_) {
          if (!mounted) return;
          setState(() {
            _isTapped = false;
            _isNavigating = false;
          });
        });
      } else if (widget.isMe == false && widget.isReaction == true) {
        widget.chatController.updateChatView(widget.msgId);

        Get.to(() => ViewMedia(mediaUrl: widget.imageUrl,caption: widget.caption,))?.then((_) {
          if (!mounted) return;
          setState(() {
            _isTapped = false;
            _isNavigating = false;
          });
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
              caption: widget.caption,
            ),
          ),
        ).then((_) {
          if (!mounted) return;
          setState(() {
            _isTapped = false;
            _isNavigating = false;
          });
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
                height: 260,
                width: 180,
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  // Mark loaded once we have at least one rendered frame.
                  if (!_isLoaded && (wasSynchronouslyLoaded || frame != null)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _isLoaded = true);
                    });
                  }
                  return child;
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 260,
                    width: 180,
                    color: Colors.black12.withValues(alpha: .1),
                    child: Center(
                      child: SpinKitWave(
                        color: AppColors.primaryColor,
                        size: 30.0,
                      ),
                    ),
                  );
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
