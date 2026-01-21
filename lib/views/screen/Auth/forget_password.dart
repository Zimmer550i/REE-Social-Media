import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_email_number_field.dart';
import 'package:ree_social_media_app/views/screen/Auth/otp_verification_screen.dart';

import '../../../controllers/auth_controller.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final AuthController authController = Get.put(AuthController());
  final emailTextController = TextEditingController();
  CountryCode selectedCountryCode = CountryCode.fromDialCode('+1'); // ✅ Added

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: AppColors.backgroundColor,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReeLogo(),
              SizedBox(height: 110),
              Text(
                "Let’s get you \nback in",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  fontFamily: "LibreText"
                ),
              ),
              SizedBox(height: 40),
              CustomNumberField(
                controller: emailTextController,
                hintText: 'Enter your phone number',
                borderSide: BorderSide(color: Color(0xFFC4C3C3), width: 1),
                onCountryCodeChanged: (code) {
                  setState(() => selectedCountryCode = code);
                },
              ),
              SizedBox(height: 80),
              Obx(
                () => CustomButton(
                  loading: authController.isLoading.value,
                  onTap: () async {
                    final String fullPhone =
                        '${selectedCountryCode.dialCode}${emailTextController.text.replaceAll(RegExp(r'[^0-9]'), '')}';
                    debugPrint("Full phone number: $fullPhone");
                    final message = await authController.forgotPassword(
                      fullPhone,
                    );
                    if (message == "success") {
                      Get.snackbar("Success", "Check your phone for OTP");
                      Get.to(
                        () => OtpVerificationScreen(
                          emailOrPhone: fullPhone,
                          isForgotPassword: true,
                        ),
                      );
                    } else {
                      Get.snackbar("Error", message);
                    }
                  },
                  text: "Send Code",
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Back to",
                    style: TextStyle(
                      color: Color(0xFF676565),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Text(
                      "Log In",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
