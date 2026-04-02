class WeatherModel {
  final double lat;
  final double lon;
  final String cityName;
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final double pressure;
  final double humidity;
  final String weatherMain;
  final String weatherDescription;
  final String weatherIcon;
  final double windSpeed;
  final int visibility;
  final int clouds;

  const WeatherModel({
    required this.lat,
    required this.lon,
    required this.cityName,
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.humidity,
    required this.weatherMain,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.windSpeed,
    required this.visibility,
    required this.clouds,
  });

  factory WeatherModel.fromMap(Map<String, dynamic> map) {
    // Extract the main weather object (the first item in the list)
    final weatherData = (map['weather'] as List).first;
    final mainData = map['main'] as Map<String, dynamic>;

    return WeatherModel(
      lat: (map['coord']['lat'] as num).toDouble(),
      lon: (map['coord']['lon'] as num).toDouble(),
      cityName: map['name'] as String,
      temp: (mainData['temp'] as num).toDouble(),
      feelsLike: (mainData['feels_like'] as num).toDouble(),
      tempMin: (mainData['temp_min'] as num).toDouble(),
      tempMax: (mainData['temp_max'] as num).toDouble(),
      pressure: (mainData['pressure'] as num).toDouble(),
      humidity: (mainData['humidity'] as num).toDouble(),
      weatherMain: weatherData['main'] as String,
      weatherDescription: weatherData['description'] as String,
      weatherIcon: weatherData['icon'] as String,
      windSpeed: (map['wind']['speed'] as num).toDouble(),
      visibility: (map['visibility'] as num?)?.toInt() ?? 0,
      // Use the null-aware operator to safely get 'all'
      clouds: (map['clouds']?['all'] as num?)?.toInt() ?? 0,
    );
  }
  /// 0 = Sunny, 1 = Rainy, 2 = Cloudy
  int get weatherPageIndex {
    final c = weatherMain.toLowerCase();
    if (c.contains('cloud')) return 2;
    if (c.contains('rain') || c.contains('drizzle') || c.contains('thunder')) {
      return 1;
    }
    return 0;
  }

  String get displayDescription {
    return weatherDescription
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}