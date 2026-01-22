import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Auth/login_screen.dart';
import 'dart:io';

class OnboardScreen2 extends StatelessWidget {
  const OnboardScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReeLogo(),
                  Text(
                    "2 of 2",
                    style: TextStyle(
                      color: Color(0xFF413E3E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/splash2.svg',
                    height: 120,
                    width: 120,
                  ),

                  SizedBox(height: 20),
                  Text(
                    "See Real Reactions \nin Real Time",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 28,
                      fontFamily: "LibreText",
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "When your media is revealed",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: " re:",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: " captures genuine reactions instantly",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,

                    child: CustomButton(
                      onTap: () async {
                        // 🎯 Request Camera Permission
                        final cameraStatus = await Permission.camera.request();
                        debugPrint('Camera permission status: $cameraStatus');

                        // 🎯 Request Microphone Permission
                        final micStatus = await Permission.microphone.request();
                        debugPrint('Microphone permission status: $micStatus');

                        // 🎯 Request Photo Library Permission (full access)
                        PermissionStatus photoStatus;
                        if (Platform.isIOS) {
                          photoStatus = await Permission.photos.request();
                          debugPrint(
                            'iOS Photo Library permission status: $photoStatus',
                          );
                          if (photoStatus == PermissionStatus.limited) {
                            // Request full photo library access if limited
                            photoStatus = await Permission.photos.request();
                            debugPrint(
                              'iOS Photo Library full access request status: $photoStatus',
                            );
                          }
                        } else if (Platform.isAndroid) {
                          final androidInfo =
                              await DeviceInfoPlugin().androidInfo;
                          final sdkInt = androidInfo.version.sdkInt;
                          if (sdkInt >= 33) {
                            photoStatus = await Permission.photos.request();
                            debugPrint(
                              'Android 13+ Photo permission status: $photoStatus',
                            );
                          } else {
                            photoStatus = await Permission.storage.request();
                            debugPrint(
                              'Android <=12 Storage permission status: $photoStatus',
                            );
                          }
                        } else {
                          photoStatus = PermissionStatus.denied;
                          debugPrint(
                            'Unsupported platform for photo permission',
                          );
                        }

                        // 🎯 Request Contacts Permission
                        PermissionStatus contactStatus;
                        if (Platform.isIOS || Platform.isAndroid) {
                          contactStatus = await Permission.contacts.request();
                          debugPrint(
                            'Contacts permission status: $contactStatus',
                          );
                        } else {
                          contactStatus = PermissionStatus.denied;
                          debugPrint(
                            'Unsupported platform for contacts permission',
                          );
                        }

                        // 🎯 Check if all permissions granted
                        final allGranted =
                            cameraStatus.isGranted &&
                            micStatus.isGranted &&
                            photoStatus.isGranted &&
                            contactStatus.isGranted;

                        if (allGranted && Platform.isAndroid) {
                          Get.offAll(
                            () => LoginScreen(),
                            transition: Transition.rightToLeft,
                          );
                        } else if (Platform.isIOS) {
                          Get.offAll(
                            () => LoginScreen(),
                            transition: Transition.rightToLeft,
                          );
                        } else {
                          Get.snackbar(
                            "Permission Required",
                            "Camera, Microphone, Photo Library, and Contacts access are needed to continue.",
                            snackPosition: SnackPosition.BOTTOM,
                            colorText: Colors.white,
                            backgroundColor: AppColors.primaryColor,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 10,
                            duration: const Duration(seconds: 3),
                          );

                          // ⚙️ Open settings if permanently denied
                          if (cameraStatus.isPermanentlyDenied ||
                              micStatus.isPermanentlyDenied ||
                              photoStatus.isPermanentlyDenied ||
                              contactStatus.isPermanentlyDenied) {
                            debugPrint(
                              'One or more permissions permanently denied, opening app settings.',
                            );
                            await openAppSettings();
                          }
                        }
                      },
                      text: "Get Started",
                    ),
                  ),
                ],
              ),
              SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
