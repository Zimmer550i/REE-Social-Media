import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/auth_controller.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';


class InitialBindings extends Bindings {

  @override
  void dependencies() {
    // Permanent controllers (stay in memory)
    Get.put(AuthController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(MessageController());

  }

  
}