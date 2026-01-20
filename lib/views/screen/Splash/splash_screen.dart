import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/auth_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Splash/Onboard/onboard_screen1.dart';
import '../Message/message_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.put(AuthController());
  @override
  void initState() {
    Future.delayed(Duration(seconds: 3), () async {
      final isLoggedIn = await authController.previouslyLoggedIn();
      if (isLoggedIn) {
        Get.offAll(() => MessageScreen());
      } else {
        Get.to(() => OnboardScreen1(), transition: Transition.fadeIn);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: AppColors.backgroundColor,
        child: Center(
          child: Text(
            "re:",
            style: TextStyle(
              fontSize: 126,
              color: AppColors.primaryColor,
              fontFamily: "LibreDisplay"
            ),
          ),
        ),
      ),
    );
  }
}
