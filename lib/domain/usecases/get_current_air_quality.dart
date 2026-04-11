import '../entities/air_quality.dart';
import '../repositories/air_quality_repository.dart';

class GetCurrentAirQuality {
  final AirQualityRepository _repository;

  const GetCurrentAirQuality(this._repository);

  Future<AirQuality> call({
    required double latitude,
    required double longitude,
  }) =>
      _repository.getAirQuality(latitude: latitude, longitude: longitude);
}
