import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

class GetCurrentWeather {
  final WeatherRepository repository;

  GetCurrentWeather(this.repository);

  Future<Weather> execute(double latitude, double longitude) {
    return repository.getWeather(latitude, longitude);
  }
}
