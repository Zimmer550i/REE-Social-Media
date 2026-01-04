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

    ever(messageController.unreadCount, (int count) {
      OneSignalHelper.setBadge(count);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      messageController.calculateUnreadMessages();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}