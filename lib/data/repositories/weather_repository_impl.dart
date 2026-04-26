import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_datasource.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherDataSource dataSource;

  WeatherRepositoryImpl(this.dataSource);

  @override
  Future<Weather> getWeather(double latitude, double longitude) {
    return dataSource.getWeather(latitude: latitude, longitude: longitude);
  }
}
