// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ree_social_media_app/controllers/send_message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import 'package:video_player/video_player.dart';
import 'fram_selection_screen.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

class SendOrTrimVideoScreen extends StatefulWidget {
  final String mainVideo;
  final String reactionVideo;
  final String userProfile;
  final String userName;
  final String chatId;
  final String postId;
  final bool? isInbox;
  final bool? isVideo;

  const SendOrTrimVideoScreen({
    super.key,
    required this.mainVideo,
    required this.userProfile,
    required this.userName,
    required this.chatId,
    required this.postId,
    required this.reactionVideo,
    this.isInbox,
    this.isVideo,
  });

  @override
  State<SendOrTrimVideoScreen> createState() => _SendOrTrimVideoScreenState();
}

class _SendOrTrimVideoScreenState extends State<SendOrTrimVideoScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  File? thumbnail;
  VideoPlayerController? _mainVideoController;
  VideoPlayerController? _reactionVideoController;
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final sendMessageController = Get.put(SendMessageController());
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.isVideo == true
        ? _initializeVideos()
        : _initializeOnlyReactionVideos();
  }

  @override
  void dispose() {
    _mainVideoController?.removeListener(_syncVideos);
    _reactionVideoController?.removeListener(_syncVideos);
    _mainVideoController?.dispose();
    _reactionVideoController?.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  Future<void> _captureAndSaveScreenshot() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save file to app's temp directory
      final dir = await getTemporaryDirectory();
      final filePath =
          "${dir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.png";

      thumbnail = File(filePath);
      await thumbnail!.writeAsBytes(pngBytes);

      debugPrint("📸 thumbnail saved at: $filePath");
    } catch (e) {
      debugPrint("❌ thumbnail error: $e");
    }
  }

  Future<void> _initializeOnlyReactionVideos() async {
    try {
      // Reaction video (background)
      _reactionVideoController = widget.reactionVideo.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.reactionVideo))
          : VideoPlayerController.file(File(widget.reactionVideo));

      await Future.wait([_reactionVideoController!.initialize()]);

      // Check if both videos are initialized successfully
      if (!_reactionVideoController!.value.isInitialized) {
        throw Exception('Error: Video(s) not initialized properly.');
      }
      _reactionVideoController!.setLooping(false);

      _videoDuration = _reactionVideoController!.value.duration;
      _reactionVideoController!.addListener(_syncReactionVideos);

      // Start both videos paused
      _isPlaying.value = false;
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error initializing videos: $e");
      // Handle error if video initialization fails
    }
  }

  Future<void> _initializeVideos() async {
    try {
      // Main video (background)
      _mainVideoController = widget.mainVideo.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.mainVideo))
          : VideoPlayerController.file(File(widget.mainVideo));

      // Reaction video (background)
      _reactionVideoController = widget.reactionVideo.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.reactionVideo))
          : VideoPlayerController.file(File(widget.reactionVideo));

      await Future.wait([
        _mainVideoController!.initialize(),
        _reactionVideoController!.initialize(),
      ]);

      // Check if both videos are initialized successfully
      if (!_mainVideoController!.value.isInitialized ||
          !_reactionVideoController!.value.isInitialized) {
        throw Exception('Error: Video(s) not initialized properly.');
      }

      _mainVideoController?.setVolume(0.0);
      // Loop both videos
      _mainVideoController!.setLooping(false);
      _reactionVideoController!.setLooping(false);

      _videoDuration = _reactionVideoController!.value.duration;

      // Listen to reaction video to sync main video
      _reactionVideoController!.addListener(_syncVideos);

      // Start both videos paused
      _isPlaying.value = false;
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error initializing videos: $e");
      // Handle error if video initialization fails
    }
  }

  void _syncVideos() async {
    if (_reactionVideoController == null || _mainVideoController == null)
      return;
    if (!_reactionVideoController!.value.isInitialized ||
        !_mainVideoController!.value.isInitialized)
      return;

    final front = _reactionVideoController!;
    final main = _mainVideoController!;

    // Sync main video position
    final diff = (front.value.position - main.value.position).inMilliseconds
        .abs();
    if (diff > 100) {
      await main.seekTo(front.value.position);
    }

    // Update UI
    if (mounted) {
      setState(() {
        _videoPosition = front.value.position;
        _videoDuration = front.value.duration;
        _isPlaying.value = front.value.isPlaying;
      });
    }
  }

  void _syncReactionVideos() async {
    if (_reactionVideoController == null) return;
    if (!_reactionVideoController!.value.isInitialized) return;

    final front = _reactionVideoController!;

    if (mounted) {
      setState(() {
        _videoPosition = front.value.position;

        // 🔥 FIX: Update duration dynamically
        _videoDuration = front.value.duration;

        _isPlaying.value = front.value.isPlaying;
      });
    }
  }

  void _togglePlayPause() async {
    if (_reactionVideoController == null || _mainVideoController == null)
      return;
    final front = _reactionVideoController!;
    final main = _mainVideoController!;

    if (front.value.isPlaying) {
      await front.pause();
      await main.pause();
      _isPlaying.value = false;
    } else {
      await main.seekTo(front.value.position);
      await Future.delayed(const Duration(milliseconds: 60));
      await main.play();
      await front.play();
      _isPlaying.value = true;
    }
  }

  void _togglePlayReactionVideoPause() async {
    if (_reactionVideoController == null) return;
    final front = _reactionVideoController!;

    if (front.value.isPlaying) {
      await front.pause();
      _isPlaying.value = false;
    } else {
      await Future.delayed(const Duration(milliseconds: 60));
      await front.play();
      _isPlaying.value = true;
    }
  }

  PopupMenuButton<dynamic> actionButton() {
    return PopupMenuButton(
      onSelected: (value) async {
        if (value == 0) {
          await sendMessageController.reportStory(widget.postId);
        }
      },
      itemBuilder: (context) => <PopupMenuEntry>[
        PopupMenuItem<int>(
          value: 0,
          height: 25,
          child: Container(
            width: double.infinity,
            height: 25,
            padding: EdgeInsets.only(left: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Report',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xB81B1F26),
                ),
              ),
            ),
          ),
        ),
      ],
      child: SizedBox(
        height: 48,
        width: 48,
        child: Center(
          child: Icon(Icons.report, color: AppColors.primaryColor, size: 28),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
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
                  ? Text(widget.userName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            actionButton(),
          ],
        ),
      ),
      body: _reactionVideoController == null
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RepaintBoundary(
                        key: _repaintKey,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Reaction video
                            if (_reactionVideoController!.value.isInitialized)
                              Positioned.fill(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _reactionVideoController!
                                        .value
                                        .size
                                        .width,
                                    height: _reactionVideoController!
                                        .value
                                        .size
                                        .height,
                                    child: VideoPlayer(
                                      _reactionVideoController!,
                                    ),
                                  ),
                                ),
                              ),

                            // Main video mini preview
                            if (widget.isVideo == true)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    border: Border.all(
                                      color: AppColors.frameColors,
                                      width: 2,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _mainVideoController!
                                          .value
                                          .size
                                          .width,
                                      height: _mainVideoController!
                                          .value
                                          .size
                                          .height,
                                      child: VideoPlayer(_mainVideoController!),
                                    ),
                                  ),
                                ),
                              ),

                            // When main video is an image
                            if (widget.isVideo == false)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    border: Border.all(
                                      color: AppColors.frameColors,
                                      width: 2,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    widget.mainVideo,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Playback controls (excluded from screenshot)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildPlaybackControls(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlaybackControls() {
    final totalMs = _videoDuration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    return ValueListenableBuilder<bool>(
      valueListenable: _isPlaying,
      builder: (_, playing, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.24)),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    _formatDuration(_videoPosition),
                    style: const TextStyle(color: Colors.black),
                  ),
                  Expanded(
                    child: Slider(
                      value: _videoPosition.inMilliseconds
                          .toDouble()
                          .clamp(0, totalMs)
                          .toDouble(),
                      min: 0,
                      max: totalMs.toDouble(),
                      activeColor: AppColors.primaryColor,
                      inactiveColor: Colors.grey,
                      onChanged: (v) async {
                        final pos = Duration(milliseconds: v.toInt());

                        // Seek to the reaction video position
                        await _reactionVideoController?.seekTo(pos);

                        // Only seek the main video if isVideo is true
                        widget.isVideo == true
                            ? await _mainVideoController?.seekTo(pos)
                            : null;

                        setState(() => _videoPosition = pos);
                      },
                    ),
                  ),
                  Text(
                    _formatDuration(_videoDuration),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    child: IconButton(
                      icon: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: widget.isVideo == true
                          ? _togglePlayPause
                          : _togglePlayReactionVideoPause,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              _buildBottomActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() => SafeArea(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        InkWell(
          onTap: () async {
            await _captureAndSaveScreenshot();
            Get.to(
              () => FrameSelectionScreen(
                frontVideoUrl: widget.reactionVideo,
                userProfile: widget.userProfile,
                userName: widget.userName,
                chatId: widget.chatId,
                isInbox: widget.isInbox,
                thumbnail: thumbnail,
              ),
            );
          },
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.grey,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "Select Image",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        Obx(
          () => InkWell(
            onTap: () async {
              await _captureAndSaveScreenshot();
              await sendMessageController.sendMediaToSingleChat(
                chatId: widget.chatId,
                filePath: widget.reactionVideo,
                thumbnail: thumbnail,
                isVideo: true,
                isReaction: true,
              );
            },
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: AppColors.primaryColor,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: sendMessageController.isLoading.value
                      ? SpinKitWave(color: Colors.white, size: 20)
                      : Text(
                          "Send Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
