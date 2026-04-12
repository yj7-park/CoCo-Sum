enum AirQualityGrade { good, moderate, bad, veryBad }

extension AirQualityGradeExt on AirQualityGrade {
  String get label {
    switch (this) {
      case AirQualityGrade.good:
        return '좋음';
      case AirQualityGrade.moderate:
        return '보통';
      case AirQualityGrade.bad:
        return '나쁨';
      case AirQualityGrade.veryBad:
        return '매우나쁨';
    }
  }

  String get actionMessage {
    switch (this) {
      case AirQualityGrade.good:
        return '마음껏 뛰어놀아요!';
      case AirQualityGrade.moderate:
        return '나가도 괜찮아요';
      case AirQualityGrade.bad:
        return '마스크 꼭 써요!';
      case AirQualityGrade.veryBad:
        return '오늘은 집에 있어요';
    }
  }

  String get subMessage {
    switch (this) {
      case AirQualityGrade.good:
        return '공기가 맑아요! 신나게 놀아도 돼요';
      case AirQualityGrade.moderate:
        return '공기가 괜찮아요. 편하게 나가세요';
      case AirQualityGrade.bad:
        return '미세먼지가 많아요. 마스크를 꼭 착용하세요';
      case AirQualityGrade.veryBad:
        return '미세먼지가 매우 심해요. 외출을 자제하세요';
    }
  }

  String get emoji {
    switch (this) {
      case AirQualityGrade.good:
        return '😄';
      case AirQualityGrade.moderate:
        return '🙂';
      case AirQualityGrade.bad:
        return '😷';
      case AirQualityGrade.veryBad:
        return '😰';
    }
  }
}

class AirQuality {
  final String stationName;
  final String? cityName;
  final double? pm25;
  final double? pm10;
  final double? o3;
  final double? no2;
  final double? co;
  final double? so2;
  final DateTime measuredAt;
  final bool isMockData;

  /// GPS 기반 역지오코딩으로 얻은 사용자 실제 위치 (예: "경기 수원시").
  final String? userLocationName;

  /// 데이터를 제공한 측정소의 짧은 주소 (예: "경기 수원시 팔달구").
  final String? stationLocationShort;

  /// 미세미세 등 외부 소스에서 미리 계산된 종합 등급(WHO 기준).
  /// null이면 pm25Grade / pm10Grade 중 더 나쁜 값으로 계산.
  final AirQualityGrade? _precomputedGrade;

  const AirQuality({
    required this.stationName,
    this.cityName,
    this.pm25,
    this.pm10,
    this.o3,
    this.no2,
    this.co,
    this.so2,
    required this.measuredAt,
    this.isMockData = false,
    this.userLocationName,
    this.stationLocationShort,
    AirQualityGrade? precomputedGrade,
  }) : _precomputedGrade = precomputedGrade;

  /// WHO 2021 AQG 기반 4단계 PM2.5 등급
  /// 좋음 ≤15 / 보통 ≤25 / 나쁨 ≤50 / 매우나쁨 51+
  AirQualityGrade get pm25Grade => _gradeFromPm25(pm25);

  /// WHO 2021 AQG 기반 4단계 PM10 등급
  /// 좋음 ≤30 / 보통 ≤50 / 나쁨 ≤100 / 매우나쁨 101+
  AirQualityGrade get pm10Grade => _gradeFromPm10(pm10);

  AirQualityGrade get overallGrade {
    if (_precomputedGrade != null) return _precomputedGrade;
    return [pm25Grade, pm10Grade].reduce((a, b) => a.index > b.index ? a : b);
  }

  // ── WHO 2021 임계값 ──────────────────────────────────────────
  static AirQualityGrade _gradeFromPm25(double? v) {
    if (v == null) return AirQualityGrade.moderate;
    if (v <= 15) return AirQualityGrade.good;
    if (v <= 25) return AirQualityGrade.moderate;
    if (v <= 50) return AirQualityGrade.bad;
    return AirQualityGrade.veryBad;
  }

  static AirQualityGrade _gradeFromPm10(double? v) {
    if (v == null) return AirQualityGrade.moderate;
    if (v <= 30) return AirQualityGrade.good;
    if (v <= 50) return AirQualityGrade.moderate;
    if (v <= 100) return AirQualityGrade.bad;
    return AirQualityGrade.veryBad;
  }
}
