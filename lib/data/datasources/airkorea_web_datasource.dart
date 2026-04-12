import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../models/air_quality_model.dart';
import 'air_quality_datasource.dart';

/// 에어코리아 웹사이트 내부 AJAX 엔드포인트를 통해 데이터를 가져오는 구현체.
///
/// ## 측정소 선택 전략 (우선순위 순)
/// 1. 좌표 우선 — 응답에 dmX/dmY(경위도)가 있으면 하버사인 공식으로 최근접 측정소 선택
/// 2. 행정구역 매칭 — 역지오코딩으로 얻은 구/군명과 stationName 문자열 매칭
/// 3. Fallback — 시도 내 첫 번째 측정소
///
/// ## 공식 API 교체 시
/// 이 파일을 복사해 `airkorea_api_datasource.dart`로 이름 변경 후
/// `_fetchAllStations`의 URL을 아래로 교체하세요:
///
/// ```
/// GET https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty
///   ?serviceKey={API_KEY}
///   &sidoName={시도명}
///   &searchCondition=HOUR
///   &numOfRows=100&pageNo=1&returnType=json
/// ```
/// 공식 API는 응답에 dmX/dmY가 없으므로 별도로
/// `getMsrstnList` 호출 후 TM좌표 → WGS84 변환이 필요합니다.
class AirKoreaWebDataSource implements AirQualityDataSource {
  final Dio _dio;

  static const _baseUrl = 'https://www.airkorea.or.kr';
  static const _endpoint = '/web/ajax/getCtprvnRltmMesureDnsty';

  AirKoreaWebDataSource(this._dio);

  // ── 공개 인터페이스 ──────────────────────────────────────────

  @override
  Future<AirQualityModel> getAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final location = await _resolveLocation(latitude, longitude);
    final stations = await _fetchAllStations(location.sidoName);

    if (stations == null || stations.isEmpty) {
      return AirQualityModel.mock(stationName: '${location.sidoName} 측정소');
    }

    final nearest = _findNearest(
      stations: stations,
      userLat: latitude,
      userLon: longitude,
      districtHint: location.districtName,
    );

