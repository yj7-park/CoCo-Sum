import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../models/air_quality_model.dart';
import 'air_quality_datasource.dart';

/// 미세미세(misemise.co.kr)의 S3 공개 데이터를 사용하는 구현체.
///
/// - URL: https://s3.ap-northeast-2.amazonaws.com/misemise-fine-dust-data/current-data/map-data/data.json
/// - CORS: Access-Control-Allow-Origin: * → 웹/모바일 모두 동작
/// - 전국 670개 측정소, latitude/longitude 포함
/// - 약 1시간마다 갱신
///
/// GPS 좌표를 받아 전국 측정소 중 하버사인 최단거리 측정소 데이터를 반환.
/// 역지오코딩 불필요.
class MisemiseDataSource implements AirQualityDataSource {
  final Dio _dio;

  static const _dataUrl =
      'https://s3.ap-northeast-2.amazonaws.com/misemise-fine-dust-data/current-data/map-data/data.json';

  MisemiseDataSource(this._dio);

  @override
  Future<AirQualityModel> getAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _dataUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final body = response.data;
      final rawData = body?['data'] as Map<String, dynamic>?;
      if (rawData == null || rawData.isEmpty) {
        return AirQualityModel.mock(stationName: '미세미세 데이터 없음');
      }

      final updateTime = (body?['data_info'] as Map?)?['updateTime'] as String?;

      // 좌표 있는 측정소만 필터링
      final stations = rawData.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((s) => s['latitude'] != null && s['longitude'] != null)
          .toList();

      if (stations.isEmpty) {
        return AirQualityModel.mock(stationName: '좌표 없음');
      }

      final nearest = _findNearest(
        stations: stations,
        userLat: latitude,
        userLon: longitude,
      );

      // ignore: avoid_print
      print('[코코숨] 미세미세 측정소: ${nearest['stationName']} '
          '(${_haversineKm(latitude, longitude, (nearest['latitude'] as num).toDouble(), (nearest['longitude'] as num).toDouble()).toStringAsFixed(1)}km, 갱신: $updateTime)');

      return AirQualityModel.fromMisemiseJson(nearest);
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨] 미세미세 요청 실패: $e');
      return AirQualityModel.mock(stationName: '데이터 오류');
    }
  }

  Map<String, dynamic> _findNearest({
    required List<Map<String, dynamic>> stations,
    required double userLat,
    required double userLon,
  }) {
    stations.sort((a, b) {
      final da = _haversineKm(
        userLat, userLon,
        (a['latitude'] as num).toDouble(),
        (a['longitude'] as num).toDouble(),
      );
      final db = _haversineKm(
        userLat, userLon,
        (b['latitude'] as num).toDouble(),
        (b['longitude'] as num).toDouble(),
      );
      return da.compareTo(db);
    });
    return stations.first;
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
