import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/profile_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import '../../../base/custom_loading.dart';

class AllDataScreen extends StatefulWidget {
  final String title;
  final String endPoint;
  const AllDataScreen({super.key, required this.title, required this.endPoint});

  @override
  State<AllDataScreen> createState() => _AllDataScreenState();
}

class _AllDataScreenState extends State<AllDataScreen> {
  final ProfileController profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    profileController.getTermsOfService(widget.endPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ReBack(onTap: () => Get.back()),
                  const SizedBox(width: 15),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Color(0xFF0D1C12),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: "LibreText",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Obx(
                () => profileController.isLoading.value
                    ? const Center(child: CustomLoading())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Logo box
                            SvgPicture.asset(
                              "assets/icons/re.svg",
                              height: 35,
                              width: 45,
                            ),
                            const SizedBox(height: 20),

                            /// Terms Content from API (HTML)
                            Html(
                              data:
                                  profileController.termsOfService.value ??
                                  "<p style='color: red; text-align: center;'>${"error_fetching_data".tr}</p>",
                              style: {
                                "p": Style(
                                  fontSize: FontSize(16),
                                  lineHeight: LineHeight(1.5),
                                  color: const Color(0xFF413E3E),
                                ),
                                "strong": Style(
                                  fontWeight: FontWeight.bold,
                                  fontSize: FontSize(16),
                                  color: Colors.black,
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
