import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/contact_access_screen.dart';
import 'package:sms_autofill/sms_autofill.dart'; // Import sms_autofill package
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Auth/reset_password_screen.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/show_snackbar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String emailOrPhone;
  final bool? isForgotPassword;
  const OtpVerificationScreen({
    super.key,
    required this.emailOrPhone,
    this.isForgotPassword = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  final AuthController authController = Get.put(AuthController());
  final controllers = List.generate(6, (_) => TextEditingController());
  final nodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    SmsAutoFill().listenForCode();
    listenForCode();
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final n in nodes) {
      n.dispose();
    }
    _timer?.cancel();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleChange(int i, String v) {
    if (v.length == 6) {
      for (int j = 0; j < 6; j++) {
        controllers[j].text = v[j];
      }
      nodes.last.requestFocus();
      setState(() {});
      _verifyCode();
      return;
    }

    if (v.isNotEmpty && i < 5) {
      nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      nodes[i - 1].requestFocus();
    }

    setState(() {});

    final codeValue = controllers.map((c) => c.text).join();
    if (codeValue.length == 6) {
      _verifyCode();
    }
  }

  @override
  void codeUpdated() {
    String? otp = code;

    if (otp == null || otp.length < 6) return;

    for (int i = 0; i < 6; i++) {
      controllers[i].text = otp[i];
    }

    nodes.last.requestFocus();
    setState(() {});
    _verifyCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReeLogo(),
              const SizedBox(height: 110),
              const Text(
                "Check Your\nMessages",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We've sent a 6-digit code",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => _otpBox(i)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _secondsRemaining == 0
                        ? () {
                            _startTimer();
                            authController.sendOtp(widget.emailOrPhone);
                          }
                        : null,
                    child: Text(
                      _secondsRemaining == 0
                          ? "Resend code"
                          : "Resend code after",
                      style: const TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _secondsRemaining == 0 ? "" : "${_secondsRemaining}s",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 92),
              Obx(
                () => CustomButton(
                  loading: authController.isLoading.value,
                  onTap: _verifyCode,
                  text: "Verify and Continue",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyCode() async {
    final code = controllers.map((c) => c.text).join();
    final message = await authController.verifyAccount(
      widget.emailOrPhone,
      code,
    );
    if (message == "success") {
      widget.isForgotPassword == true
          ? Get.to(() => const ResetPasswordScreen())
          : Get.to(() => const ContactAccessScreen());
    } else {
      showSnackBar(message, true);
    }
  }

  Widget _otpBox(int i) {
    final filled = controllers[i].text.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      margin: EdgeInsets.only(right: i == 5 ? 0 : 5),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled ? Colors.transparent : const Color(0xFFC4C3C3),
          width: 1.2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: .35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controllers[i],
        focusNode: nodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofillHints: const [AutofillHints.oneTimeCode],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : AppColors.textColor,
        ),
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,

          /// ✔ FINAL FIX — paste handler (box stays filled)
          TextInputFormatter.withFunction((oldValue, newValue) {
            // User pasted multiple characters
            if (newValue.text.length > 1) {
              final paste = newValue.text;

              if (paste.length >= 6) {
                // Insert the FIRST digit into the SELECTED field
                final firstDigit = paste[0];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Fill remaining 5 digits after the frame
                  for (int j = 0; j < 6; j++) {
                    controllers[j].text = paste[j];
                  }

                  nodes.last.requestFocus();
                  setState(() {});
                  _verifyCode();
                });

                // Return the first digit so the selected box fills!
                return TextEditingValue(
                  text: firstDigit,
                  selection: TextSelection.collapsed(offset: 1),
                );
              }

              // If pasted less than 6 digits, ignore
              return oldValue;
            }

            return newValue;
          }),
        ],
        decoration: const InputDecoration(
          counterText: '',
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '*',
          hintStyle: TextStyle(fontSize: 16, color: Color(0xFFB6B6B6)),
        ),
        cursorColor: AppColors.primaryColor,
        onChanged: (v) => _handleChange(i, v),
      ),
    );
  }
}

class OtpPasteFormatter extends TextInputFormatter {
  final Function(String) onOtpPaste;

  OtpPasteFormatter({required this.onOtpPaste});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if user pasted full OTP
    if (newValue.text.length > 1) {
      onOtpPaste(newValue.text);
      return oldValue; // prevent default insert
    }
    return newValue;
  }
}
