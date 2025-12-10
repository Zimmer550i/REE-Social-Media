// ignore_for_file: use_build_context_synchronously, unnecessary_underscores

import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/send_or_trim_video_screen.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    this.countdownSeconds = 3,
    required this.userProfile,
    required this.userName,
    this.chatId,
    required this.postId,
    this.isInbox = false,
  });

  final String videoUrl;
  final String userProfile;
  final String userName;
  final String? chatId;
  final String postId;
  final bool? isInbox;
  final int countdownSeconds;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  final MessageController messageController = Get.find<MessageController>();
  CameraController? _frontCam;
  VideoPlayerController? _video;
  Timer? _countdownTimer;

  int _secondsRemaining = 3;
  bool isRecording = false;
  XFile? recordedFile;
  String? storyChatId;
  double imgWidth = 0;
  double imgHeight = 0;

  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;
  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  late final VoidCallback _videoListener;

  bool get isVideo {
    final ext = widget.videoUrl.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.contains('video');
  }

  @override
  void initState() {
    super.initState();
    if (widget.isInbox == false) getStoryId();
    _secondsRemaining = widget.countdownSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFlow());
  }

  void getStoryId() async {
    storyChatId = await messageController.getOrCreatePrivateChat(
      widget.chatId!,
      widget.userName,
      widget.userProfile,
    );
    debugPrint("Chat ID: $storyChatId");
  }

  Future<void> _initFlow() async {
    if (Platform.isAndroid) {
      await _requestPermissions();
    }
    await _initFrontCamera();

    if (isVideo) {
      await _initVideo();
    }

    if (!isVideo) {
      _loadImageInfo();
    }

    if (mounted) {
      _startCountdown();
    }
  }

  Future<void> _onCountdownComplete() async {
    setState(() => _secondsRemaining = 0);

    try {
      // Play video if available
      if (isVideo && _video != null && _video!.value.isInitialized) {
        await _video!.play();
        debugPrint("🎬 Main video playing...");
      }
      // Start recording reaction
      await _startFrontRecording();
    } catch (e) {
      debugPrint("⚠️ Countdown complete but start failed: $e");
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera & Microphone permission required'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initFrontCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _frontCam = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _frontCam!.initialize();

    // Flip preview horizontally (to look natural)
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initVideo() async {
    _video = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    await _video!.initialize();
    _videoDuration = _video!.value.duration;
    _video!.setLooping(false);

    _videoListener = () {
      if (!mounted) return;
      setState(() {
        _position = _video!.value.position;
        _isPlaying.value = _video!.value.isPlaying;
      });
    };

    _video!.addListener(_videoListener);
    if (mounted) setState(() {});
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        _onCountdownComplete();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  /// Stop and navigate when user presses “Next”
  Future<void> _onNextPressed(bool isVideo) async {
    await _stopRecordingIfNeeded();

    if (recordedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reaction recorded. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    isVideo
        ? Get.to(
            () => SendOrTrimVideoScreen(
              mainVideo: widget.videoUrl,
              reactionVideo: recordedFile!.path,
              userProfile: widget.userProfile,
              userName: widget.userName,
              postId: widget.postId,
              chatId: widget.isInbox == true
                  ? widget.chatId.toString()
                  : storyChatId.toString(),
              isInbox: widget.isInbox ?? false,
              isVideo: true,
            ),
          )
        : Get.to(
            () => SendOrTrimVideoScreen(
              mainVideo: widget.videoUrl,
              reactionVideo: recordedFile!.path,
              userProfile: widget.userProfile,
              userName: widget.userName,
              postId: widget.postId,
              chatId: widget.isInbox == true
                  ? widget.chatId.toString()
                  : storyChatId.toString(),
              isInbox: widget.isInbox ?? false,
              isVideo: false,
            ),
          );
  }

  Future<void> _startFrontRecording() async {
    if (_frontCam == null || !_frontCam!.value.isInitialized) return;
    if (_frontCam!.value.isRecordingVideo) return;

    try {
      setState(() => isRecording = true);
      await _frontCam!.startVideoRecording();
      debugPrint("🎬 Front camera recording started");
    } catch (e) {
      debugPrint("⚠️ Failed to start recording: $e");
      setState(() => isRecording = false);
    }
  }

  Future<void> _stopRecordingIfNeeded() async {
    if (_frontCam?.value.isRecordingVideo == true) {
      try {
        final file = await _frontCam?.stopVideoRecording();
        recordedFile = file;
        debugPrint("🎥 Recording saved at: ${file?.path}");
      } catch (e) {
        debugPrint("⚠️ Stop recording failed: $e");
      } finally {
        setState(() => isRecording = false);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _video?.removeListener(_videoListener);
    _video?.dispose();
    _stopRecordingIfNeeded();
    _frontCam?.dispose();
    _disposeControllers();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _disposeControllers() {
    try {
      _countdownTimer?.cancel();
      _video?.removeListener(_videoListener);
      _video?.dispose();
      _video = null;

      _frontCam?.dispose();
      _frontCam = null;

      recordedFile = null;
      isRecording = false;
      _secondsRemaining = widget.countdownSeconds;
    } catch (e) {
      debugPrint("⚠️ Dispose error: $e");
    }
  }

  void _loadImageInfo() {
    NetworkImage(widget.videoUrl)
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, _) {
            setState(() {
              imgWidth = info.image.width.toDouble();
              imgHeight = info.image.height.toDouble();
            });
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final videoReady = isVideo ? _video?.value.isInitialized == true : true;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // ← Back Arrow
            ReBack(
              onTap: () async {
                await _stopRecordingIfNeeded();
                _disposeControllers();
                Get.back();
              },
            ),
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          // ✖️ X Button (Exit)
          IconButton(
            icon: const Icon(Icons.close, size: 26),
            onPressed: () async {
              await _stopRecordingIfNeeded();
              _disposeControllers();
              Get.back();
            },
          ),
        ],
      ),
      body: videoReady
          ? Stack(
              alignment: Alignment.center,
              children: [
                // 🎬 Background (video or image)
                Positioned.fill(
                  child: isVideo
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _video!.value.size.width,
                            height: _video!.value.size.height,
                            child: VideoPlayer(_video!),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final screenHeight = MediaQuery.of(
                              context,
                            ).size.height;

                            // 🔥 Rendered height on screen
                            final renderedHeight =
                                constraints.maxWidth * (imgHeight / imgWidth);

                            // 🔥 If rendered image height > 80% of screen height
                            double sHeight = screenHeight * 0.7;
                            final bool isVeryTall = renderedHeight > sHeight;
                            debugPrint(
                              "🔥 renderedHeight: $renderedHeight || screenHeight: ${screenHeight * 0.7} || isVeryTall: $isVeryTall",
                            );

                            return Image.network(
                              widget.videoUrl,
                              fit: isVeryTall ? BoxFit.cover : BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            );
                          },
                        ),
                ),

                if (_secondsRemaining > 0) _buildCountdownOverlay(),

                // 📸 Front camera PiP
                if (_frontCam?.value.isInitialized == true)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SizedBox(
                      width: 110,
                      // height: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .25),
                          border: Border.all(
                            color: AppColors.frameColors,
                            width: 2,
                          ),
                        ),
                        // clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: CameraPreview(_frontCam!),
                      ),
                    ),
                  ),
                isVideo
                    ? _buildBottomControls()
                    : Positioned(
                        bottom: 40,
                        left: 0,
                        right: 20,
                        child: Row(
                          children: [
                            Spacer(),
                            InkWell(
                              onTap: () {
                                _onNextPressed(false);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  color: AppColors.primaryColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 8,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Next",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Icon(
                                        Icons.navigate_next,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            )
          : Center(
              child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
            ),
    );
  }

  Widget _buildCountdownOverlay() => Positioned.fill(
    child: Stack(
      alignment: Alignment.center,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.white.withValues(alpha: 0.5)),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                '$_secondsRemaining',
                style: const TextStyle(
                  fontSize: 64,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get ready to re:',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF383838),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildBottomControls() {
    final total = _videoDuration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    final value = _position.inMilliseconds.toDouble().clamp(0, total);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black.withValues(alpha: 0.3),
        child: Row(
          children: [
            Text(_fmt(_position), style: const TextStyle(color: Colors.white)),
            Expanded(
              child: Slider(
                value: double.parse(value.toStringAsFixed(0)),
                min: 0,
                max: double.parse(total.toStringAsFixed(0)),
                activeColor: Colors.white,
                onChanged: (v) =>
                    _video?.seekTo(Duration(milliseconds: v.toInt())),
              ),
            ),
            Text(
              _fmt(_videoDuration),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<bool>(
              valueListenable: _isPlaying,
              builder: (_, playing, _) => IconButton(
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
            ),
            const SizedBox(width: 18),
            InkWell(
              onTap: () {
                _onNextPressed(true);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: AppColors.primaryColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 8,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.navigate_next, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
