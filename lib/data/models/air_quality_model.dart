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
