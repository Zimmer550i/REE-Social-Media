// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/utils/show_snackbar.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/base/date_of_birth_picker.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/get_start_screen.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final UserController userController = Get.put(UserController());
  final nameTextController = TextEditingController();
  final dobTextController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  /// Open bottom sheet to select Camera or Gallery
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

  /// Handle Save button
  void _onSave() async {
    if (nameTextController.text.isEmpty || dobTextController.text.isEmpty) {
      showSnackBar("Please fill all field", true);
      return;
    }

    if (userController.isLoading.value) return;

    final dobText = dobTextController.text.trim();
    debugPrint("DOB Text: $dobText");

    DateTime? dob;
    try {
      dob = DateFormat('MM/dd/yyyy').parseStrict(dobText);
    } catch (e) {
      showSnackBar("Invalid date format. Please select a valid date.", true);
      return;
    }

    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    if (age < 18) {
      showSnackBar("You must be at least 18+ years old to use this app.", true);
      return;
    }

    final result = await userController.updateInfo(
      name: nameTextController.text.trim(),
      image: _profileImage,
      dob: dob,
    );

    if (result == "success") {
      Get.to(() => const GetStartScreen());
    } else {
      showSnackBar(result, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReeLogo(),
                  Text(
                    "4 of 4",
                    style: TextStyle(
                      color: const Color(0xFF413E3E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 45),

              /// Title
              const Text(
                "Set Up Your \nProfile",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Add your details so friends can recognize you",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),

              /// Profile Image Picker
              InkWell(
                onTap: _chooseImageSource,
                child: Center(
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/images/demo1.png')
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              /// Name Input
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
                      child: SvgPicture.asset('assets/icons/name_fill.svg'),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              /// Date of Birth Input
              DateOfBirthField(controller: dobTextController),

              const SizedBox(height: 40),

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
    );
  }
}
