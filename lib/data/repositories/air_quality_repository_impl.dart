import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_quality_repository.dart';
import '../datasources/air_quality_datasource.dart';

class AirQualityRepositoryImpl implements AirQualityRepository {
  final AirQualityDataSource _dataSource;

  const AirQualityRepositoryImpl(this._dataSource);

  @override
  Future<AirQuality> getAirQuality({
    required double latitude,
    required double longitude,
  }) =>
      _dataSource.getAirQuality(latitude: latitude, longitude: longitude);
}
