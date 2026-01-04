import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_checkbox_screen.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';
import '../../../controllers/chat_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<Map<String, dynamic>> matchedContacts;

  const CreateGroupScreen({super.key, required this.matchedContacts});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final chatController = Get.put(ChatController());
  final userController = Get.put(UserController());
  final searchTextController = TextEditingController();

  late List<Map<String, dynamic>> allFriends;
  late List<Map<String, dynamic>> filteredFriends;

  @override
  void initState() {
    super.initState();
    allFriends = widget.matchedContacts.map((c) {
      return {
        "_id": c["_id"],
        "name": c["name"] ?? "Unknown",
        "image": c["image"] ?? "",
        "isInvite": false,
      };
    }).toList();
    allFriends.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    filteredFriends = List.from(allFriends);
    searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchTextController.removeListener(_onSearchChanged);
    searchTextController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchTextController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredFriends = List.from(allFriends);
      } else {
        filteredFriends = allFriends.where((friend) {
          final name = (friend['name'] ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
        filteredFriends.sort((a, b) {
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(children: [ReBack(onTap: () => Get.back())]),
            const SizedBox(height: 24),

            // 🔍 Search box
            CustomTextField(
              controller: searchTextController,
              borderColor: Colors.transparent,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SvgPicture.asset('assets/icons/search.svg'),
              ),
              hintText: 'Search here',
            ),

            const SizedBox(height: 24),

            // 👥 Filtered friend list
            Expanded(
              child: filteredFriends.isEmpty
                  ? const Center(child: Text("No friends found"))
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final item = filteredFriends[index];
                        final imageUrl = userController.addBaseUrl(
                          item['image'],
                        );
                        final hasImage =
                            imageUrl != null &&
                            imageUrl.isNotEmpty &&
                            imageUrl != "";

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primaryColor,
                              backgroundImage: hasImage
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: !hasImage
                                  ? Text(
                                      _getInitials(item['name']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            CustomCheckboxScreen(
                              value: item['isInvite'],
                              onChanged: (val) {
                                setState(() {
                                  item['isInvite'] = val!;
                                });
                              },
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemCount: filteredFriends.length,
                    ),
            ),

            Obx(
              () => CustomButton(
                loading: chatController.isLoading.value,
                onTap: () {
                  final selected = filteredFriends
                      .where((c) => c['isInvite'] == true)
                      .map((c) => c["_id"].toString())
                      .toList();

                  if (selected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select at least one member"),
                      ),
                    );
                    return;
                  }

                  chatController.createGroupChat(selected);
                },
                text: "Create Now",
              ),
            ),
          ],
        ),
      ),
    );
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
}
