import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';


ThemeData dark({Color color = const Color(0xFF2683EB)}) => ThemeData(
  fontFamily: 'LibreText',
  primaryColor: color,
  scaffoldBackgroundColor:AppColors.backgroundColor,
  secondaryHeaderColor:  color.withValues(alpha: 0.4),
  disabledColor:AppColors.subTextColor,
  brightness: Brightness.dark,
  hintColor:AppColors.hintColor,
  cardColor:AppColors.cardColor,
  dividerColor: AppColors.dividerColor,
  shadowColor: AppColors.shadowColor,
  canvasColor: AppColors.bottomBarColor,

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.fillColor,
    hintStyle: TextStyle(color:AppColors.hintColor,fontSize:16),
    isDense: true,
    contentPadding:EdgeInsets.symmetric(
      horizontal:12,
      vertical: 16
    ),
    enabledBorder: enableBorder(),
    focusedBorder: focusedBorder(),
    errorBorder:errorBorder()

  ),
  bottomNavigationBarTheme:  BottomNavigationBarThemeData(
    backgroundColor:AppColors.bottomBarColor,
    selectedLabelStyle: TextStyle(color:color),
    unselectedLabelStyle: TextStyle(color:AppColors.subTextColor),
  ),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: color)), colorScheme: ColorScheme.dark(primary: color, secondary: color).copyWith(surface: Color(0xFF343636)).copyWith(error: Color(0xFFdd3135)),
);

OutlineInputBorder enableBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  );
}
OutlineInputBorder focusedBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide:BorderSide(
      color: AppColors.primaryColor,
    ),
  );
}

OutlineInputBorder errorBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide:const BorderSide(
      color: Colors.red,
    ),
  );
}