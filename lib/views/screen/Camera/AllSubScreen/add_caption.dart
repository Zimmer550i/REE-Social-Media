// ignore_for_file: deprecated_member_use, unnecessary_null_comparison
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class AddCaptionScreen extends StatefulWidget {
  final String filePath;
  const AddCaptionScreen({super.key, required this.filePath});

  @override
  State<AddCaptionScreen> createState() => _AddCaptionScreenState();
}

class _AddCaptionScreenState extends State<AddCaptionScreen> {
  final UserController _userController = Get.find<UserController>();
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController caption = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String? image = _userController.userInfo.value!.image;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.file(File(widget.filePath), fit: BoxFit.contain),
            ),

            /// Close button
            Positioned(
              top: 70,
              right: 20,
              child: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.close, color: Color(0xFF676565)),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 100,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: image == null
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    backgroundImage: image == null
                        ? null
                        : NetworkImage(_userController.userInfo.value!.image!),
                    child: image == null
                        ? Text(
                            getInitials(_userController.userInfo.value!.name!),
                            style: TextStyle(
                              color: AppColors.backgroundColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  /// Caption Input
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 0.8,
                        ),
                      ),
                      child: TextField(
                        controller: caption,
                        maxLines: 1,
                        minLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Write a caption...",
                          hintStyle: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: Obx(
                            () => GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _chatController.sendPickedImage(
                                  widget.filePath,
                                  caption.text,
                                );
                              },
                              child: _chatController.isLoading.value
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    )
                                  : Icon(Icons.arrow_upward, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getInitials(String name) {
    if (name.trim().isEmpty) return "";

    List<String> parts = name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
