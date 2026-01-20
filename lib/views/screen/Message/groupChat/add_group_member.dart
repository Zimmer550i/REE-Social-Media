// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/group_chat_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_checkbox_screen.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/base/re_back.dart';

class AddGroupMemberScreen extends StatefulWidget {
  final String chatId;
  final List<Map<String, dynamic>> existMembers;

  const AddGroupMemberScreen({
    super.key,
    required this.chatId,
    required this.existMembers,
  });

  @override
  State<AddGroupMemberScreen> createState() => _AddGroupMemberScreenState();
}

class _AddGroupMemberScreenState extends State<AddGroupMemberScreen> {
  final GroupChatController _groupChatController = Get.put(
    GroupChatController(),
  );
  final ContactController _contactController = Get.put(ContactController());
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _initializeContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeContacts() async {
    await _contactController.fetchContacts();
    final allContacts = _contactController.matchedContacts;
    final existingIds = widget.existMembers.map((m) => m["_id"]).toSet();
    final availableContacts = allContacts
        .where((contact) => !existingIds.contains(contact["_id"]))
        .map(
          (contact) => {
            "_id": contact["_id"],
            "name": contact["name"] ?? "No Name",
            "image": contact["image"] ?? "assets/images/dummy.jpg",
            "isInvite": false,
          },
        )
        .toList();

    setState(() {
      _allFriends = availableContacts;
      _filteredFriends = List.from(_allFriends);
    });

    debugPrint("✅ Available friends: $_allFriends");
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredFriends = query.isEmpty
          ? List.from(_allFriends)
          : _allFriends
                .where(
                  (friend) =>
                      (friend['name'] ?? '').toLowerCase().contains(query),
                )
                .toList();
    });
  }

  Future<void> _handleAddMembers() async {
    final selectedIds = _filteredFriends
        .where((f) => f['isInvite'] == true)
        .map((f) => f['_id'].toString())
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one member")),
      );
      return;
    }

    final result = await _groupChatController.addMembersToGroup(
      chatId: widget.chatId,
      newMembers: selectedIds,
    );

    if (result == "success") {
      Get.back();
      await _groupChatController.fetchGroupDetails(widget.chatId);
      Get.snackbar(
        "Success",
        "Members added successfully!",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchField(),
              const SizedBox(height: 24),
              _buildFriendList(),
              const SizedBox(height: 16),
              CustomButton(onTap: _handleAddMembers, text: "Add Now"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ReBack(onTap: () => Get.back()),
        const SizedBox(width: 8),
        Text(
          "Add Group Members",
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Search bar widget
  Widget _buildSearchField() {
    return CustomTextField(
      controller: _searchController,
      borderColor: Colors.transparent,
      suffixIcon: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SvgPicture.asset('assets/icons/search.svg'),
      ),
      hintText: 'Search friends...',
    );
  }

  /// List of available friends (excluding existing members)
  Widget _buildFriendList() {
    if (_filteredFriends.isEmpty) {
      return const Expanded(
        child: Center(child: Text("No available friends found")),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _filteredFriends.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          final friend = _filteredFriends[index];
          String imageUrl = friend['image'] ?? '';
          String name = friend['name'] ?? '';

          return Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryColor,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl.isEmpty ? Text(name[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              CustomCheckboxScreen(
                value: friend['isInvite'],
                onChanged: (val) {
                  setState(() => friend['isInvite'] = val ?? false);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
