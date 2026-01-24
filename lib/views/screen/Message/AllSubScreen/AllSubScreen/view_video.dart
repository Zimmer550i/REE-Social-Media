// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import 'package:ree_social_media_app/views/base/reponsive_image.dart';
import 'package:video_player/video_player.dart';

class ViewMedia extends StatefulWidget {
  const ViewMedia({super.key, required this.mediaUrl});

  final String mediaUrl; // can be video or image

  @override
  State<ViewMedia> createState() => _ViewMediaState();
}

class _ViewMediaState extends State<ViewMedia> {
  VideoPlayerController? _video;
  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;
  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  late final VoidCallback _videoListener;

  bool get isVideo {
    final ext = widget.mediaUrl.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.contains('video');
  }

  bool get isImage {
    final ext = widget.mediaUrl.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp') ||
        ext.contains('image');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFlow());
  }

  Future<void> _initFlow() async {
    await _requestPermissions();
    if (isVideo) await _initVideo();
    if (mounted && isVideo) _startPlayback();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  Future<void> _initVideo() async {
    _video = widget.mediaUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
        : VideoPlayerController.file(File(widget.mediaUrl));

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

  Future<void> _startPlayback() async {
    await _video!.play();
  }

  @override
  void dispose() {
    _video?.removeListener(_videoListener);
    _video?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final videoReady = isVideo ? _video?.value.isInitialized == true : true;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [ReBack(onTap: () => Get.back())]),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 26),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: videoReady
          ? Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: _buildMediaView()),
                if (isVideo) _buildBottomControls(),
              ],
            )
          : Center(
              child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
            ),
    );
  }

  Widget _buildMediaView() {
    if (isVideo && _video != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _video!.value.size.width,
          height: _video!.value.size.height,
          child: VideoPlayer(_video!),
        ),
      );
    }

    //Image view (supports both local and network images)
    if (widget.mediaUrl.startsWith('http')) {
      return ResponsiveImage(url: widget.mediaUrl);
    } else {
      final file = File(widget.mediaUrl);
      if (!file.existsSync()) {
        return const Center(child: Icon(Icons.broken_image, size: 60));
      }
      return Image.file(file, fit: BoxFit.contain);
    }
  }

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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        color: Colors.black.withValues(alpha: .3),
        child: SafeArea(
          child: Row(
            children: [
              Text(
                _fmt(_position),
                style: const TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: total.toDouble(),
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
            ],
          ),
        ),
      ),
    );
  }
}
