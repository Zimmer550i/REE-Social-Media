import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/invite_friend_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enable_notification_screen.dart';

class ContactAccessScreen extends StatefulWidget {
  const ContactAccessScreen({super.key});

  @override
  State<ContactAccessScreen> createState() => _ContactAccessScreenState();
}

class _ContactAccessScreenState extends State<ContactAccessScreen> {
  /// Fetch contacts and save them locally
  Future<void> _saveContactsToLocal() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    List<Map<String, dynamic>> contactList = [];

    for (var c in contacts) {
      if (c.phones.isNotEmpty) {
        for (var phone in c.phones) {
          contactList.add({
            "name": c.displayName,
            "number": _normalizePhoneNumber(phone.number),
          });
        }
      }
    }

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_contacts", jsonEncode(contactList));

    debugPrint("✅ Contacts saved locally: ${contactList.length}");
  }

  /// Normalize phone numbers to always include country code
  String _normalizePhoneNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');

    // Example default: Bangladesh (+88). Change as needed.
    if (!cleaned.startsWith("+")) {
      cleaned = "+1$cleaned";
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReeLogo(),
                  Text(
                    "1 of 4",
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

              const SizedBox(height: 110),
              const Text(
                "Access Your \nContacts",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "We'll use your contacts to invite friends to",
                      style: TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: " re:",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text:
                          " and show you who is already on the app. Your info stays private",
                      style: TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // // Not Now button
              // InkWell(
              //   onTap: () {
              //     Get.to(() => const EnableNotificationScreen());
              //   },
              //   child: Container(
              //     height: 48,
              //     width: double.infinity,
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(
              //         color: const Color(0xFFC4C3C3),
              //         width: 0.5,
              //       ),
              //     ),
              //     child: const Center(
              //       child: Text(
              //         "Not Now",
              //         style: TextStyle(
              //           color: Color(0xFF676565),
              //           fontSize: 18,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 20),

              // Allow Access button
              CustomButton(
                onTap: () async {
                  if (await FlutterContacts.requestPermission()) {
                    await _saveContactsToLocal();
                    Get.to(() => const InviteFriendScreen());
                  } else {
                    Get.snackbar(
                      "Permission Denied",
                      "You need to allow access to continue",
                    );
                  }
                },
                text: "Allow Access",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
