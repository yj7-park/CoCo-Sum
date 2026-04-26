import '../models/weather_model.dart';

abstract class WeatherDataSource {
  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  });
}
