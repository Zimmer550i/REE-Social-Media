import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ree_social_media_app/helpers/generate_video_thumbnail.dart';

class VideoUtils {
  static Future<String?> getCachedThumbnail(String videoUrl,context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = videoUrl.hashCode.toString(); // unique cache name
      final thumbPath = "${tempDir.path}/$fileName.jpg";

      final thumbFile = File(thumbPath);

      if (await thumbFile.exists()) {
        // ✅ Return cached thumbnail
        return thumbFile.path;
      }

      // ❌ If not cached → generate and save

      final generatedPath = await generateVideoThumbnail(File(videoUrl),context);
      if (generatedPath != null) {
        debugPrint('Thumbnail saved at: $generatedPath');
      }

      return generatedPath;
    } catch (e) {
      debugPrint("Thumbnail error: $e");
      return null;
    }
  }
}
