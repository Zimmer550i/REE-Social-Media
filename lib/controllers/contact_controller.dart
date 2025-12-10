// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:ree_social_media_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactController extends GetxController {
  var matchedContacts = <Map<String, dynamic>>[].obs;
  var unmatchedContacts = <Map<String, dynamic>>[].obs;
  var filteredMatchedContacts = <Map<String, dynamic>>[].obs;
  var filteredUnmatchedContacts = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  final api = ApiService();

  /// Fetch contacts from device & send to API
  Future<void> fetchContacts() async {
    try {
      isLoading.value = true;

      if (await FlutterContacts.requestPermission()) {
        final rawContacts = await FlutterContacts.getContacts(
          withProperties: true,
        );

        // Convert contacts to List<Map<String, dynamic>> for isolate-safe processing
        final List<Map<String, dynamic>> contactMaps = rawContacts.map((c) {
          return {
            "displayName": c.displayName,
            "phones": c.phones.map((p) => p.number).toList(),
          };
        }).toList();

        final contactList = await compute(_processContacts, contactMaps);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("saved_contacts", jsonEncode(contactList));

        await sendContactsToApi(contactList);
      }
    } catch (e) {
      debugPrint("🚨 Error fetching contacts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  static List<Map<String, dynamic>> _processContacts(
    List<Map<String, dynamic>> rawContacts,
  ) {
    final expanded = rawContacts.expand((c) {
      final phones = c["phones"] as List<dynamic>? ?? [];
      if (phones.isEmpty) return [];
      return phones.map((phone) {
        String cleanedNumber = (phone as String).replaceAll(
          RegExp(r'[^\d+]'),
          '',
        );
        if (!cleanedNumber.startsWith("+")) {
          cleanedNumber = "+1$cleanedNumber"; // default country code
        }
        return {"name": c["displayName"], "phone": cleanedNumber};
      });
    });
    return List<Map<String, dynamic>>.from(expanded);
  }

  Future<void> sendInviteSms(
    BuildContext context,
    String number,
    String name,
  ) async {
    String link = Platform.isIOS
        ? ""
        : "https://play.google.com/store/apps/details?id=com.re.socialmedia";
    // 1️⃣ Create the message
    final message =
        "Join me on re: The app that makes sharing photos and videos more fun by capturing real reactions. Download here - $link";

    // 2️⃣ Encode the message for URI
    final encodedMessage = Uri.encodeComponent(message);

    // 3️⃣ Build the SMS URI
    final smsUri = Uri.parse('sms:$number?body=$encodedMessage');

    try {
      // 4️⃣ Launch the SMS app explicitly
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication, // Forces external SMS app
        );
      } else {
        // 5️⃣ Handle case when no SMS app is available
        debugPrint("❌ Could not launch SMS app. URI: $smsUri");
        _showErrorDialog(context, "No SMS app found on this device.");
      }
    } catch (e) {
      debugPrint("❌ Error launching SMS: $e");
      _showErrorDialog(context, "Failed to open SMS app.");
    }
  }

  // Helper function to show an error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Send contacts to backend
  Future<void> sendContactsToApi(List<Map<String, dynamic>> contactList) async {
    try {
      final response = await api.postRaw(
        "/user/contact",
        contactList,
        authReq: true,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        matchedContacts.assignAll(
          List<Map<String, dynamic>>.from(decoded["data"]["match"]),
        );
        unmatchedContacts.assignAll(
          List<Map<String, dynamic>>.from(decoded["data"]["unmatch"]),
        );

        // Initially all contacts are shown
        filteredMatchedContacts.assignAll(matchedContacts);
        filteredUnmatchedContacts.assignAll(unmatchedContacts);

        debugPrint("✅ Matched Contacts: ${matchedContacts.length}");
        debugPrint("✅ Unmatched Contacts: ${unmatchedContacts.length}");
      } else {
        debugPrint("❌ Failed to upload contacts: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🚨 Error sending contacts: $e");
    }
  }

  /// 🔍 Search Function
  void filterContacts(String query) {
    if (query.isEmpty) {
      filteredMatchedContacts.assignAll(matchedContacts);
      filteredUnmatchedContacts.assignAll(unmatchedContacts);
    } else {
      final lower = query.toLowerCase();
      filteredMatchedContacts.assignAll(
        matchedContacts.where(
          (c) =>
              (c["name"] ?? "").toLowerCase().contains(lower) ||
              (c["phone"] ?? "").toLowerCase().contains(lower),
        ),
      );
      filteredUnmatchedContacts.assignAll(
        unmatchedContacts.where(
          (c) =>
              (c["name"] ?? "").toLowerCase().contains(lower) ||
              (c["phone"] ?? "").toLowerCase().contains(lower),
        ),
      );
    }
  }

  Future<void> createPrivateChat(String memberId) async {
    isLoading.value = true;
    try {
      final response = await api.post("/chat/create-private", {
        "member": memberId,
      }, authReq: true);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = body['data']['_id'];
        debugPrint("✅ Private chat created with ID: $chatId");
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating private chat: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
