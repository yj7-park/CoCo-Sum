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
  });

  AirQualityGrade get pm25Grade => _gradeFromPm25(pm25);
  AirQualityGrade get pm10Grade => _gradeFromPm10(pm10);

  AirQualityGrade get overallGrade {
    return [pm25Grade, pm10Grade].reduce((a, b) => a.index > b.index ? a : b);
  }

  static AirQualityGrade _gradeFromPm25(double? v) {
    if (v == null) return AirQualityGrade.moderate;
    if (v <= 15) return AirQualityGrade.good;
    if (v <= 35) return AirQualityGrade.moderate;
    if (v <= 75) return AirQualityGrade.bad;
    return AirQualityGrade.veryBad;
  }

  static AirQualityGrade _gradeFromPm10(double? v) {
    if (v == null) return AirQualityGrade.moderate;
    if (v <= 30) return AirQualityGrade.good;
    if (v <= 80) return AirQualityGrade.moderate;
    if (v <= 150) return AirQualityGrade.bad;
    return AirQualityGrade.veryBad;
  }
}
