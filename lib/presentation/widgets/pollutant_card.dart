import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/air_quality.dart';
import '../theme/app_theme.dart';

class PollutantCard extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final AirQualityGrade grade;
  final bool isMain;

  const PollutantCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.grade,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary(grade);
    final valueText = value != null ? value!.toStringAsFixed(0) : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              _GradeDot(color: color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valueText,
                style: GoogleFonts.notoSansKr(
                  fontSize: isMain ? 36 : 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark(grade),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 등급 막대
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _gradeToProgress(grade),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            grade.label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _gradeToProgress(AirQualityGrade g) => switch (g) {
        AirQualityGrade.good => 0.25,
        AirQualityGrade.moderate => 0.50,
        AirQualityGrade.bad => 0.75,
        AirQualityGrade.veryBad => 1.0,
      };
}

class _GradeDot extends StatelessWidget {
  final Color color;
  const _GradeDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
        ],
      ),
    );
  }
}
