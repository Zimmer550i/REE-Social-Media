import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/enable_notification_screen.dart';

class InviteFriendScreen extends StatefulWidget {
  const InviteFriendScreen({super.key});

  @override
  State<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends State<InviteFriendScreen> {
  final searchTextController = TextEditingController();
  final ContactController contactController = Get.put(ContactController());
  final UserController userController = Get.put(UserController());
  final RxSet<String> addedFriends = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    contactController.fetchContacts();
    searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    contactController.filterContacts(searchTextController.text);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1 && parts.last.isNotEmpty) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return "";
  }

  Widget _buildContactTile(
    Map<String, dynamic> contact, {
    bool isMatched = true,
  }) {
    final id = contact["_id"]; // may be null for unmatched contacts
    final image = userController.addBaseUrl(contact["image"].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryColor,
            backgroundImage:
                (contact["image"] != null &&
                    contact["image"].toString().isNotEmpty)
                ? NetworkImage(image.toString())
                : null,
            child:
                (contact["image"] == null ||
                    contact["image"].toString().isEmpty)
                ? Text(
                    _getInitials(contact["name"] ?? ""),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Contact info
          Expanded(
            child: Text(
              "${contact["name"] ?? "Unknown"}\n${contact["phone"] ?? ""}",
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF676565),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action Button
          GestureDetector(
            onTap: () {
              // Only mark added if not already
              final key = isMatched ? id : contact["phone"];
              if (!addedFriends.contains(key)) {
                addedFriends.add(key);

                if (isMatched && id != null) {
                  // Only create chat if we have an id
                  contactController.createPrivateChat(id);
                } else if (!isMatched) {
                  // Send invite by phone number
                  contactController.sendInviteSms(
                    context,
                    contact["phone"],
                    contact["name"],
                  );
                }
              }
            },
            child: Container(
              height: 38,
              width: 80,
              decoration: BoxDecoration(
                color: isMatched ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isMatched
                        ? const Color(0xFF002329).withValues(alpha: .07)
                        : Colors.black.withValues(alpha: 0.3),
                    offset: isMatched ? const Offset(0, 2) : const Offset(0, 0),
                    blurRadius: 4,
                  ),
                ],
                border: isMatched
                    ? null
                    : Border.all(
                        color: Colors.grey.withValues(alpha: .5),
                        width: 1,
                      ),
              ),
              child: Center(
                child: Obx(
                  () => Text(
                    addedFriends.contains(isMatched ? id : contact["phone"])
                        ? (isMatched ? "Added" : "Invited")
                        : (isMatched ? "Add" : "Invite"),
                    style: TextStyle(
                      color: isMatched ? Colors.white : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReeLogo(),
                  Text(
                    "2 of 4",
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
            ),

            // Body
            Expanded(
              child: Obx(() {
                final matched = contactController.filteredMatchedContacts;
                final unmatched = contactController.filteredUnmatchedContacts;
                final isLoading = contactController.isLoading.value;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Connect With Friends",
                        style: TextStyle(
                          color: Color(0xFF413E3E),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "To start your first messages on",
                              style: TextStyle(
                                color: Color(0xFF676565),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: " re:",
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: " invite 5 friends",
                              style: TextStyle(
                                color: Color(0xFF676565),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Search bar
                      CustomTextField(
                        controller: searchTextController,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: SvgPicture.asset('assets/icons/search.svg'),
                        ),
                        hintText: 'Search Contacts',
                      ),
                      const SizedBox(height: 24),

                      // Loading
                      if (isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      else ...[
                        // Friends on re:
                        if (matched.isNotEmpty) ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: matched.length,
                            itemBuilder: (context, index) => _buildContactTile(
                              matched[index],
                              isMatched: true,
                            ),
                          ),
                        ],

                        // Invite to join
                        if (unmatched.isNotEmpty) ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: unmatched.length,
                            itemBuilder: (context, index) => _buildContactTile(
                              unmatched[index],
                              isMatched: false,
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 30),
                      Obx(() {
                        final canProceed = addedFriends.length >= 5;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          child: CustomButton(
                            onTap: canProceed
                                ? () => Get.to(
                                    () => const EnableNotificationScreen(),
                                  )
                                : () {
                                    Get.snackbar(
                                      "Invite More Friends",
                                      "Please invite at least 5 friends to continue.",
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.redAccent,
                                      colorText: Colors.white,
                                    );
                                  },
                            text: "Next",
                            color: canProceed
                                ? AppColors.primaryColor
                                : AppColors.greyColor,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
