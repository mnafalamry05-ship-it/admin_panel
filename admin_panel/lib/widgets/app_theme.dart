import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1a237e);
  static const primaryDark = Color(0xFF0d1456);
  static const primaryLight = Color(0xFF283593);
  static const secondary = Color(0xFF1565C0);
  static const accent = Color(0xFF0288D1);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFE65100);
  static const error = Color(0xFFC62828);
  static const surface = Color(0xFFF5F7FF);
  static const background = Color(0xFFF0F2FA);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE0E4F0);
}

class AppTextStyles {
  static const String fontFamily = 'Cairo';

  static const heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const amount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );
}
