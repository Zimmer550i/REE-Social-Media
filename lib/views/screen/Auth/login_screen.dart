import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/auth_controller.dart';
import 'package:ree_social_media_app/services/one_signal_manager.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_email_number_field.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Auth/forget_password.dart';
import 'package:ree_social_media_app/views/screen/Auth/signup_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/message_screen.dart';
import '../../../utils/show_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.put(AuthController());

  final phoneTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  CountryCode selectedCountryCode = CountryCode.fromDialCode('+1');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
  
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReeLogo(),
              SizedBox(height: 110),
              Text(
                "Welcome!",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 40),
              CustomNumberField(
                controller: phoneTextController,
                hintText: 'Enter your phone number',
                borderSide: BorderSide(color: Color(0xFFC4C3C3), width: 1),
                onCountryCodeChanged: (code) {
                  setState(() => selectedCountryCode = code);
                },
              ),
              SizedBox(height: 12),
              CustomTextField(
                controller: passwordTextController,
                hintText: 'Enter Password',
                isPassword: true,
                borderSide: BorderSide(color: Color(0xFFC4C3C3), width: 1),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SvgPicture.asset('assets/icons/lock.svg'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Get.to(() => ForgetPassword());
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Obx(
                () => CustomButton(
                  onTap: () async {
                    final String fullPhone =
                        '${selectedCountryCode.dialCode}${phoneTextController.text.replaceAll(RegExp(r'[^0-9]'), '')}';
                    if (phoneTextController.text.isEmpty ||
                        passwordTextController.text.isEmpty) {
                      showSnackBar("Please fill in all required fields", true);
                    } else {
                      final message = await authController.login(
                        fullPhone,
                        passwordTextController.text,
                      );
                      if (message == "success") {
                        OneSignalHelper.optIn();
                        Get.offAll(() => MessageScreen());
                      } else if (message == "verify") {
                        showSnackBar("Please verify your email address", true);
                      } else {
                        showSnackBar(message, true);
                      }
                    }
                  },
                  text: "Log In",
                  loading: authController.isLoading.value,
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don’t have an account?",
                    style: TextStyle(
                      color: Color(0xFF676565),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(
                        text: " Sign up",
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(
                              () => SignupScreen(),
                              transition: Transition.leftToRight,
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
