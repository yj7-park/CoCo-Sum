/// WHO 기준 8단계 공기질 등급
enum AirQualityGrade { best, good, fine, moderate, bad, quiteBad, veryBad, worst }

extension AirQualityGradeExt on AirQualityGrade {
  String get label {
    switch (this) {
      case AirQualityGrade.best:     return '최고';
      case AirQualityGrade.good:     return '좋음';
      case AirQualityGrade.fine:     return '양호';
      case AirQualityGrade.moderate: return '보통';
      case AirQualityGrade.bad:      return '나쁨';
      case AirQualityGrade.quiteBad: return '상당히 나쁨';
      case AirQualityGrade.veryBad:  return '매우 나쁨';
      case AirQualityGrade.worst:    return '최악';
    }
  }

  String get actionMessage {
    switch (this) {
      case AirQualityGrade.best:     return '마음껏 뛰어놀아요!';
      case AirQualityGrade.good:     return '신나게 뛰어놀아요!';
      case AirQualityGrade.fine:     return '나가도 좋아요';
      case AirQualityGrade.moderate: return '나가도 괜찮아요';
      case AirQualityGrade.bad:      return '민감한 분은 주의하세요';
      case AirQualityGrade.quiteBad: return '마스크 꼭 써요!';
      case AirQualityGrade.veryBad:  return '외출을 자제해요';
      case AirQualityGrade.worst:    return '오늘은 집에 있어요';
    }
  }

  String get subMessage {
    switch (this) {
      case AirQualityGrade.best:     return '공기가 아주 맑아요! 마음껏 즐기세요';
      case AirQualityGrade.good:     return '공기가 맑아요! 신나게 놀아도 돼요';
      case AirQualityGrade.fine:     return '공기가 괜찮아요. 편하게 나가세요';
      case AirQualityGrade.moderate: return '공기가 보통이에요. 편하게 활동하세요';
      case AirQualityGrade.bad:      return '민감한 분들은 마스크를 권장해요';
      case AirQualityGrade.quiteBad: return '미세먼지가 많아요. 마스크를 꼭 착용하세요';
      case AirQualityGrade.veryBad:  return '미세먼지가 심해요. 외출을 자제하세요';
      case AirQualityGrade.worst:    return '미세먼지가 매우 심해요. 외출하지 마세요';
    }
  }

  String get emoji {
    switch (this) {
      case AirQualityGrade.best:     return '😄';
      case AirQualityGrade.good:     return '🙂';
      case AirQualityGrade.fine:     return '😊';
      case AirQualityGrade.moderate: return '😐';
      case AirQualityGrade.bad:      return '😷';
      case AirQualityGrade.quiteBad: return '😷';
      case AirQualityGrade.veryBad:  return '😰';
      case AirQualityGrade.worst:    return '🤢';
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
  final String? userLocationName;
  final String? stationLocationShort;
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

  /// WHO 8단계 PM2.5 등급
  /// 최고 ≤8 / 좋음 ≤15 / 양호 ≤20 / 보통 ≤25
  /// 나쁨 ≤37 / 상당히나쁨 ≤50 / 매우나쁨 ≤75 / 최악 76+
  AirQualityGrade get pm25Grade => _gradeFromPm25(pm25);

  /// WHO 8단계 PM10 등급
  /// 최고 ≤15 / 좋음 ≤30 / 양호 ≤40 / 보통 ≤50
  /// 나쁨 ≤75 / 상당히나쁨 ≤100 / 매우나쁨 ≤150 / 최악 151+
  AirQualityGrade get pm10Grade => _gradeFromPm10(pm10);

  AirQualityGrade get overallGrade {
    if (_precomputedGrade != null) return _precomputedGrade;
    return [pm25Grade, pm10Grade].reduce((a, b) => a.index > b.index ? a : b);
  }

  static AirQualityGrade _gradeFromPm25(double? v) {
    if (v == null) return AirQualityGrade.moderate;
    if (v <=  8) return AirQualityGrade.best;
    if (v <= 15) return AirQualityGrade.good;
    if (v <= 20) return AirQualityGrade.fine;
    if (v <= 25) return AirQualityGrade.moderate;
    if (v <= 37) return AirQualityGrade.bad;
    if (v <= 50) return AirQualityGrade.quiteBad;
    if (v <= 75) return AirQualityGrade.veryBad;
    return AirQualityGrade.worst;
  }

  static AirQualityGrade _gradeFromPm10(double? v) {
    if (v == null) return AirQualityGrade.moderate;
    if (v <=  15) return AirQualityGrade.best;
    if (v <=  30) return AirQualityGrade.good;
    if (v <=  40) return AirQualityGrade.fine;
    if (v <=  50) return AirQualityGrade.moderate;
    if (v <=  75) return AirQualityGrade.bad;
    if (v <= 100) return AirQualityGrade.quiteBad;
    if (v <= 150) return AirQualityGrade.veryBad;
    return AirQualityGrade.worst;
  }
}
