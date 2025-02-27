import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Weather service class to fetch and analyze weather data
class WeatherService {
  final String apiKey = "263bb619c0914b7dbfa162348252502";

  Future<Map<String, dynamic>> fetchWeatherData(
      double latitude, double longitude) async {
    try {
      // Replace with your preferred weather API endpoint
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$latitude,$longitude&aqi=no'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return {};
    }
  }

  // Analyze weather data to determine risk level
  RiskLevel assessRiskLevel(Map<String, dynamic> weatherData) {
    if (weatherData.isEmpty) return RiskLevel.unknown;

    try {
      // Extract relevant weather conditions
      final current = weatherData['current'];
      final condition = current['condition']['text'].toString().toLowerCase();
      final windKph = current['wind_kph'] as double;
      final precipMm = current['precip_mm'] as double;
      final humidity = current['humidity'] as int;
      final tempC = current['temp_c'] as double;

      // Assess risk based on extreme weather conditions
      if (condition.contains('thunder') ||
          condition.contains('hurricane') ||
          condition.contains('cyclone') ||
          condition.contains('tornado') ||
          windKph > 70 ||
          precipMm > 50) {
        return RiskLevel.high;
      } else if (condition.contains('rain') ||
          condition.contains('snow') ||
          condition.contains('fog') ||
          condition.contains('mist') ||
          windKph > 40 ||
          precipMm > 15 ||
          humidity > 90 ||
          tempC > 40 ||
          tempC < -10) {
        return RiskLevel.moderate;
      } else {
        return RiskLevel.low;
      }
    } catch (e) {
      print('Error assessing risk level: $e');
      return RiskLevel.unknown;
    }
  }
}

// Location service to get user's current location
class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];

      String locality = place.locality ?? '';
      String administrativeArea = place.administrativeArea ?? '';
      String country = place.country ?? '';

      // Create a readable location string
      List<String> locationParts = [];
      if (locality.isNotEmpty) locationParts.add(locality);
      if (administrativeArea.isNotEmpty) locationParts.add(administrativeArea);
      if (country.isNotEmpty) locationParts.add(country);

      return locationParts.join(', ');
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }
}

// Risk level enum
enum RiskLevel { low, moderate, high, unknown }

// Extension to get risk level data
extension RiskLevelData on RiskLevel {
  Color get color {
    switch (this) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.moderate:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.unknown:
        return Colors.grey;
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.low:
        return "LOW";
      case RiskLevel.moderate:
        return "MODERATE";
      case RiskLevel.high:
        return "HIGH";
      case RiskLevel.unknown:
        return "UNKNOWN";
    }
  }

  String get advice {
    switch (this) {
      case RiskLevel.low:
        return "Stay updated on weather alerts and follow basic safety measures.";
      case RiskLevel.moderate:
        return "Be prepared for changing conditions. Keep emergency supplies ready and monitor updates.";
      case RiskLevel.high:
        return "Take immediate precautions! Stay indoors if possible and follow all emergency guidelines.";
      case RiskLevel.unknown:
        return "Weather data unavailable. Take general safety precautions as needed.";
    }
  }
}

class WeatherRiskIndicator extends StatefulWidget {
  const WeatherRiskIndicator({super.key});

  @override
  State<WeatherRiskIndicator> createState() => _WeatherRiskIndicatorState();
}

class _WeatherRiskIndicatorState extends State<WeatherRiskIndicator> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  RiskLevel _riskLevel = RiskLevel.unknown;
  bool _isLoading = true;
  Map<String, dynamic> _weatherData = {};
  String _locationName = "Detecting location...";
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();

      // Get address from coordinates
      final address = await _locationService.getAddressFromCoordinates(
          position.latitude, position.longitude);

      // Get weather data based on coordinates
      final weatherData = await _weatherService.fetchWeatherData(
          position.latitude, position.longitude);

      // Assess risk level
      final riskLevel = _weatherService.assessRiskLevel(weatherData);

      if (mounted) {
        setState(() {
          _locationName = address;
          _weatherData = weatherData;
          _riskLevel = riskLevel;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchLocationAndWeather: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _riskLevel = RiskLevel.unknown;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRiskIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Risk Level",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _locationName,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!_isLoading)
                GestureDetector(
                  onTap: _fetchLocationAndWeather,
                  child: Icon(
                    Icons.refresh,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Error: $_errorMessage",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_weatherData.isNotEmpty &&
                        _weatherData.containsKey('current'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              _getWeatherIcon(
                                  _weatherData['current']['condition']['text']),
                              size: 20,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${_weatherData['current']['condition']['text']}, ${_weatherData['current']['temp_c']}°C",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _riskLevel.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _riskLevel.label,
                            style: TextStyle(
                              color: _riskLevel.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _riskLevel.advice,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('rain') || lowerCondition.contains('drizzle')) {
      return Icons.water_drop;
    } else if (lowerCondition.contains('snow')) {
      return Icons.ac_unit;
    } else if (lowerCondition.contains('cloud')) {
      return Icons.cloud;
    } else if (lowerCondition.contains('clear') ||
        lowerCondition.contains('sunny')) {
      return Icons.wb_sunny;
    } else if (lowerCondition.contains('thunder') ||
        lowerCondition.contains('storm')) {
      return Icons.flash_on;
    } else if (lowerCondition.contains('fog') ||
        lowerCondition.contains('mist')) {
      return Icons.cloud_queue;
    } else if (lowerCondition.contains('wind')) {
      return Icons.air;
    } else {
      return Icons.thermostat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildRiskIndicator();
  }
}

// Example usage in your screen:
/*
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          WeatherRiskIndicator(),
          // Other widgets
        ],
      ),
    ),
  );
}
*/
