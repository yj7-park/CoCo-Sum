import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../models/air_quality_model.dart';
import 'air_quality_datasource.dart';

/// 미세미세(misemise.co.kr)의 S3 공개 데이터를 사용하는 구현체.
///
/// - 데이터: https://s3.ap-northeast-2.amazonaws.com/misemise-fine-dust-data/...
///   CORS: Access-Control-Allow-Origin: * → 웹/모바일 모두 동작
///   전국 670개 측정소, latitude/longitude 포함, 약 1시간마다 갱신
/// - 역지오코딩: Nominatim(OpenStreetMap) — 별도 API 키 불필요
///
/// GPS → 하버사인 최근접 측정소 선택. 역지오코딩 불필요.
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
    // 미세미세 데이터 + 사용자 위치명을 병렬로 가져옴
    final results = await Future.wait([
      _fetchStations(),
      _fetchUserLocationName(latitude, longitude),
    ]);

    final stations = results[0] as List<Map<String, dynamic>>?;
    final userLocationName = results[1] as String?;

    if (stations == null || stations.isEmpty) {
      return AirQualityModel.mock(stationName: '미세미세 데이터 없음');
    }

    final nearest = _findNearest(
      stations: stations,
      userLat: latitude,
      userLon: longitude,
    );

    // ignore: avoid_print
    print('[코코숨] 측정소: ${nearest['stationName']} '
        '(${_haversineKm(latitude, longitude, (nearest['latitude'] as num).toDouble(), (nearest['longitude'] as num).toDouble()).toStringAsFixed(1)}km)');

    return AirQualityModel.fromMisemiseJson(
      nearest,
      userLocationName: userLocationName,
    );
  }

  // ── 미세미세 전국 데이터 ──────────────────────────────────────

  Future<List<Map<String, dynamic>>?> _fetchStations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _dataUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final rawData = response.data?['data'] as Map<String, dynamic>?;
      if (rawData == null) return null;

      return rawData.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((s) => s['latitude'] != null && s['longitude'] != null)
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨] 미세미세 요청 실패: $e');
      return null;
    }
  }

  // ── 사용자 위치명 (Nominatim 역지오코딩) ────────────────────

  /// zoom=8: 특별시/광역시 → 시도+구, 도내 시 → 시도+시 반환.
  /// 예) "서울 중구", "경기 수원시", "부산 연제구"
  Future<String?> _fetchUserLocationName(double lat, double lon) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat.toString(),
          'lon': lon.toString(),
          'accept-language': 'ko',
          'zoom': '8',
        },
        options: Options(
          headers: {
            'User-Agent': 'CoCo-Sum/1.0 (air-quality-app)',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      final address = response.data?['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      // zoom=8 주소 패턴:
      //   특별시/광역시: province="",      city="서울특별시", borough="중구"
      //   도내 시:       province="경기도", city="수원시",     borough=""
      //   도내 군:       province="경기도", city="",           county="양평군"
      final province = address['province']?.toString() ?? '';
      final city     = address['city']?.toString() ?? '';
      final borough  = address['borough']?.toString() ?? '';
      final county   = address['county']?.toString() ?? '';

      // 시도: 도 지역은 province, 특별시/광역시는 city
      final rawSido = province.isNotEmpty ? province : city;
      final sido = _normSido(rawSido);

      // 세부 지역:
      //   특별시/광역시 → borough (city 자체가 sido이므로 제외)
      //   도내 → city(시) 또는 county(군)
      final detail = province.isEmpty
          ? borough  // 특별시/광역시: borough="중구"
          : (city.isNotEmpty ? city : county); // 도내: "수원시" or "양평군"

      if (sido.isEmpty) return null;
      final name = detail.isNotEmpty ? '$sido $detail' : sido;
      // ignore: avoid_print
      print('[코코숨] 사용자 위치: $name');
      return name;
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨] 역지오코딩 실패: $e');
      return null;
    }
  }

  // ── 최근접 측정소 선택 ─────────────────────────────────────

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

  // ── 시도명 정규화 ──────────────────────────────────────────

  static String _normSido(String raw) {
    const map = {
      '서울특별시': '서울', '부산광역시': '부산', '대구광역시': '대구',
      '인천광역시': '인천', '광주광역시': '광주', '대전광역시': '대전',
      '울산광역시': '울산', '세종특별자치시': '세종', '경기도': '경기',
      '강원특별자치도': '강원', '강원도': '강원', '충청북도': '충북',
      '충청남도': '충남', '전라북도': '전북', '전북특별자치도': '전북',
      '전라남도': '전남', '경상북도': '경북', '경상남도': '경남',
      '제주특별자치도': '제주',
    };
    return map[raw] ?? raw;
  }

  // ── 수학 유틸 ─────────────────────────────────────────────

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
