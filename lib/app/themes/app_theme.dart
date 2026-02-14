import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgRose,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink500),
      fontFamily: null,
    );
  }
}
