// ignore_for_file: use_build_context_synchronously, unnecessary_underscores, unnecessary_null_comparison
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/send_or_trim_video_screen.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    this.countdownSeconds = 3,
    required this.userProfile,
    required this.userName,
    this.chatId,
    this.caption,
    required this.postId,
    this.isInbox = false,
  });

  final String videoUrl;
  final String userProfile;
  final String userName;
  final String? chatId;
  final String? caption;
  final String postId;
  final bool? isInbox;
  final int countdownSeconds;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  final MessageController messageController = Get.find<MessageController>();
  CameraController? _frontCam;
  VideoPlayerHdrController? _video;
  Timer? _countdownTimer;

  int _secondsRemaining = 3;
  bool isRecording = false;
  XFile? recordedFile;
  String? storyChatId;
  double imgWidth = 0;
  double imgHeight = 0;

  // Tall image prediction flag
  bool _isTallImage = false;

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
        ? VideoPlayerHdrController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerHdrController.file(File(widget.videoUrl));

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

  Future<void> _onNextPressed(bool isVideo) async {
    await _stopRecordingIfNeeded();

    debugPrint("ChatId: $storyChatId");

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
            final screenHeight = MediaQuery.of(context).size.height;
            final aspectRatio = info.image.height / info.image.width;

            // Predict rendered height using full width
            final renderedHeight =
                MediaQuery.of(context).size.width * aspectRatio;

            final bool isVeryTall = renderedHeight > screenHeight * 0.7;

            setState(() {
              imgWidth = info.image.width.toDouble();
              imgHeight = info.image.height.toDouble();
              _isTallImage = isVeryTall;
            });
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final videoReady = isVideo ? _video?.value.isInitialized == true : true;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
              backgroundImage: widget.userProfile.isNotEmpty
                  ? NetworkImage(widget.userProfile)
                  : null,
              child: (widget.userProfile.isEmpty || widget.userProfile == "")
                  ? Text(
                      getInitials(widget.userName),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,

                        fontFamily: "LibreText",
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: "LibreText",
              ),
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
                            child: VideoPlayerHdr(_video!),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Image.network(
                            widget.videoUrl,
                            key: ValueKey(_isTallImage),
                            fit: _isTallImage ? BoxFit.cover : BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
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
                if (!isVideo && widget.caption!.isNotEmpty) ...[
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 100,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: widget.userProfile.isEmpty
                              ? AppColors.primaryColor
                              : Colors.transparent,
                          backgroundImage: widget.userProfile.isEmpty
                              ? null
                              : NetworkImage(widget.userProfile),
                          child: widget.userProfile.isEmpty
                              ? Text(
                                  getInitials(widget.userName),
                                  style: TextStyle(
                                    color: AppColors.backgroundColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 12),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              color: AppColors.backgroundColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                widget.caption!,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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

  String getInitials(String name) {
    if (name.trim().isEmpty) return "";

    List<String> parts = name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildCountdownOverlay() => Positioned.fill(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(),
            ),
          ),
        ),

        // Foreground content
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Get ready to re:',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF383838),
                  fontWeight: FontWeight.w600,
                ),
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
        color: Colors.black.withValues(alpha: 0.2),
        child: Row(
          children: [
            Text(_fmt(_position), style: const TextStyle(color: Colors.black)),
            Expanded(
              child: Slider(
                value: double.parse(value.toStringAsFixed(0)),
                min: 0,
                max: double.parse(total.toStringAsFixed(0)),
                activeColor: Colors.black,
                onChanged: (v) =>
                    _video?.seekTo(Duration(milliseconds: v.toInt())),
              ),
            ),
            Text(
              _fmt(_videoDuration),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<bool>(
              valueListenable: _isPlaying,
              builder: (_, playing, _) => IconButton(
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
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
