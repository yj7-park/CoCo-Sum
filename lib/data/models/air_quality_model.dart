import '../../domain/entities/air_quality.dart';

class AirQualityModel extends AirQuality {
  const AirQualityModel({
    required super.stationName,
    super.cityName,
    super.pm25,
    super.pm10,
    super.o3,
    super.no2,
    super.co,
    super.so2,
    required super.measuredAt,
    super.isMockData = false,
    super.userLocationName,
    super.stationLocationShort,
    super.precomputedGrade,
  });

  /// 에어코리아 AJAX 응답 JSON에서 생성.
  ///
  /// 예상 필드명:
  /// stationName, sidoName, pm25Value, pm10Value,
  /// o3Value, no2Value, coValue, so2Value, dataTime
  factory AirQualityModel.fromAirKoreaJson(Map<String, dynamic> json) {
    return AirQualityModel(
      stationName: json['stationName'] as String? ?? '알 수 없음',
      cityName: json['sidoName'] as String?,
      pm25: _parseDouble(json['pm25Value']),
      pm10: _parseDouble(json['pm10Value']),
      o3: _parseDouble(json['o3Value']),
      no2: _parseDouble(json['no2Value']),
      co: _parseDouble(json['coValue']),
      so2: _parseDouble(json['so2Value']),
      measuredAt:
          _parseDateTime(json['dataTime'] as String?) ?? DateTime.now(),
    );
  }

  /// 공식 API (data.go.kr) 응답 형식에서 생성.
  ///
  /// API 키 발급 후 AirKoreaApiDataSource 구현 시 사용.
  factory AirQualityModel.fromOfficialApiJson(Map<String, dynamic> json) {
    return AirQualityModel(
      stationName: json['stationName'] as String? ?? '알 수 없음',
      cityName: json['sidoName'] as String?,
      pm25: _parseDouble(json['pm25Value']),
      pm10: _parseDouble(json['pm10Value']),
      o3: _parseDouble(json['o3Value']),
      no2: _parseDouble(json['no2Value']),
      co: _parseDouble(json['coValue']),
      so2: _parseDouble(json['so2Value']),
      measuredAt:
          _parseDateTime(json['dataTime'] as String?) ?? DateTime.now(),
    );
  }

  /// 미세미세(misemise.co.kr) S3 JSON에서 생성.
  ///
  /// 필드: stationName, address, latitude, longitude, dataTime,
  ///       pm25Value, pm10Value, no2Value, o3Value, coValue, so2Value,
  ///       overallGrade_whoStandard_fourLevel (1=좋음 ~ 4=매우나쁨)
  factory AirQualityModel.fromMisemiseJson(
    Map<String, dynamic> json, {
    String? userLocationName,
  }) {
    final address = json['address'] as String? ?? '';
    // "경기도 수원시 팔달구 인계로 178..." → "경기 수원시 팔달구"
    final stationShort = _shortAddress(address);
    final cityName =
        address.isNotEmpty ? address.split(' ').first : null;

    // 미세미세가 WHO 기준으로 미리 계산한 종합 등급 (1~4)
    final rawGrade =
        json['overallGrade_whoStandard_fourLevel'] as int?;
    final precomputed = _mapIntGrade(rawGrade);

    return AirQualityModel(
      stationName: json['stationName'] as String? ?? '알 수 없음',
      cityName: cityName,
      pm25: _parseDouble(json['pm25Value']),
      pm10: _parseDouble(json['pm10Value']),
      o3: _parseDouble(json['o3Value']),
      no2: _parseDouble(json['no2Value']),
      co: _parseDouble(json['coValue']),
      so2: _parseDouble(json['so2Value']),
      measuredAt:
          _parseDateTime(json['dataTime'] as String?) ?? DateTime.now(),
      userLocationName: userLocationName,
      stationLocationShort: stationShort,
      precomputedGrade: precomputed,
    );
  }

  /// "경기도 수원시 팔달구 인계로..." → "경기 수원시 팔달구"
  static String? _shortAddress(String address) {
    if (address.isEmpty) return null;
    final parts = address.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    // 첫 토큰 정규화 (시도)
    final sido = _normSido(parts[0]);
    final rest = parts.skip(1).take(2).join(' ');
    return rest.isEmpty ? sido : '$sido $rest';
  }

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

  static AirQualityGrade? _mapIntGrade(int? v) {
    switch (v) {
      case 1: return AirQualityGrade.good;
      case 2: return AirQualityGrade.moderate;
      case 3: return AirQualityGrade.bad;
      case 4: return AirQualityGrade.veryBad;
      default: return null;
    }
  }

  /// 데이터 로드 실패 시 또는 개발/테스트용 목업 데이터.
  factory AirQualityModel.mock({String stationName = '서울 종로구'}) {
    return AirQualityModel(
      stationName: stationName,
      cityName: '서울',
      pm25: 22,
      pm10: 45,
      o3: 0.024,
      no2: 0.035,
      co: 0.7,
      so2: 0.003,
      measuredAt: DateTime.now(),
      isMockData: true,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null || value == '-' || value == '') return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      // "2024-01-15 10:00" → "2024-01-15T10:00"
      return DateTime.parse(value.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }
}
