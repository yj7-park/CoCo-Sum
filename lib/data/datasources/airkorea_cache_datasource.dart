import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../models/air_quality_model.dart';
import 'air_quality_datasource.dart';

/// Flutter Web 전용 DataSource.
///
/// GitHub Actions 스케줄 워크플로(`cache-airkorea.yml`)가 30분마다
/// 에어코리아 전국 측정소 데이터를 `gh-pages` 브랜치의
/// `data/airquality_cache.json`에 저장하고,
/// 이 클래스는 같은 origin에서 그 파일을 가져옵니다 → CORS 없음.
///
/// GPS 좌표를 받으면 캐시된 전국 측정소 중 하버사인 최단거리로
/// 가장 가까운 측정소를 선택합니다.
class AirKoreaCacheDataSource implements AirQualityDataSource {
  final Dio _dio;

  // 같은 origin이므로 상대 경로로 요청 가능; 절대경로로도 동작
  static const _cacheUrl = './data/airquality_cache.json';

  AirKoreaCacheDataSource(this._dio);

  @override
  Future<AirQualityModel> getAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _cacheUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data;
      final rawList = data?['stations'] as List<dynamic>?;
      if (rawList == null || rawList.isEmpty) {
        return AirQualityModel.mock(stationName: '데이터 없음');
      }

      final stations = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final nearest = _findNearest(
        stations: stations,
        userLat: latitude,
        userLon: longitude,
      );

      // ignore: avoid_print
      print('[코코숨-웹] 캐시 측정소: ${nearest['stationName']} '
          '(갱신: ${data?['updatedAt'] ?? '?'})');

      return AirQualityModel.fromAirKoreaJson(nearest);
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨-웹] 캐시 로드 실패: $e');
      return AirQualityModel.mock(stationName: '웹 데모');
    }
  }

  Map<String, dynamic> _findNearest({
    required List<Map<String, dynamic>> stations,
    required double userLat,
    required double userLon,
  }) {
    // dmX = 경도, dmY = 위도
    final withCoords = stations.where((s) {
      final x = s['dmX']?.toString().trim() ?? '';
      final y = s['dmY']?.toString().trim() ?? '';
      return x.isNotEmpty && x != '-' && y.isNotEmpty && y != '-';
    }).toList();

    if (withCoords.isEmpty) return stations.first;

    withCoords.sort((a, b) {
      final da = _haversineKm(
        userLat, userLon,
        double.tryParse(a['dmY'].toString()) ?? 0,
        double.tryParse(a['dmX'].toString()) ?? 0,
      );
      final db = _haversineKm(
        userLat, userLon,
        double.tryParse(b['dmY'].toString()) ?? 0,
        double.tryParse(b['dmX'].toString()) ?? 0,
      );
      return da.compareTo(db);
    });

    final best = withCoords.first;
    final dist = _haversineKm(
      userLat, userLon,
      double.tryParse(best['dmY'].toString()) ?? 0,
      double.tryParse(best['dmX'].toString()) ?? 0,
    );
    // ignore: avoid_print
    print('[코코숨-웹] 최근접: ${best['stationName']} (${dist.toStringAsFixed(1)}km)');
    return best;
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
