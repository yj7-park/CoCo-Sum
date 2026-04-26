import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import 'weather_datasource.dart';

class OpenMeteoDataSource implements WeatherDataSource {
  final Dio _dio;

  OpenMeteoDataSource(this._dio);

  @override
  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
          'daily': 'temperature_2m_max,temperature_2m_min',
          'timezone': 'auto',
          'forecast_days': 1,
        },
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      throw Exception('Weather request failed: $e');
    }
  }
}
