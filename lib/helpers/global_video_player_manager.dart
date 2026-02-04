import 'dart:io';

import 'package:video_player_hdr/video_player_hdr.dart';
import 'package:flutter/foundation.dart';

class GlobalVideoPlayerManager {
  static VideoPlayerHdrController? _controller;

  static VideoPlayerHdrController? get controller => _controller;

  static Future<VideoPlayerHdrController?> initialize(String path) async {
    await dispose();

    try {
      final controller = path.startsWith('http')
          ? VideoPlayerHdrController.networkUrl(Uri.parse(path))
          : VideoPlayerHdrController.file(File(path));
      await controller.initialize();
      _controller = controller;
      debugPrint("🎬 Video player initialized");
      return controller;
    } catch (e) {
      debugPrint("❌ Error initializing video player: $e");
      return null;
    }
  }

  static Future<void> dispose() async {
    try {
      if (_controller != null) {
        await _controller!.pause();
        await _controller!.dispose();
        debugPrint("🧹 Video player disposed successfully");
      }
    } catch (e) {
      debugPrint("⚠️ Video player dispose error: $e");
    } finally {
      _controller = null;
    }
  }

  static bool get isInitialized => _controller?.value.isInitialized ?? false;
}
