import '../models/air_quality_model.dart';

/// 공기질 데이터 소스 추상 인터페이스.
///
/// ## 공식 API로 교체하는 방법
/// 1. `airkorea_api_datasource.dart` 파일 생성
/// 2. 이 인터페이스를 구현 (implements AirQualityDataSource)
/// 3. `lib/presentation/providers/providers.dart`에서
///    `AirKoreaWebDataSource` → `AirKoreaApiDataSource`로 교체
///
/// 현재 구현체: AirKoreaWebDataSource (웹 크롤링, mock fallback 포함)
abstract class AirQualityDataSource {
  Future<AirQualityModel> getAirQuality({
    required double latitude,
    required double longitude,
  });
}
