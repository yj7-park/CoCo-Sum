import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/air_quality.dart';

class AppColors {
  AppColors._();

  // 최고 — 맑은 하늘
  static const best = Color(0xFF29B6F6);
  static const bestDark = Color(0xFF0277BD);
  static const bestBg = [Color(0xFF87CEEB), Color(0xFFD4EDFF)];

  // 좋음 — 파란 하늘
  static const good = Color(0xFF4FC3F7);
  static const goodDark = Color(0xFF0288D1);
  static const goodBg = [Color(0xFFAFDEF5), Color(0xFFDFF0FA)];

  // 양호 — 민트/청록
  static const fine = Color(0xFF4DB6AC);
  static const fineDark = Color(0xFF00695C);
  static const fineBg = [Color(0xFF80CBC4), Color(0xFFE0F2F1)];

  // 보통 — 연두/노랑
  static const moderate = Color(0xFF9CCC65);
  static const moderateDark = Color(0xFF558B2F);
  static const moderateBg = [Color(0xFFB5D879), Color(0xFFECF7CC)];

  // 나쁨 — 황/노랑
  static const bad = Color(0xFFFFCA28);
  static const badDark = Color(0xFFF57F17);
  static const badBg = [Color(0xFFFFE082), Color(0xFFFFF9C4)];

  // 상당히나쁨 — 주황
  static const quiteBad = Color(0xFFFF8C42);
  static const quiteBadDark = Color(0xFFE65100);
  static const quiteBadBg = [Color(0xFFFF8C42), Color(0xFFFFDDB8)];

  // 매우나쁨 — 빨강
  static const veryBad = Color(0xFFEF5350);
  static const veryBadDark = Color(0xFFB71C1C);
  static const veryBadBg = [Color(0xFFEF9A9A), Color(0xFFFFEBEE)];

  // 최악 — 보라/짙은
  static const worst = Color(0xFFC75B7A);
  static const worstDark = Color(0xFF880E4F);
  static const worstBg = [Color(0xFFC75B7A), Color(0xFFEDB8CC)];

  static Color primary(AirQualityGrade g) => switch (g) {
        AirQualityGrade.best => best,
        AirQualityGrade.good => good,
        AirQualityGrade.fine => fine,
        AirQualityGrade.moderate => moderate,
        AirQualityGrade.bad => bad,
        AirQualityGrade.quiteBad => quiteBad,
        AirQualityGrade.veryBad => veryBad,
        AirQualityGrade.worst => worst,
      };

  static Color dark(AirQualityGrade g) => switch (g) {
        AirQualityGrade.best => bestDark,
        AirQualityGrade.good => goodDark,
        AirQualityGrade.fine => fineDark,
        AirQualityGrade.moderate => moderateDark,
        AirQualityGrade.bad => badDark,
        AirQualityGrade.quiteBad => quiteBadDark,
        AirQualityGrade.veryBad => veryBadDark,
        AirQualityGrade.worst => worstDark,
      };

  static List<Color> gradient(AirQualityGrade g) => switch (g) {
        AirQualityGrade.best => bestBg,
        AirQualityGrade.good => goodBg,
        AirQualityGrade.fine => fineBg,
        AirQualityGrade.moderate => moderateBg,
        AirQualityGrade.bad => badBg,
        AirQualityGrade.quiteBad => quiteBadBg,
        AirQualityGrade.veryBad => veryBadBg,
        AirQualityGrade.worst => worstBg,
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
