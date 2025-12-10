import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/localization_controller.dart';
import 'package:ree_social_media_app/controllers/theme_controller.dart';
import 'package:ree_social_media_app/helpers/dependency_injection.dart';
import 'package:ree_social_media_app/services/one_signal_manager.dart';
import 'package:ree_social_media_app/services/shared_prefs_service.dart';
import 'package:ree_social_media_app/services/socket_manager.dart';
import 'package:ree_social_media_app/themes/light_theme.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/app_constants.dart';
import 'package:ree_social_media_app/utils/message.dart';
import 'helpers/di.dart' as di;
import 'helpers/route.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OneSignalHelper.initialize();
  // await GlobalCameraManager.dispose();
  // GlobalVideoPlayerManager.dispose();

  await Future.delayed(const Duration(milliseconds: 200));

  // Initialize DI
  Map<String, Map<String, String>> languages = await di.init();
  InitialBindings().dependencies();
  try {
    final token = await SharedPrefsService.get('token');
    SocketService.connect(token.toString());
    // Load available cameras safely
    cameras = await availableCameras();
    AppRoutes.cameras = cameras;
  } catch (e) {
    debugPrint("Camera init error: $e");
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp(languages: languages));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.languages});
  final Map<String, Map<String, String>> languages;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetBuilder<LocalizationController>(
          builder: (localizeController) {
            return GetMaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: light(),
              defaultTransition: Transition.topLevel,
              locale: localizeController.locale,
              translations: Messages(languages: languages),
              fallbackLocale: Locale(
                AppConstants.languages[0].languageCode,
                AppConstants.languages[0].countryCode,
              ),
              transitionDuration: const Duration(milliseconds: 500),
              getPages: AppRoutes.page,
              initialRoute: AppRoutes.splashScreen,
              builder: (context, child) {
                return TextSelectionTheme(
                  data: TextSelectionThemeData(
                    selectionColor: AppColors.primaryColor,
                    cursorColor: AppColors.primaryColor,
                    selectionHandleColor: AppColors.primaryColor,
                  ),
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}
