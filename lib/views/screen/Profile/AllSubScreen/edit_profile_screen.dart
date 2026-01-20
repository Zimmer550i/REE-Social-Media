// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/show_snackbar.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserController userController = Get.put(UserController());
  final nameTextController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  /// Pick image (camera / gallery)
  Future<void> _chooseImageSource() async {
    final XFile? pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Pick from Gallery"),
              onTap: () async {
                Navigator.pop(
                  ctx,
                  await _picker.pickImage(source: ImageSource.gallery),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () async {
                Navigator.pop(
                  ctx,
                  await _picker.pickImage(source: ImageSource.camera),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  /// Save profile
  void _onSave() async {
    if (nameTextController.text.isEmpty) {
      nameTextController.text = userController.userInfo.value!.name!;
    }

    if (userController.isLoading.value) return;

    final result = await userController.updateInfo(
      name: nameTextController.text.trim(),
      image: _profileImage,
    );

    if (result == "success") {
      Get.back(); // go back to profile screen
      showSnackBar("Profile updated successfully", false);
    } else {
      showSnackBar(result, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            /// Top bar
            Row(
              children: [
                SizedBox(width: 20),
                ReBack(onTap: () => Get.back()),
                SizedBox(width: 16),
                SvgPicture.asset("assets/icons/re.svg", height: 35, width: 45),
              ],
            ),

            const SizedBox(height: 45),

            /// Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    /// Profile Image
                    InkWell(
                      onTap: _chooseImageSource,
                      child: Center(
                        child: Container(
                          height: 160,
                          width: 160,

                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 155,
                                width: 155,
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : const AssetImage(
                                                'assets/images/upload.png',
                                              )
                                              as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Positioned(
                              //   child: SvgPicture.asset(
                              //     'assets/icons/upload.svg',
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// Name Field
                    CustomTextField(
                      controller: nameTextController,
                      hintText: 'Enter your name',
                      borderSide: const BorderSide(
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
                            child: SvgPicture.asset(
                              'assets/icons/name_fill.svg',
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),

                    /// Save Button
                    Obx(
                      () => CustomButton(
                        loading: userController.isLoading.value,
                        onTap: _onSave,
                        text: "Save",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
