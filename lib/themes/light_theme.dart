import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

ThemeData light() => ThemeData(
  fontFamily: 'Inter',
  primaryColor: AppColors.primaryColor,
  secondaryHeaderColor: Color(0xFF1ED7AA),
  disabledColor: Color(0xFFBABFC4),
  brightness: Brightness.light,

  hintColor: Color(0xFF9F9F9F),
  cardColor: Colors.white,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
    elevation: 5,
  ),

  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor)),
  colorScheme: ColorScheme.light(primary: AppColors.primaryColor, secondary: AppColors.primaryColor).copyWith(surface: const Color(0xFFF3F3F3)).copyWith(error: Color(0xFFE84D4F)),
);