import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/controllers/story_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Camera/AllSubScreen/send_message_with_friend_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoTrimAndSendScreen extends StatefulWidget {
  final String videoUrl;

  const VideoTrimAndSendScreen({super.key, required this.videoUrl});

  @override
  State<VideoTrimAndSendScreen> createState() => _VideoTrimAndSendScreenState();
}

class _VideoTrimAndSendScreenState extends State<VideoTrimAndSendScreen> {
  final CreateStoryController _storyController = Get.put(
    CreateStoryController(),
  );
  late VideoPlayerController _videoController;
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final List<String> _thumbnailPaths = [];
  int _selectedFrameIndex = 0;

  bool _isInitialized = false;
  final double _thumbnailWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    await _requestPermissions();

    _videoController = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    await _videoController.initialize();
    await _generateThumbnails();

    _videoController.addListener(() {
      if (mounted) _isPlaying.value = _videoController.value.isPlaying;
    });

    setState(() => _isInitialized = true);
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    if (statuses.values.any((status) => status != PermissionStatus.granted)) {
      Get.snackbar(
        "Permission Denied",
        "Camera & Storage permissions are required.",
      );
      Get.back();
    }
  }

  Future<void> _generateThumbnails() async {
    _thumbnailPaths.clear();
    final totalDuration = _videoController.value.duration.inMilliseconds;
    const int count = 10;
    final interval = (totalDuration / count).floor();

    for (int i = 0; i < count; i++) {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        maxHeight: 0,
        maxWidth: 0,
        quality: 100,
        timeMs: i * interval,
      );
      if (path != null) _thumbnailPaths.add(path);
    }
    setState(() {});
  }

  /// Format Duration (mm:ss)
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Video preview player
  Widget _buildVideoPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_videoController.value.isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildVideoControls(), // your existing video controls slider
        ),
      ],
    );
  }

  /// Video controls
  Widget _buildVideoControls() {
    final duration = _videoController.value.duration;
    final position = _videoController.value.position;
    final progress = (position.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            _formatDuration(position),
            style: const TextStyle(color: Colors.black54),
          ),
          Expanded(
            child: Slider(
              value: progress,
              onChanged: (v) {
                _videoController.seekTo(
                  Duration(milliseconds: (duration.inMilliseconds * v).toInt()),
                );
              },
              activeColor: AppColors.primaryColor,
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<bool>(
            valueListenable: _isPlaying,
            builder: (_, playing, _) => InkWell(
              onTap: () async {
                if (playing) {
                  await _videoController.pause();
                } else {
                  await _videoController.play();
                }
                _isPlaying.value = _videoController.value.isPlaying;
              },
              child: CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                child: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thumbnails frame selector
  Widget _buildFrameSelector() {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🟦 Outer rail background
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _thumbnailPaths.length,
                  itemBuilder: (_, i) {
                    final isSelected = i == _selectedFrameIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFrameIndex = i;
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: _thumbnailWidth,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(_thumbnailPaths[i]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: .015),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ◀ Left scroll arrow
          Positioned(
            left: -5,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset - 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // ▶ Right scroll arrow
          Positioned(
            right: -5,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset + 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Action Buttons
  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildFrameSelector(),
          InkWell(
            onTap: _sendSelectedFrame,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "Send Selected Frame",
                  style: TextStyle(color: Colors.black54, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SafeArea(
            child: Obx(
              () => CustomButton(
                loading: _storyController.isLoading.value,
                onTap: () {
                  if (_thumbnailPaths.isEmpty) return;
                  final selectedFrame = _thumbnailPaths[_selectedFrameIndex];
                  _storyController.addStory(imagePath: selectedFrame);
                },
                text: "Create Story",
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Send selected frame as image
  void _sendSelectedFrame() async {
    if (_thumbnailPaths.isEmpty) return;
    final selectedFrame = _thumbnailPaths[_selectedFrameIndex];
    Get.to(
      () =>
          SendMessageWithFriendScreen(filePath: selectedFrame, isVideo: false),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,

        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Trim & Send Video",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildVideoPreview()),
          _buildActionButtons(),
        ],
      ),
    );
  }
}
