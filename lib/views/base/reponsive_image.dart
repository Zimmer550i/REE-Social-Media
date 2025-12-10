import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class ResponsiveImage extends StatefulWidget {
  final String url;
  const ResponsiveImage({super.key, required this.url});

  @override
  State<ResponsiveImage> createState() => _ResponsiveImageState();
}

class _ResponsiveImageState extends State<ResponsiveImage> {
  double? imgWidth;
  double? imgHeight;

  @override
  void initState() {
    super.initState();
    _loadImageInfo();
  }

  void _loadImageInfo() {
    NetworkImage(widget.url)
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
    if (imgWidth == null || imgHeight == null) {
      return Center(
        child: SpinKitWave(color: AppColors.primaryColor, size: 30),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;

        // 🔥 Rendered height on screen
        final renderedHeight = constraints.maxWidth * (imgHeight! / imgWidth!);

        // 🔥 If rendered image height > 80% of screen height
        double sHeight = screenHeight * 0.7;
        final bool isVeryTall = renderedHeight > sHeight;
        debugPrint(
          "🔥 renderedHeight: $renderedHeight || screenHeight: ${screenHeight * 0.7} || isVeryTall: $isVeryTall",
        );

        return Image.network(
          widget.url,
          fit: isVeryTall ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        );
      },
    );
  }
}
