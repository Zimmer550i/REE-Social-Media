import 'package:flutter/material.dart';

class AppColors {
  static Color primaryColor = const Color(0xFF1A1A1A);
  static Color backgroundColor = Colors.white;
  static Color cardColor = const Color(0xFF2F2F2F);
  static Color cardLightColor = const Color(0xFF555555);
  static Color borderColor = const Color(0xFF1A1A1A);
  static Color textColor = const Color(0xFF413E3E);
  static Color subTextColor = const Color(0xFFE8E8E8);
  static Color hintColor = const Color(0xFF676565);
  static Color greyColor = const Color(0xFFB5B5B5);
  static Color fillColor = const Color(0xFF1A1A1A).withValues(alpha: 0.3);
  static Color dividerColor = const Color(0xFF555555);
  static Color shadowColor = const Color(0xFF2B2A2A);
  static Color bottomBarColor = const Color(0xFF343434);
  static Color black100 = const Color(0xFFC4C3C3);
  static Color frameColors = const Color(0xFF383838);

  static BoxShadow shadow = BoxShadow(
    blurRadius: 4,
    spreadRadius: 0,
    color: shadowColor,
    offset: const Offset(0, 2),
  );
}
