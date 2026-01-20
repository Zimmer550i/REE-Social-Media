// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchTextController = TextEditingController();

  final ContactController contactController = Get.put(ContactController());
  final UserController userController = Get.put(UserController());

  RxList<Map<String, dynamic>> filteredContacts = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();

    // fetch contacts from controller
    contactController.fetchContacts().then((_) {
      filteredContacts.assignAll(contactController.matchedContacts);
    });

    // listen to search field
    searchTextController.addListener(_filterContacts);
  }

  void _filterContacts() {
    final query = searchTextController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredContacts.assignAll(contactController.matchedContacts);
    } else {
      final results = contactController.matchedContacts.where((contact) {
        final name = (contact['name'] ?? '').toString().toLowerCase();
        final phone = (contact['phone'] ?? '').toString().toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
      filteredContacts.assignAll(results);
    }
  }

  @override
  void dispose() {
    searchTextController.removeListener(_filterContacts);
    searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  ReeLogo(),
                  const Spacer(),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFC4C3C3),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(Icons.close),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 24),
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

              // 🔹 Contact List
              Expanded(
                child: Obx(() {
                  if (contactController.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }

                  if (filteredContacts.isEmpty) {
                    return const Center(
                      child: Text(
                        "No contacts found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredContacts.length,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final c = filteredContacts[index];
                      final imageUrl = userController.addBaseUrl(c['image']);
                      final name = c['name'] ?? 'Unknown';
                      final phone = c['phone'] ?? '';

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryColor,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : const AssetImage("assets/images/dummy.jpg")
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          SvgPicture.asset(
                            "assets/icons/message.svg",
                            color: AppColors.primaryColor,
                            height: 22,
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
