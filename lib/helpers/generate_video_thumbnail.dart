import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Generates a video thumbnail (without video_thumbnail or ffmpeg)
/// Must be called from a widget context (not before build)
Future<String?> generateVideoThumbnail(File videoFile, BuildContext context) async {
  try {
    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    await controller.seekTo(const Duration(seconds: 1));
    await controller.pause();

    final key = GlobalKey();

    // Build a temporary hidden widget in the tree
    final completer = Completer<String?>();

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => Center(
        child: Opacity(
          opacity: 0.0,
          child: RepaintBoundary(
            key: key,
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final thumbPath = '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(thumbPath);
      await file.writeAsBytes(pngBytes);

      completer.complete(thumbPath);
    } catch (e) {
      debugPrint('❌ Frame capture failed: $e');
      completer.complete(null);
    } finally {
      entry.remove();
      controller.dispose();
    }

    return completer.future;
  } catch (e) {
    debugPrint('❌ Error generating thumbnail: $e');
    return null;
  }
}
