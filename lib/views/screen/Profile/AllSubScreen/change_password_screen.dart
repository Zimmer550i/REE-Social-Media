import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';

import '../../../../controllers/auth_controller.dart';
import '../../../../utils/show_snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthController authController = Get.put(AuthController());
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    ReBack(onTap: () => Get.back()),
                    SizedBox(width: 15),
                    Text(
                      "Change Password",
                      style: TextStyle(
                        color: Color(0xFF0D1C12),
                        fontSize: 24,
                        fontFamily: "LibreText",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: currentPasswordController,
                      hintText: 'Enter current Password',
                      isPassword: true,
                      borderSide: BorderSide(
                        color: Color(0xFFC4C3C3),
                        width: 1,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SvgPicture.asset('assets/icons/lock.svg'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: newPasswordController,
                      hintText: 'Enter new password',
                      isPassword: true,
                      borderSide: BorderSide(
                        color: Color(0xFFC4C3C3),
                        width: 1,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SvgPicture.asset('assets/icons/lock.svg'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm  Password',
                      isPassword: true,
                      borderSide: BorderSide(
                        color: Color(0xFFC4C3C3),
                        width: 1,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SvgPicture.asset('assets/icons/lock.svg'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 91),
                    Obx(
                      () => CustomButton(
                        loading: authController.isLoading.value,
                        onTap: () async {
                          if (currentPasswordController.text.isEmpty ||
                              newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            showSnackBar("Please fill all the fields", true);
                          } else {
                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              showSnackBar("Passwords do not match", true);
                            } else {
                              final message = await authController
                                  .changePassword(
                                    currentPasswordController.text,
                                    newPasswordController.text,
                                    confirmPasswordController.text,
                                  );
                              if (message == "success") {
                                Get.back();
                                showSnackBar(
                                  "Password changed successfully",
                                  false,
                                );
                              } else {
                                showSnackBar("Error $message", true);
                              }
                            }
                          }
                        },
                        text: "Save",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