    return AirQualityModel.fromAirKoreaJson(nearest);
  }

  // ── 위치 정보 취득 ────────────────────────────────────────────

  /// Nominatim(OpenStreetMap) 역지오코딩 — 웹/모바일 모두 동작.
  /// geocoding 패키지의 placemarkFromCoordinates는 Flutter Web에서
  /// UnimplementedError를 던지므로 직접 HTTP 호출로 대체.
  Future<_LocationInfo> _resolveLocation(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat.toString(),
          'lon': lon.toString(),
          'accept-language': 'ko',
          'zoom': '8', // zoom=8: 특별시/광역시→city, 도→province+city 모두 반환
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

      final address = response.data['address'] as Map<String, dynamic>?;
      if (address != null) {
        // zoom=8 기준 한국 주소 필드 패턴:
        //   특별시/광역시: province 없음, city="서울특별시", borough="중구"
        //   도 내 시: province="경기도", city="수원시"
        //   도 내 군: province="경기도", county="양평군"
        final rawProvince = address['province']?.toString() ?? '';
        final rawCity = address['city']?.toString() ?? '';
        // 시도 = province 우선(도 단위), 없으면 city(특별시/광역시)
        final sido = _normalizeAdminArea(
            rawProvince.isNotEmpty ? rawProvince : rawCity);

        // 구/군 힌트: borough(광역시 구) → city(도내 시) → county(도내 군)
        final district = (address['borough'] ??
                address['city'] ??
                address['county'])
            ?.toString();

        // ignore: avoid_print
        print('[코코숨] 역지오코딩(Nominatim): sido=$sido, district=$district');
        return _LocationInfo(sidoName: sido, districtName: district);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨] 역지오코딩 실패: $e');
    }
    return const _LocationInfo(sidoName: '서울');
  }

  /// "경기도" → "경기", "서울특별시" → "서울" 등 에어코리아 포맷으로 정규화.
  static String _normalizeAdminArea(String raw) {
    const exact = {
      '서울특별시': '서울',
      '부산광역시': '부산',
      '대구광역시': '대구',
      '인천광역시': '인천',
      '광주광역시': '광주',
      '대전광역시': '대전',
      '울산광역시': '울산',
      '세종특별자치시': '세종',
      '경기도': '경기',
      '강원특별자치도': '강원',
      '강원도': '강원',
      '충청북도': '충북',
      '충청남도': '충남',
      '전라북도': '전북',
      '전북특별자치도': '전북',
      '전라남도': '전남',
      '경상북도': '경북',
      '경상남도': '경남',
      '제주특별자치도': '제주',
    };
    if (exact.containsKey(raw)) return exact[raw]!;

    for (final suffix in ['특별자치도', '특별자치시', '광역시', '특별시', '도', '시']) {
      if (raw.endsWith(suffix)) {
        return raw.substring(0, raw.length - suffix.length);
      }
    }
    return raw.isEmpty ? '서울' : raw;
  }

  // ── 데이터 취득 ───────────────────────────────────────────────

  /// 시도 내 모든 측정소 데이터를 한 번에 가져옴 (numOfRows=100).
  Future<List<Map<String, dynamic>>?> _fetchAllStations(String sidoName) async {
    try {
      final response = await _dio.get(
        '$_baseUrl$_endpoint',
        queryParameters: {
          'sidoName': sidoName,
          'searchCondition': 'HOUR',
          'numOfRows': '100',
          'pageNo': '1',
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                    'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/21A329',
            'Referer': _baseUrl,
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'X-Requested-With': 'XMLHttpRequest',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      List<dynamic>? raw;
      final data = response.data;
      if (data is Map) {
        raw = (data['list'] ?? data['data'] ?? data['items']) as List<dynamic>?;
      } else if (data is List) {
        raw = data;
      }

      if (raw == null || raw.isEmpty) return null;

      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨] 에어코리아 요청 실패: $e');
      return null;
    }
  }

  // ── 최근접 측정소 선택 ────────────────────────────────────────

  Map<String, dynamic> _findNearest({
    required List<Map<String, dynamic>> stations,
    required double userLat,
    required double userLon,
    String? districtHint,
  }) {
    // 1순위: dmX/dmY 좌표 있으면 하버사인 최단거리
    final withCoords = stations.where((s) {
      final x = s['dmX']?.toString().trim() ?? '';
      final y = s['dmY']?.toString().trim() ?? '';
      return x.isNotEmpty && x != '-' && y.isNotEmpty && y != '-';
    }).toList();

    if (withCoords.isNotEmpty) {
      withCoords.sort((a, b) {
        final da = _haversineKm(
          userLat, userLon,
          double.parse(a['dmY'].toString()),
          double.parse(a['dmX'].toString()),
        );
        final db = _haversineKm(
          userLat, userLon,
          double.parse(b['dmY'].toString()),
          double.parse(b['dmX'].toString()),
        );
        return da.compareTo(db);
      });
      // ignore: avoid_print
      print('[코코숨] 최근접 측정소(좌표): ${withCoords.first['stationName']} '
          '(${_haversineKm(userLat, userLon, double.parse(withCoords.first['dmY'].toString()), double.parse(withCoords.first['dmX'].toString())).toStringAsFixed(1)}km)');
      return withCoords.first;
    }

    // 2순위: 역지오코딩 구/군명으로 stationName 문자열 매칭
    if (districtHint != null && districtHint.isNotEmpty) {
      final matched = _matchByDistrict(stations, districtHint);
      if (matched != null) {
        // ignore: avoid_print
        print('[코코숨] 최근접 측정소(구 매칭): ${matched['stationName']}');
        return matched;
      }
    }

    // 3순위: 첫 번째 측정소 fallback
    // ignore: avoid_print
    print('[코코숨] 최근접 측정소(fallback): ${stations.first['stationName']}');
    return stations.first;
  }

  /// "강남구", "수원시 팔달구" 등 district 힌트로 stationName 매칭.
  Map<String, dynamic>? _matchByDistrict(
    List<Map<String, dynamic>> stations,
    String district,
  ) {
    // district에서 최소 단위 추출: "수원시 팔달구" → ["팔달구", "수원시"]
    final tokens = district
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll(RegExp(r'[시구군]$'), ''))
        .where((t) => t.length >= 2)
        .toList();

    // 긴 토큰부터 우선 매칭 (더 구체적일수록 우선)
    tokens.sort((a, b) => b.length.compareTo(a.length));

    for (final token in tokens) {
      for (final s in stations) {
        final name = s['stationName']?.toString() ?? '';
        if (name.contains(token) || token.contains(name.replaceAll(RegExp(r'[시구군]$'), ''))) {
          return s;
        }
      }
    }
    return null;
  }

  // ── 수학 유틸 ─────────────────────────────────────────────────

  /// 두 WGS84 좌표 간 거리 (km, 하버사인 공식).
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

// ── 내부 데이터 클래스 ──────────────────────────────────────────

class _LocationInfo {
  final String sidoName;
  final String? districtName;

  const _LocationInfo({required this.sidoName, this.districtName});
}
