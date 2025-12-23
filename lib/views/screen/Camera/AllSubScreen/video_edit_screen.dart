import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/send_message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Camera/AllSubScreen/send_message_with_friend_screen.dart';
import 'package:video_player/video_player.dart';
import '../../../../controllers/story_controller.dart';
import '../../../../helpers/route.dart';
import '../../../../utils/file_utils.dart';

class VideoEditScreen extends StatefulWidget {
  final String? chatId;
  final String filePath;
  final bool isVideo;
  final bool isChatBox;

  const VideoEditScreen({
    super.key,
    required this.filePath,
    this.isVideo = false,
    required this.isChatBox,
    this.chatId,
  });

  @override
  State<VideoEditScreen> createState() => _SendOrTrimVideoScreenState();
}

class _SendOrTrimVideoScreenState extends State<VideoEditScreen> {
  final CreateStoryController createStoryController = Get.put(
    CreateStoryController(),
  );
  final SendMessageController sendMessageController = Get.put(
    SendMessageController(),
  );
  final MessageController messageController = Get.find<MessageController>();
  CameraController? _frontCam;
  VideoPlayerController? _video;

  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;
  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initFlow();
    }
    messageController.fetchStories();
  }

  Future<void> _initFlow() async {
    await _initVideo();
    //await startBackgroundVideo();
  }

  Future<void> _initVideo() async {
    if (widget.filePath.startsWith('http')) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.filePath));
    } else {
      _video = VideoPlayerController.file(File(widget.filePath));
    }
    await _video!.initialize();
    _videoDuration = _video!.value.duration;
    _video!.setLooping(false);

    _video!.addListener(() {
      if (!mounted) return;
      setState(() {
        _position = _video!.value.position;
      });
      _isPlaying.value = _video!.value.isPlaying;
    });
    if (mounted) setState(() {});
  }

  Future<void> startBackgroundVideo() async {
    if (_video != null && _video!.value.isInitialized) {
      await _video!.play();
    }
  }

  @override
  void dispose() {
    if (widget.isVideo) {
      _video?.removeListener(() {});
      _video?.dispose();
    }

    () async {
      try {
        if (_frontCam?.value.isRecordingVideo == true) {
          await _frontCam?.stopVideoRecording();
        }
      } catch (_) {}
      _frontCam?.dispose();
    }();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: widget.isVideo
                ? (_video != null && _video!.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _video!.value.size.width,
                            height: _video!.value.size.height,
                            child: VideoPlayer(_video!),
                          ),
                        )
                      : Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        ))
                : Image.file(File(widget.filePath), fit: BoxFit.contain),
          ),

          /// Close button
          Positioned(
            top: 70,
            right: 20,
            child: InkWell(
              onTap: () {
                Get.offAllNamed(AppRoutes.messageScreen);
              },
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                ),
                child: const Center(
                  child: Icon(Icons.close, color: Color(0xFF676565)),
                ),
              ),
            ),
          ),

          /// Bottom controls (only if video)
          if (widget.isVideo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),

          if (!widget.isVideo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Platform.isAndroid
                  ? SafeArea(child: _buildBottomActions())
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: _buildBottomActions(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,

    children: [
      InkWell(
        onTap: () {
          if (widget.isVideo) {
            createStoryController.addStory(videoPath: widget.filePath);
          } else {
            createStoryController.addStory(imagePath: widget.filePath);
          }
        },
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.grey,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Obx(
                () => createStoryController.isLoading.value
                    ? SpinKitWave(color: Colors.white, size: 16.0)
                    : Text(
                        "Add Story",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),

      // Send button
      InkWell(
        onTap: widget.isChatBox
            ? () {
                sendMessageController.sendMediaToSingleChat(
                  chatId: widget.chatId!,
                  filePath: widget.filePath,
                  isVideo: widget.isVideo,
                  thumbnail: null,
                  isReaction: false,
                );
              }
            : () async {
                try {
                  if (widget.isVideo) {
                    final formattedFile = await ensureMp4Format(
                      widget.filePath,
                    );
                    Get.to(
                      () => SendMessageWithFriendScreen(
                        filePath: formattedFile.path,
                        isVideo: widget.isVideo,
                      ),
                    );
                  } else {
                    Get.to(
                      () => SendMessageWithFriendScreen(
                        filePath: widget.filePath,
                        isVideo: widget.isVideo,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('⚠️ Could not format video: $e');
                }
              },
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: AppColors.primaryColor,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Obx(() {
                final loading2 = sendMessageController.isLoading.value;
                if (loading2) {
                  return const SpinKitWave(color: Colors.white, size: 16.0);
                }
                return Text(
                  "Send Now",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ],
  );

  /// ==== Video Controls ====
  Widget _buildBottomControls() {
    final total = _videoDuration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    final value = _position.inMilliseconds.toDouble().clamp(0, total);

    return Container(
      decoration: BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Progress / Seek
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  _fmt(_position),
                  style: const TextStyle(
                    color: Color(0xFF413E3E),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: total.toDouble(),
                    activeColor: const Color(0xFF413E3E),
                    inactiveColor: const Color(0xFF413E3E),
                    thumbColor: const Color(0xFFD9D9D9),
                    onChanged: (v) {
                      final pos = Duration(milliseconds: v.toInt());
                      _video?.seekTo(pos);
                    },
                  ),
                ),
                Text(
                  _fmt(_videoDuration),
                  style: const TextStyle(
                    color: Color(0xFF413E3E),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlaying,
                  builder: (_, playing, _) {
                    return CircleAvatar(
                      backgroundColor: AppColors.primaryColor,
                      child: IconButton(
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          if (playing) {
                            await _video?.pause();
                          } else {
                            await _video?.play();
                          }
                          _isPlaying.value = _video?.value.isPlaying ?? false;
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildBottomActions(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
