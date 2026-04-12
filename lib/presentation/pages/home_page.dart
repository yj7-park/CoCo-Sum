import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/air_quality.dart';
import '../../services/update_checker.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/action_banner.dart';
import '../widgets/coco_character.dart';
import '../widgets/pollutant_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _updateDialogShown = false;

  @override
  void initState() {
    super.initState();
    // 업데이트 체크는 빌드 이후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watchForUpdate();
    });
  }

  void _watchForUpdate() {
    ref.listenManual(updateInfoProvider, (_, next) {
      next.whenData((info) {
        if (info != null && !_updateDialogShown && mounted) {
          _updateDialogShown = true;
          _showUpdateDialog(context, info);
        }
      });
    });
  }

  void _showUpdateDialog(BuildContext ctx, UpdateInfo info) {
    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => _UpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final airQuality = ref.watch(airQualityProvider);

    return airQuality.when(
      loading: () => _LoadingScreen(),
      error: (e, _) => _ErrorScreen(
        message: e.toString(),
        onRetry: () => ref.invalidate(airQualityProvider),
      ),
      data: (data) => _MainScreen(data: data, ref: ref),
    );
  }
}

// ── 로딩 화면 ─────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.goodBg,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CocoCharacter(grade: AirQualityGrade.good, size: 160),
              const SizedBox(height: 24),
              Text(
                '코코가 공기를 확인 중이에요...',
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  color: AppColors.goodDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 에러 화면 ─────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.moderateBg,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😵', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  '앗, 공기 정보를 가져오지 못했어요',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.moderateDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.moderate,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    '다시 시도',
                    style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 메인 화면 ─────────────────────────────────────────────────

class _MainScreen extends StatelessWidget {
  final AirQuality data;
  final WidgetRef ref;

  const _MainScreen({required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    final grade = data.overallGrade;
    final gradientColors = AppColors.gradient(grade);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _TopBar(data: data, ref: ref),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _CocoSection(grade: grade),
                        const SizedBox(height: 4),
                        _GradeBadge(grade: grade),
                        const SizedBox(height: 20),
                        ActionBanner(grade: grade),
                        const SizedBox(height: 20),
                        _PollutantRow(data: data),
                        if (data.isMockData) ...[
                          const SizedBox(height: 12),
                          _MockDataNotice(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AirQuality data;
  final WidgetRef ref;

  const _TopBar({required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    // 사용자 GPS 위치 (역지오코딩) / 측정소 위치
    final userLoc = data.userLocationName;
    final stationLoc = data.stationLocationShort ?? data.stationName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Flexible(
                  child: _LocationText(
                    userLocation: userLoc,
                    stationLocation: stationLoc,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                timeStr,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => ref.invalidate(airQualityProvider),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "경기 수원시 (경기 팔달구 데이터 기준)" 형태 위치 표시 위젯
class _LocationText extends StatelessWidget {
  final String? userLocation;
  final String stationLocation;

  const _LocationText({
    required this.userLocation,
    required this.stationLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      // 역지오코딩 전/실패: 측정소 위치만 표시
      return Text(
        stationLocation,
        style: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    final isSame = userLocation == stationLocation ||
        stationLocation.startsWith(userLocation!);

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: userLocation,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isSame)
            TextSpan(
              text: ' ($stationLocation 데이터)',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

class _CocoSection extends StatelessWidget {
  final AirQualityGrade grade;
  const _CocoSection({required this.grade});

  @override
  Widget build(BuildContext context) {
    return CocoCharacter(grade: grade, size: 210);
  }
}

class _GradeBadge extends StatelessWidget {
  final AirQualityGrade grade;
  const _GradeBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(grade).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '미세먼지 ${grade.label}',
        style: GoogleFonts.notoSansKr(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.dark(grade),
        ),
      ),
    );
  }
}

class _PollutantRow extends StatelessWidget {
  final AirQuality data;
  const _PollutantRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: PollutantCard(
              label: 'PM2.5 초미세먼지',
              value: data.pm25,
              unit: 'μg/m³',
              grade: data.pm25Grade,
              isMain: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PollutantCard(
              label: 'PM10 미세먼지',
              value: data.pm10,
              unit: 'μg/m³',
              grade: data.pm10Grade,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 업데이트 다이얼로그 ───────────────────────────────────────

class _UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            '업데이트가 있어요!',
            style: GoogleFonts.notoSansKr(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${info.currentVersion} → ${info.latestVersion}',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '변경사항',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.releaseNotes
                  .split('\n')
                  .where((l) => l.trim().isNotEmpty)
                  .take(5)
                  .join('\n'),
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '나중에',
            style: GoogleFonts.notoSansKr(color: Colors.grey[500]),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final uri = Uri.parse(info.downloadUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.good,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '업데이트',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MockDataNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '현재 예시 데이터입니다 (API 연동 전)',
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
