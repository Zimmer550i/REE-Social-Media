// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Contact/create_group_screen.dart';
import '../../base/bottom_menu.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final searchTextController = TextEditingController();

  final ContactController contactController = Get.put(ContactController());
  final ChatController chatController = Get.put(ChatController());
  final UserController userController = Get.put(UserController());

  final RxString _loadingContactId = ''.obs;

  @override
  void initState() {
    super.initState();
    contactController.fetchContacts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Contacts",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildContactList()),
              const SizedBox(height: 12),
              _buildCreateGroupButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomMenu(2),
    );
  }

  // 🔍 Search Bar
  Widget _buildSearchBar() {
    return CustomTextField(
      controller: searchTextController,
      onChanged: contactController.filterContacts,
      borderColor: Colors.transparent,
      suffixIcon: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SvgPicture.asset('assets/icons/search.svg'),
      ),
      hintText: 'Search here',
    );
  }

  Widget _buildContactList() {
    return Obx(() {
      if (contactController.isLoading.value) {
        return Center(
          child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
        );
      }
      final currenUserNumber = Get.find<UserController>().userInfo.value!.phone;
      final myNumber = currenUserNumber?.trim();
      final allMatched = contactController.filteredMatchedContacts;
      final allUnmatched = contactController.filteredUnmatchedContacts;
      final matched = <Map<String, dynamic>>[];
      final unmatched = <Map<String, dynamic>>[];

      for (var c in allMatched) {
        final phone = c['phone']?.toString().trim();
        if (phone != null && phone == myNumber) continue;

        final name = c['name'] ?? '';
        if (name.trim().isEmpty) {
          unmatched.add(c);
        } else {
          matched.add(c);
        }
      }

      for (var c in allUnmatched) {
        final phone = c['phone']?.toString().trim();
        if (phone != null && phone == myNumber) continue;

        if (!matched.contains(c) && !unmatched.contains(c)) {
          unmatched.add(c);
        }
      }

      // Sort matched contacts alphabetically by name (case-insensitive)
      matched.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      final apiUsers = userController.allUsers;

      if (matched.isEmpty && unmatched.isEmpty) {
        return const Center(
          child: Text(
            "No contacts found.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }

      return ListView(
        children: [
          if (matched.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Friends on re:",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ...matched.map((c) => _buildMatchedContactTile(c, apiUsers)),
          ],
          if (unmatched.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Invite Friends",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ...unmatched.map((c) => _buildUnmatchedContactTile(c)),
          ],
        ],
      );
    });
  }

  Widget _buildMatchedContactTile(
    Map<String, dynamic> c,
    List<dynamic> apiUsers,
  ) {
    String? imageUrl;
    if (c["image"] == null) {
      imageUrl = "";
    } else {
      imageUrl = userController.addBaseUrl(c['image']);
    }

    final name = c["name"] ?? "";
    final phone = c["phone"] ?? "";

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryColor,
        backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
        child: !hasImage
            ? Text(
                _getInitials(name),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
      title: Text(name),
      subtitle: Text(phone),
      trailing: Obx(() {
        final isThisTileLoading = _loadingContactId.value == c["_id"];
        return GestureDetector(
          onTap: isThisTileLoading
              ? null
              : () async {
                  _loadingContactId.value = c["_id"];

                  try {
                    await chatController.createPrivateChat(
                      name,
                      c['image'],
                      c["_id"],
                    );
                  } finally {
                    _loadingContactId.value = '';
                  }
                },
          child: isThisTileLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                )
              : SvgPicture.asset(
                  "assets/icons/message.svg",
                  color: AppColors.primaryColor,
                  height: 22,
                ),
        );
      }),
    );
  }

  // 📨 Friend not on app
  Widget _buildUnmatchedContactTile(Map<String, dynamic> c) {
    final name = c["name"] ?? "Unknown";
    final phone = c["phone"] ?? "";

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryColor,
        child: Text(
          _getInitials(name),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: Text(phone),
      trailing: InkWell(
        onTap: () => contactController.sendInviteSms(context, phone, name),
        child: Container(
          height: 38,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 0),
                blurRadius: 4,
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
          ),
          child: Center(
            child: const Text(
              "Invite",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ➕ Create Group Button
  Widget _buildCreateGroupButton() {
    return CustomButton(
      onTap: () {
        final matched = contactController.matchedContacts;
        if (matched.isEmpty) {
          Get.snackbar(
            "No Friends",
            "You don’t have any friends to create a groupChat with.",
          );
          return;
        }
        Get.to(() => CreateGroupScreen(matchedContacts: matched));
      },
      text: "Create Group",
    );
  }
}
