import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import '../models/air_quality_model.dart';
import 'air_quality_datasource.dart';

/// 에어코리아 웹사이트 내부 AJAX 엔드포인트를 통해 데이터를 가져오는 구현체.
///
/// 비공식 엔드포인트를 사용하므로 응답 형식이 변경될 수 있습니다.
/// 실패 시 자동으로 mock 데이터로 fallback합니다.
///
/// ## 공식 API 교체 시
/// 이 파일을 복사해서 `airkorea_api_datasource.dart`로 이름을 바꾼 후
/// `_fetchFromAjax`를 아래 공식 API 호출로 교체하세요:
///
/// ```
/// GET https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty
///   ?serviceKey={API_KEY}
///   &sidoName={시도명}
///   &searchCondition=HOUR
///   &numOfRows=100
///   &pageNo=1
///   &returnType=json
/// ```
class AirKoreaWebDataSource implements AirQualityDataSource {
  final Dio _dio;

  static const _baseUrl = 'https://www.airkorea.or.kr';
  static const _endpoint = '/web/ajax/getCtprvnRltmMesureDnsty';

  AirKoreaWebDataSource(this._dio);

  @override
  Future<AirQualityModel> getAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final sidoName = await _resolveSidoName(latitude, longitude);
    return await _fetchFromAjax(sidoName) ??
        AirQualityModel.mock(stationName: '$sidoName 측정소');
  }

  Future<AirQualityModel?> _fetchFromAjax(String sidoName) async {
    try {
      final response = await _dio.get(
        '$_baseUrl$_endpoint',
        queryParameters: {
          'sidoName': sidoName,
          'searchCondition': 'HOUR',
          'numOfRows': '30',
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

      final data = response.data;
      List<dynamic>? list;

      if (data is Map) {
        list = (data['list'] ?? data['data'] ?? data['items']) as List<dynamic>?;
      } else if (data is List) {
        list = data;
      }

      if (list != null && list.isNotEmpty) {
        final first = list.first;
        if (first is Map) {
          return AirQualityModel.fromAirKoreaJson(
            Map<String, dynamic>.from(first),
          );
        }
      }
      return null;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[코코숨] 에어코리아 요청 실패 (${e.type.name}): ${e.message}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨] 데이터 파싱 실패: $e');
      return null;
    }
  }

  /// geocoding 패키지로 역지오코딩 후 에어코리아 시도명 포맷으로 정규화.
  ///
  /// geocoding이 반환하는 [Placemark.administrativeArea]는
  /// "서울특별시", "경기도", "제주특별자치도" 등 공식 행정구역명이므로
  /// 에어코리아 API가 기대하는 짧은 형태("서울", "경기", "제주")로 변환.
  ///
  /// 역지오코딩 자체가 실패하면 예외를 던지지 않고 '서울'을 반환.
  Future<String> _resolveSidoName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final area = placemarks.first.administrativeArea ?? '';
        return _normalizeAdminArea(area);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[코코숨] 역지오코딩 실패: $e → 서울 fallback');
    }
    return '서울';
  }

  /// "경기도" → "경기", "서울특별시" → "서울" 등으로 변환.
  /// 에어코리아 API sidoName 파라미터가 도/특별시/광역시 접미사 없는 형태를 요구.
  static String _normalizeAdminArea(String raw) {
    // 정확히 매핑되는 케이스 먼저 처리
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

    // 접미사 제거 fallback: "○○도" → "○○", "○○시" → "○○"
    for (final suffix in ['특별자치도', '특별자치시', '광역시', '특별시', '도', '시']) {
      if (raw.endsWith(suffix)) {
        return raw.substring(0, raw.length - suffix.length);
      }
    }

    return raw.isEmpty ? '서울' : raw;
  }
}
