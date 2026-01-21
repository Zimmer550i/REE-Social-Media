// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Message/message_screen.dart';

class GetStartScreen extends StatefulWidget {
  const GetStartScreen({super.key});

  @override
  State<GetStartScreen> createState() => _GetStartScreenState();
}

class _GetStartScreenState extends State<GetStartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReeLogo(),
              SizedBox(height: 45),
              Text(
                "You’re All Set!",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 28,
                  fontFamily: "LibreText",
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Start sharing moments and see real reactions",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 42),
              Center(
                child: SvgPicture.asset(
                  'assets/icons/smail.svg',
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 80),
              CustomButton(
                onTap: () {
                  Get.offAll(() => MessageScreen());
                },
                text: "Get Started",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
