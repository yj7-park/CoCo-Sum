import 'package:dio/dio.dart';
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
    final sidoName = _latLonToSidoName(latitude, longitude);
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

  /// 위·경도 좌표를 에어코리아 광역시도명으로 변환 (근사 경계값 사용).
  /// geocoding 패키지 없이 오프라인 동작 가능하도록 하드코딩.
  String _latLonToSidoName(double lat, double lon) {
    if (lat >= 37.42 && lat <= 37.70 && lon >= 126.73 && lon <= 127.18) {
      return '서울';
    }
    if (lat >= 37.15 && lat <= 37.74 && lon >= 126.43 && lon <= 127.32) {
      return '경기';
    }
    if (lat >= 37.26 && lat <= 37.59 && lon >= 126.31 && lon <= 126.85) {
      return '인천';
    }
    if (lat >= 34.87 && lat <= 35.40 && lon >= 128.73 && lon <= 129.32) {
      return '부산';
    }
    if (lat >= 35.65 && lat <= 36.03 && lon >= 128.40 && lon <= 128.78) {
      return '대구';
    }
    if (lat >= 35.07 && lat <= 35.28 && lon >= 126.70 && lon <= 127.00) {
      return '광주';
    }
    if (lat >= 36.20 && lat <= 36.47 && lon >= 127.22 && lon <= 127.55) {
      return '대전';
    }
    if (lat >= 35.44 && lat <= 35.60 && lon >= 129.17 && lon <= 129.46) {
      return '울산';
    }
    if (lat >= 36.44 && lat <= 36.59 && lon >= 127.21 && lon <= 127.36) {
      return '세종';
    }
    if (lat >= 33.10 && lat <= 33.61 && lon >= 126.14 && lon <= 126.97) {
      return '제주';
    }
    if (lat >= 37.50 && lat <= 38.62 && lon >= 127.05 && lon <= 129.39) {
      return '강원';
    }
    if (lat >= 36.49 && lat <= 37.18 && lon >= 127.06 && lon <= 129.02) {
      return '충북';
    }
    if (lat >= 35.90 && lat <= 36.98 && lon >= 125.90 && lon <= 127.66) {
      return '충남';
    }
    if (lat >= 35.98 && lat <= 37.18 && lon >= 127.59 && lon <= 129.59) {
      return '경북';
    }
    if (lat >= 34.58 && lat <= 35.68 && lon >= 127.60 && lon <= 129.22) {
      return '경남';
    }
    if (lat >= 35.41 && lat <= 36.00 && lon >= 126.36 && lon <= 127.89) {
      return '전북';
    }
    if (lat >= 33.90 && lat <= 35.06 && lon >= 125.89 && lon <= 127.72) {
      return '전남';
    }
    return '서울'; // fallback
  }
}
