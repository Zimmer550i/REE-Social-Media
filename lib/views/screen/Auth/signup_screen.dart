import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:ree_social_media_app/controllers/auth_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_email_number_field.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Auth/login_screen.dart';
import 'package:ree_social_media_app/views/screen/Auth/otp_verification_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/all_data_page.dart';
import '../../../utils/show_snackbar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController authController = Get.put(AuthController());
  bool isCheck = false;

  final phoneTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();
  CountryCode selectedCountryCode = CountryCode.fromDialCode('+1');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReeLogo(),
              const SizedBox(height: 110),
              Text(
                "Sign Up in \nSeconds",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  fontFamily: "LibreText",
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Create an account to capture and share real reactions",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),

              CustomNumberField(
                controller: phoneTextController,
                hintText: 'Enter your phone number',
                borderSide: const BorderSide(
                  color: Color(0xFFC4C3C3),
                  width: 1,
                ),
                onCountryCodeChanged: (code) {
                  setState(() => selectedCountryCode = code);
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: passwordTextController,
                hintText: 'Enter Password',
                borderSide: const BorderSide(
                  color: Color(0xFFC4C3C3),
                  width: 1,
                ),
                isPassword: true,
                validator: (_) {
                  return authController.validatePassword()
                      ? null
                      : authController.passwordError.value;
                },
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
              const SizedBox(height: 12),
              CustomTextField(
                controller: confirmPasswordTextController,
                hintText: 'Confirm Password',
                borderSide: const BorderSide(
                  color: Color(0xFFC4C3C3),
                  width: 1,
                ),
                isPassword: true,
                validator: (_) {
                  return authController.validatePassword()
                      ? null
                      : authController.passwordError.value;
                },
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
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    activeColor: AppColors.primaryColor,
                    value: isCheck,
                    onChanged: (val) => setState(() => isCheck = val!),
                  ),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: "You agree to the ",
                        style: const TextStyle(
                          color: Color(0xFF676565),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(
                                  () => AllDataScreen(
                                    title: "Terms of Service",
                                    endPoint: '/terms',
                                  ),
                                );
                              },
                          ),
                          const TextSpan(
                            text: " and acknowledge you have read the ",
                            style: TextStyle(
                              color: Color(0xFF676565),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(
                                  () => AllDataScreen(
                                    title: "Privacy Policy",
                                    endPoint: '/privacy',
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),
              Obx(
                () => CustomButton(
                  onTap: () async {
                    final String rawPhone = phoneTextController.text.trim();
                    final String password = passwordTextController.text.trim();
                    final String confirmPassword = confirmPasswordTextController
                        .text
                        .trim();

                    if (rawPhone.isEmpty ||
                        password.isEmpty ||
                        confirmPassword.isEmpty) {
                      showSnackBar('Please fill in all required fields', true);
                      return;
                    }

                    if (password != confirmPassword) {
                      showSnackBar("Passwords do not match", true);
                      return;
                    }

                    if (!isCheck) {
                      showSnackBar(
                        'Please agree to the Terms of Service and Privacy Policy',
                        true,
                      );
                      return;
                    }

                    final String fullPhone =
                        '${selectedCountryCode.dialCode}${rawPhone.replaceAll(RegExp(r'[^0-9]'), '')}';
                    final message = await authController.signup(
                      fullPhone,
                      password,
                      true,
                    );

                    if (message == "success") {
                      Get.to(
                        () => OtpVerificationScreen(emailOrPhone: fullPhone),
                      );
                    } else {
                      showSnackBar(message, true);
                    }
                  },
                  text: "Agree and Continue",
                  loading: authController.isLoading.value,
                ),
              ),

              SizedBox(height: 20),

              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account?",
                    style: TextStyle(
                      color: Color(0xFF676565),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(
                        text: " Log In",
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(
                              () => LoginScreen(),
                              transition: Transition.rightToLeft,
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
