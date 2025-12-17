import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class DotBarUi extends StatelessWidget {
  const DotBarUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(),
        Container(
          width: 2.5, // thinner line
          height: 60, // longer connector
          color: AppColors.primaryColor.withValues(alpha: .7),
        ),
        _dot(),
      ],
    );
  }

  Widget _dot() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.primaryColor.withValues(alpha: 0.3),
        //     blurRadius: 6,
        //     spreadRadius: 2,
        //   ),
        // ],
      ),
    );
  }
}
