import '../entities/air_quality.dart';

abstract class AirQualityRepository {
  Future<AirQuality> getAirQuality({
    required double latitude,
    required double longitude,
  });
}
