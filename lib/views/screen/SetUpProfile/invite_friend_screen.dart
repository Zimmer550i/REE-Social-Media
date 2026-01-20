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
  final ContactController contactController = Get.find<ContactController>();
  final UserController userController = Get.find<UserController>();
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
    final id = contact["_id"];
    final imageUrl = contact["image"]?.toString() ?? "";
    final name = contact["name"]?.toString() ?? "Unknown";
    final image = imageUrl.isNotEmpty
        ? userController.addBaseUrl(imageUrl)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryColor,
            backgroundImage: (image != null && image.isNotEmpty)
                ? NetworkImage(image)
                : null,
            child: (image == null || image.isEmpty)
                ? Text(
                    _getInitials(name),
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
              "$name\n${contact["phone"] ?? ""}",
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
          if (isMatched == false) ...[
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
                      offset: isMatched
                          ? const Offset(0, 2)
                          : const Offset(0, 0),
                      blurRadius: 4,
                    ),
                  ],
                  border: isMatched
                      ? null
                      : Border.all(
                          color: AppColors.primaryColor.withValues(alpha: .1),
                          width: 1,
                        ),
                ),
                child: Center(
                  child: Obx(
                    () => Text(
                      addedFriends.contains(isMatched ? id : contact["phone"])
                          ? ("Invited")
                          : ("Invite"),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

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
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                final allMatched = contactController.filteredMatchedContacts;
                final unmatched = <Map<String, dynamic>>[];
                final matched = <Map<String, dynamic>>[];

                for (var c in allMatched) {
                  final name = c["name"]?.toString().trim() ?? "";
                  if (name.isEmpty) {
                    unmatched.add(c);
                  } else {
                    matched.add(c);
                  }
                }

                final allUnmatched =
                    contactController.filteredUnmatchedContacts;
                for (var c in allUnmatched) {
                  if (!matched.contains(c) && !unmatched.contains(c)) {
                    unmatched.add(c);
                  }
                }
                final isLoading = contactController.isLoading.value;
                if (isLoading) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  );
                }

                if (matched.isEmpty && unmatched.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        "No contacts found.\nPlease allow contacts permission.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    Text(
                      "Connect With Friends",
                      style: TextStyle(
                        color: AppColors.primaryColor,
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
                              color: AppColors.primaryColor,
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
                            text: " invite friends",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: searchTextController,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: SvgPicture.asset('assets/icons/search.svg'),
                      ),
                      hintText: 'Search Contacts',
                    ),
                    const SizedBox(height: 24),

                    if (matched.isNotEmpty)
                      ...matched.map(
                        (contact) =>
                            _buildContactTile(contact, isMatched: true),
                      ),
                    if (unmatched.isNotEmpty)
                      ...unmatched.map(
                        (contact) =>
                            _buildContactTile(contact, isMatched: false),
                      ),

                    const SizedBox(height: 30),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: CustomButton(
              onTap: () => Get.to(() => const EnableNotificationScreen()),
              text: "Next",
            ),
          ),
        ),
      ),
    );
  }
}
