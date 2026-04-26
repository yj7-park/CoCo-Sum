class Weather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;

  const Weather({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
  });

  String get weatherDescription {
    // WMO Weather interpretation codes (WW)
    // https://open-meteo.com/en/docs
    switch (weatherCode) {
      case 0: return '맑음';
      case 1: case 2: case 3: return '대체로 맑음';
      case 45: case 48: return '안개';
      case 51: case 53: case 55: return '이슬비';
      case 61: case 63: case 65: return '비';
      case 71: case 73: case 75: return '눈';
      case 77: return '눈발';
      case 80: case 81: case 82: return '소나기';
      case 85: case 86: return '눈 소나기';
      case 95: return '뇌우';
      case 96: case 99: return '우박을 동반한 뇌우';
      default: return '알 수 없음';
    }
  }

  String get iconEmoji {
    switch (weatherCode) {
      case 0: return '☀️';
      case 1: case 2: case 3: return '🌤️';
      case 45: case 48: return '🌫️';
      case 51: case 53: case 55: return '🌦️';
      case 61: case 63: case 65: return '🌧️';
      case 71: case 73: case 75: return '❄️';
      case 77: return '🌨️';
      case 80: case 81: case 82: return '🌦️';
      case 85: case 86: return '🌨️';
      case 95: return '⛈️';
      case 96: case 99: return '⛈️';
      default: return '❓';
    }
  }
}
