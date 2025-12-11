import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/invite_friend_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactAccessScreen extends StatefulWidget {
  const ContactAccessScreen({super.key});

  @override
  State<ContactAccessScreen> createState() => _ContactAccessScreenState();
}

class _ContactAccessScreenState extends State<ContactAccessScreen> with WidgetsBindingObserver {
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.contacts.status;
    setState(() {
      _permissionGranted = status.isGranted;
    });
  }

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
              // Allow Access button
              CustomButton(
                onTap: () async {
                  if (_permissionGranted) {
                    await _saveContactsToLocal();
                    Get.off(() => const InviteFriendScreen());
                  } else {
                    final permission = await FlutterContacts.requestPermission();

                    if (permission) {
                      await _saveContactsToLocal();
                      Get.off(() => const InviteFriendScreen());
                    } else {
                      Get.defaultDialog(
                        title: "Permission Required",
                        backgroundColor: Colors.white,
                        middleText:
                            "Please enable Contacts permission from Settings to continue.",
                        confirm: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            overlayColor: AppColors.primaryColor.withAlpha(50),
                          ),
                          onPressed: () async {
                            await openAppSettings();
                            final status = await Permission.contacts.status;
                            if (status.isGranted) {
                              await _saveContactsToLocal();
                              Get.off(() => const InviteFriendScreen());
                            }
                          },
                          child: const Text(
                            "Open Settings",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        cancel: TextButton(
                          onPressed: () => Get.back(),
                          style: ButtonStyle(
                            overlayColor: WidgetStateProperty.all(
                              AppColors.primaryColor.withAlpha(50),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      );
                    }
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
