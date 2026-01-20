import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/auth_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import '../../../../utils/show_snackbar.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final UserController userController = Get.put(UserController());
  final passwordTextController = TextEditingController();
  final reportController = TextEditingController();

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
                      "Report a Problem",
                      style: TextStyle(
                        color: Color(0xFF0D1C12),
                        fontSize: 24,
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
                    Obx(
                      () => CustomTextField(
                        controller: passwordTextController,
                        isRealOnly: true,
                        hintText: userController.userInfo.value!.name
                            .toString(),
                        borderSide: BorderSide(
                          color: Color(0xFFC4C3C3),
                          width: 1,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SvgPicture.asset(
                              'assets/icons/change_password.svg',
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: 16),
                    // CustomTextField(
                    //   controller: passwordTextController,
                    //   hintText: userController.userInfo.value!.phone.toString(),
                    //   isRealOnly: true,
                    //   borderSide: BorderSide(color: Color(0xFFC4C3C3), width: 1),
                    //   prefixIcon: Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(4.0),
                    //       child: SvgPicture.asset(
                    //         'assets/icons/change_password.svg',
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    SizedBox(height: 16),
                    Obx(
                      () => CustomTextField(
                        controller: passwordTextController,
                        hintText: userController.userInfo.value!.phone
                            .toString(),
                        isRealOnly: true,
                        borderSide: BorderSide(
                          color: Color(0xFFC4C3C3),
                          width: 1,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SvgPicture.asset(
                              'assets/icons/change_password.svg',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xFFC4C3C3),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Comment",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF676565),
                            ),
                          ),
                          SizedBox(height: 8),
                          CustomTextField(
                            controller: reportController,
                            filColor: AppColors.backgroundColor,
                            maxLines: 3,
                            hintText: 'Write your comment ',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 91),
                    Obx(() {
                      final authController = Get.find<AuthController>();
                      final user = userController.userInfo.value;

                      return CustomButton(
                        loading: authController.isLoading.value,
                        onTap: () async {
                          if (reportController.text.trim().isEmpty) {
                            showSnackBar("Please enter a report", true);
                            return;
                          }

                          final name = user?.name ?? "";
                          final phone = user?.phone ?? "";

                          final message = await authController.reportSubmit(
                            name,
                            phone,
                            reportController.text.trim(),
                          );

                          if (message == "success") {
                            showSnackBar(
                              "Report submitted successfully",
                              false,
                            );
                            reportController.clear();
                          } else {
                            showSnackBar(message, true);
                          }
                        },
                        text: "Submit Now",
                      );
                    }),
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
