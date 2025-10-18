import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/controllers/camera_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Camera/AllSubScreen/send_message_with_friend_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';


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
    VideoPlayerController? _frontVideoController;
    final GlobalKey _videoPreviewKey = GlobalKey();
  int _selectedTab = 0;

  final List<String> _thumbnailPaths = [];
  final Trimmer _trimmer = Trimmer();

  bool _isInitialized = false;
  double _leftHandle = 0.0;
  double _rightHandle = 100.0;
  double _trimStart = 0.0;
  double _trimEnd = 1.0;

  final double _thumbnailWidth = 60.0;
  final double thumbnailHeight = 80.0;

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
      if (mounted) {
        _isPlaying.value = _videoController.value.isPlaying;
      }
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
  if (!_videoController.value.isInitialized) return;

  _thumbnailPaths.clear();

  final totalDuration = _videoController.value.duration.inMilliseconds;
  const int count = 10;
  final int interval = (totalDuration / count).floor();
  final dir = await getTemporaryDirectory();

  for (int i = 0; i < count; i++) {
    await _videoController.seekTo(Duration(milliseconds: i * interval));
    await Future.delayed(const Duration(milliseconds: 150)); // allow frame to render

    final boundary = _videoPreviewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) continue;

    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    if (pngBytes == null) continue;

    final file = File('${dir.path}/thumb_$i.png');
    await file.writeAsBytes(pngBytes);
    _thumbnailPaths.add(file.path);
  }

  if (mounted) setState(() {});
}



  /// ⏱️ Format Duration (mm:ss)
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// ✂️ Trim the video using FFmpeg
     Future<File?> _trimFrontVideo(File inputFile) async {
    try {
      await _trimmer.loadVideo(videoFile: inputFile);
  
      final duration = _frontVideoController?.value.duration ?? Duration.zero;
      final start = duration * _trimStart;
      final end = duration * _trimEnd;
  
      debugPrint("🎬 Trimming from ${start.inSeconds}s → ${end.inSeconds}s");
      // saveTrimmedVideo returns void in newer video_trimmer versions; use a Completer to capture the path from the onSave callback.
      final Completer<String?> _completer = Completer<String?>();
  
      _trimmer.saveTrimmedVideo(
        startValue: start.inMilliseconds / 1000,
        endValue: end.inMilliseconds / 1000,
        videoFileName: "trimmed_${DateTime.now().millisecondsSinceEpoch}",
        onSave: (String? path) {
          debugPrint("🔔 onSave callback: $path");
          if (!_completer.isCompleted) _completer.complete(path);
        },
      );
  
      String? outputPath;
      try {
        // await the completer which will be completed by the onSave/onError callbacks
        outputPath = await _completer.future.timeout(const Duration(seconds: 30));
      } catch (e) {
        debugPrint("❌ Trimming timed out or failed: $e");
        outputPath = null;
      }
  
      if (outputPath != null && outputPath.isNotEmpty) {
        debugPrint("✅ Trimmed video saved at: $outputPath");
        return File(outputPath);
      } else {
        debugPrint("❌ Trimming failed (outputPath is null or empty)");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Trimming error: $e");
      return null;
    }
  }

  /// 🎞️ Video preview player
  Widget _buildVideoPreview() {
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: VideoPlayer(_videoController),
      ),
    );
  }

  /// 🎮 Video controls
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
            builder: (_, playing, __) => InkWell(
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

  /// ✂️ Trim Slider
  Widget _buildTrimSlider() {
    final total = _thumbnailPaths.length * (_thumbnailWidth + 2);

    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🟦 Outer blue rounded rail
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _thumbnailPaths.length,
                    itemBuilder: (_, i) => Container(
                      width: _thumbnailWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: Image.file(
                        File(_thumbnailPaths[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🌈 Light blue selected area
          Positioned(
            left: _leftHandle,
            width: _rightHandle - _leftHandle,
            top: 15,
            bottom: 15,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // ◀ Left arrow
          Positioned(
            left: 0,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset - 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Icon(Icons.chevron_left, color: Colors.white, size: 32),
            ),
          ),

          // ▶ Right arrow
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  (_scrollController.offset + 100).clamp(0, double.infinity),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Icon(Icons.chevron_right, color: Colors.white, size: 32),
            ),
          ),

          // 🔹 Left handle
          Positioned(
            left: _leftHandle,
            top: 8,
            bottom: 8,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftHandle += details.delta.dx;
                  _leftHandle = _leftHandle.clamp(0.0, _rightHandle - 30);
                  _trimStart = (_leftHandle / total).clamp(0.0, 1.0);
                });
              },
              child: _buildTrimHandle(),
            ),
          ),

          // 🔹 Right handle
          Positioned(
            left: _rightHandle - 8,
            top: 8,
            bottom: 8,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _rightHandle += details.delta.dx;
                  _rightHandle = _rightHandle.clamp(_leftHandle + 30, total);
                  _trimEnd = (_rightHandle / total).clamp(0.0, 1.0);
                });
              },
              child: _buildTrimHandle(),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Handle UI (Dot + Bar + Dot)
  Widget _buildTrimHandle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 5,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  /// 🔵 Circular handle builder (exactly like your screenshot)
  Widget _buildCircularHandle() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.drag_handle_rounded,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  /// 🧭 Action Buttons (Send / Create Story)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          InkWell(
            onTap: _handleTrimAndSend,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "Send Message",
                  style: TextStyle(color: Colors.black54, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          CustomButton(
            onTap: () => _storyController.addStory(videoPath: widget.videoUrl),
            text: "Create Story",
          ),
        ],
      ),
    );
  }

  /// 📤 Trim & Send
  Future<void> _handleTrimAndSend() async {
    final originalFile = File(widget.videoUrl);
    Get.snackbar(
      "Processing",
      "Trimming video... please wait.",
      snackPosition: SnackPosition.BOTTOM,
    );

    final trimmedFile = await _trimFrontVideo(originalFile);

    if (trimmedFile != null) {
      Get.to(
        () => SendMessageWithFriendScreen(
          filePath: trimmedFile.path,
          isVideo: true,
        ),
      );
    } else {
      Get.snackbar("Error", "Failed to trim video.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                _buildTabs(),
                // SizedBox(height: 10),
                _buildTrimSlider(),
              ],
            ),
          ),

          _buildVideoControls(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // 🔹 Tabs ("Use trim" / "Use frame")
  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabButton("Use trim", 0),
        const SizedBox(width: 18),
        _buildTabButton("Use frame", 1),
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.lightBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.lightBlue : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
