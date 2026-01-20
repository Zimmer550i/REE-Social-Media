import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/services/one_signal_manager.dart';

class AppLifecycleController extends GetxController
    with WidgetsBindingObserver {
  final MessageController messageController = Get.put(MessageController());

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Update badge whenever unreadCount changes
    ever(messageController.unreadCount, (int count) {
      OneSignalHelper.setBadge(count);
    });

    // Listen to push notifications
    // OneSignalHelper.setNotificationReceivedHandler((notification) {
    //   // Increment unread count immediately
    //   messageController.incrementUnread();
    // });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate in case missed notifications
      messageController.calculateUnreadMessages();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}