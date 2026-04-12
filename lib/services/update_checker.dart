import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

/// GitHub Releases API를 통해 최신 버전을 확인하고,
/// 현재 설치된 버전보다 새 버전이 있으면 [UpdateInfo]를 반환합니다.
///
/// Android APK 사이드로딩 환경에서 자동 업데이트 체크 용도.
/// 웹에서는 동작하지 않습니다 (항상 null 반환).
class UpdateChecker {
  final Dio _dio;
  static const _owner = 'yj7-park';
  static const _repo = 'CoCo-Sum';

  UpdateChecker(this._dio);

  /// 업데이트가 있으면 [UpdateInfo] 반환, 없으면 null.
  Future<UpdateInfo?> checkForUpdate() async {
    // 웹에서는 업데이트 체크 불필요
    if (kIsWeb) return null;

    try {
      final currentInfo = await PackageInfo.fromPlatform();
      final currentVersion = currentInfo.version; // "1.0.2"

      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      final data = response.data;
      if (data == null) return null;

      final tagName = data['tag_name'] as String? ?? ''; // "v1.0.3"
      final latestVersion = tagName.replaceFirst('v', '');
      final releaseNotes = data['body'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? '';

      // assets에서 arm64 APK URL 찾기
      final assets = (data['assets'] as List?)?.cast<Map>() ?? [];
      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String? ?? '').contains('arm64'),
        orElse: () => assets.isNotEmpty ? assets.first : <String, dynamic>{},
      );
      final apkUrl = apkAsset['browser_download_url'] as String? ?? htmlUrl;

      if (!_isNewer(latestVersion, currentVersion)) return null;

      // ignore: avoid_print
      print('[코코숨] 업데이트 발견: $currentVersion → $latestVersion');

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseNotes: releaseNotes,
        downloadUrl: apkUrl,
        releasePageUrl: htmlUrl,
      );
    } catch (e) {
      // 업데이트 체크 실패는 조용히 무시 (네트워크 오류 등)
      // ignore: avoid_print
      print('[코코숨] 업데이트 체크 실패: $e');
      return null;
    }
  }

  /// "1.0.3" > "1.0.1" 인지 비교 (semantic versioning 주요 부분).
  static bool _isNewer(String latest, String current) {
    try {
      final l = _parts(latest);
      final c = _parts(current);
      for (int i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parts(String v) {
    final parts = v.split('.');
    while (parts.length < 3) { parts.add('0'); }
    return parts.take(3).map((p) => int.tryParse(p) ?? 0).toList();
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;  // 직접 APK 다운로드 URL (arm64)
  final String releasePageUrl; // GitHub Release 페이지

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
  });
}
