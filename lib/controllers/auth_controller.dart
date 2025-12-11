import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/services/one_signal_manager.dart';
import 'package:ree_social_media_app/views/screen/Auth/login_screen.dart';
import '../services/api_service.dart';
import '../services/shared_prefs_service.dart';
import '../utils/show_snackbar.dart';

class AuthController extends GetxController {
  RxBool isLoggedIn = RxBool(false);
  final api = ApiService();

  // Controller for phone input
  final phoneController = TextEditingController();
  final fullNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observable for phone error message (empty means no error)
  final phoneError = ''.obs;
  final fullNameError = ''.obs;
  final passwordError = ''.obs;

  // Simple email regex pattern for validation
  final RegExp emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

  final RxBool isLoading = false.obs;
  final RxBool isSubscribed = false.obs;

  // Validate phone, returns true if valid
  bool validatephone() {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      phoneError.value = 'phone cannot be empty';
      return false;
    }

    phoneError.value = '';
    return true;
  }

  bool validatePassword() {
    final password = passwordController.text.trim();
    if (password.isEmpty) {
      passwordError.value = 'Password cannot be empty';
      return false;
    }
    passwordError.value = '';
    return true;
  }

  bool validateConfirmPassword() {
    final password = confirmPasswordController.text.trim();
    if (password.isEmpty) {
      passwordError.value = 'Password cannot be empty';
      return false;
    }
    passwordError.value = '';
    return true;
  }

  bool validateFullName() {
    final fullName = fullNameController.text.trim();

    if (fullName.isEmpty) {
      fullNameError.value = 'Full Name cannot be empty';
      return false;
    }
    fullNameError.value = '';
    return true;
  }

  Future<String> login(
    String phone,
    String password, {
    bool rememberMe = true,
  }) async {
    isLoading.value = true;
    try {
      final response = await api.post("/auth/login", {
        "phone": phone.trim(),
        "password": password.trim(),
      });
      var body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.find<UserController>().setInfo(body['data']['user']);
        if (rememberMe) {
          setToken(body['data']['accessToken']);
        }
        isLoading.value = false;

        return "success";
      } else {
        if (body['error'] == "Please verify your phone address.") {
          isLoading.value = false;
          return "verify";
        }
        isLoading.value = false;
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> signup(String phone, String password, bool isPhone) async {
    isLoading.value = true;

    try {
      final response = await api.post("/user/create-user", {
        "phone": phone.trim(),
        "password": password.trim(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        clean();
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return jsonDecode(response.body)['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> sendOtp(String phone) async {
    isLoading.value = true;
    try {
      final response = await api.post("/auth//resend-otp", {
        "phone": phone.trim(),
      });

      if (response.statusCode == 200) {
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return jsonDecode(response.body)['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> forgotPassword(String phone) async {
    isLoading.value = true;
    try {
      final response = await api.post("/auth/forgot-password", {
        "phone": phone.trim(),
      });

      if (response.statusCode == 200) {
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return jsonDecode(response.body)['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> verifyForgotPasswordOtp(String code) async {
    isLoading.value = true;
    try {
      final response = await api.post(
        "v1/account/verify-forget-password-otp/",
        {"otp": code.trim()},
      );
      var body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setToken(body['data']['access_token']);
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> verifyAccount(String phone, String code) async {
    isLoading.value = true;
    try {
      final response = await api.post("/auth/verify-email", {
        "phone": phone.trim(),
        "oneTimeCode": int.parse(code),
      });

      var body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setToken(body['data']['accessToken']);
        await Get.find<UserController>().getInfo();
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        // Handle specific API error message
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      // Handle unexpected error, such as no internet
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> resetPassword(String pass, String conPass) async {
    isLoading.value = true;
    try {
      final response = await api.post("/auth/reset-password", {
        "newPassword": pass.trim(),
        "confirmPassword": conPass.trim(),
      }, authReq: true);
      var body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> changePassword(
    String currentPassword,
    String newPassword,
    String conPassword,
  ) async {
    isLoading.value = true;
    try {
      final response = await api.post("/auth/change-password", {
        "currentPassword": currentPassword.trim(),
        "newPassword": newPassword.trim(),
        "confirmPassword": conPassword.trim(),
      }, authReq: true);
      var body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<String> reportSubmit(String name, String? phone, String report) async {
    isLoading.value = true;
    try {
      final response = await api.post("/report/create-report", {
        "name": name.trim(),
        "phone": phone?.trim() ?? '',
        "content": report.trim(),
      }, authReq: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return jsonDecode(response.body)['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<bool> previouslyLoggedIn() async {
    String? token = await SharedPrefsService.get('token');
    if (token != null) {
      debugPrint('🔍 Token found. Fetching user info...');
      final message = await Get.find<UserController>().getInfo();
      final data = Get.find<UserController>().userInfo.value;

      if (message == "success") {
        if (data == null) {
          return false;
        }
        String name = data.name.toString();
        String image = data.image.toString();
        if (name.isEmpty || image.isEmpty) {
          return false;
        }
        debugPrint("🟡 Token:======> $token");
        isLoggedIn.value = true;
        return true;
      } else if (message == "User doesn't exist!") {
        debugPrint("❌ User doesn't exist.");
        return false;
      } else {
        return false;
      }
    }
    isLoggedIn.value = false;
    return false;
  }

  Future<void> sendInvite(String phoneNumber, String senderName) async {
    try {
      final response = await api.post("/send-invite", {
        "phoneNumber": phoneNumber,
        "senderName": senderName,
      }, authReq: true);

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Invitation sent to $phoneNumber");
      } else {
        Get.snackbar("Error", "Failed: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
    }
  }

  Future<void> logout() async {
    await SharedPrefsService.remove('token');
    OneSignalHelper.optOut();
    await Get.offAll(() => LoginScreen());
    isLoggedIn.value = false;
  }

  Future<void> deleteAccount() async {
    try {
      final response = await api.delete("/user/delete-profile", authReq: true);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await SharedPrefsService.clear();
        Get.offAll(() => LoginScreen());
        showSnackBar("Your account has been deleted", false);
        isLoggedIn.value = false;
      } else {
        showSnackBar("Failed: ${response.body}", true);
      }
    } catch (e) {
      showSnackBar("Something went wrong: $e", true);
    }
  }

  Future<void> setToken(String value) async {
    await SharedPrefsService.set('token', value);
    debugPrint('💾 Token Saved: $value');
  }

  void clean() {
    phoneController.clear();
    fullNameController.clear();
    passwordController.clear();
  }

  @override
  void dispose() {
    super.dispose();
    phoneController.dispose();
    fullNameController.dispose();
    passwordController.dispose();
  }
}
