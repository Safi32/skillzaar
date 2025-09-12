import 'package:flutter/material.dart';

class AppColors {
  static const Color green = Color(0xFF13B94B);
}

class AppTheme {
  static ThemeData get themeData => ThemeData(
    primaryColor: AppColors.green,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: AppColors.green,
      secondary: AppColors.green,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.green),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    ),
  );
}
