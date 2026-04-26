import '../../domain/entities/weather.dart';

class WeatherModel extends Weather {
  const WeatherModel({
    required super.temperature,
    required super.weatherCode,
    required super.windSpeed,
    required super.humidity,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'] ?? json['current'];
    return WeatherModel(
      temperature: (current['temperature'] ?? current['temperature_2m'] as num).toDouble(),
      weatherCode: (current['weathercode'] ?? current['weather_code'] as num).toInt(),
      windSpeed: (current['windspeed'] ?? current['wind_speed_10m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] ?? 0 as num).toInt(),
    );
  }
}
