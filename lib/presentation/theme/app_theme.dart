import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/air_quality.dart';

class AppColors {
  AppColors._();

  // 좋음 — 파란 하늘
  static const good = Color(0xFF4FC3F7);
  static const goodDark = Color(0xFF0288D1);
  static const goodBg = [Color(0xFF87CEEB), Color(0xFFD4EDFF)];

  // 보통 — 연두/노랑
  static const moderate = Color(0xFF9CCC65);
  static const moderateDark = Color(0xFF558B2F);
  static const moderateBg = [Color(0xFFB5D879), Color(0xFFECF7CC)];

  // 나쁨 — 주황
  static const bad = Color(0xFFFF8C42);
  static const badDark = Color(0xFFE65100);
  static const badBg = [Color(0xFFFF8C42), Color(0xFFFFDDB8)];

  // 매우나쁨 — 보라/빨강
  static const veryBad = Color(0xFFC75B7A);
  static const veryBadDark = Color(0xFF880E4F);
  static const veryBadBg = [Color(0xFFC75B7A), Color(0xFFEDB8CC)];

  static Color primary(AirQualityGrade g) => switch (g) {
        AirQualityGrade.good => good,
        AirQualityGrade.moderate => moderate,
        AirQualityGrade.bad => bad,
        AirQualityGrade.veryBad => veryBad,
      };

  static Color dark(AirQualityGrade g) => switch (g) {
        AirQualityGrade.good => goodDark,
        AirQualityGrade.moderate => moderateDark,
        AirQualityGrade.bad => badDark,
        AirQualityGrade.veryBad => veryBadDark,
      };

  static List<Color> gradient(AirQualityGrade g) => switch (g) {
        AirQualityGrade.good => goodBg,
        AirQualityGrade.moderate => moderateBg,
        AirQualityGrade.bad => badBg,
        AirQualityGrade.veryBad => veryBadBg,
      };
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.good),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
        scaffoldBackgroundColor: Colors.transparent,
      );
}
