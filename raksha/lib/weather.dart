import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

// Constants
class WeatherConstants {
  static const String apiKey = '7e45214d8f80c2a64a9e7fa026fca61c';
  static const String baseUrl = 'api.openweathermap.org';
  static const String weatherEndpoint = '/data/2.5/weather';
}

// Weather data model
class WeatherData {
  final String temperature;
  final String description;
  final String cityName;
  final String location;
  final Position? position;
  final String weatherMain;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.cityName,
    required this.location,
    required this.weatherMain,
    this.position,
  });
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;

  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWeather();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeWeather() async {
    if (await _checkLocationPermission()) {
      if (mounted) {
        await _fetchWeatherData();
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _setError('Please enable location services in your device settings.');
          return false;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permission is required for this app.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Please enable location permissions in app settings.');
        await Geolocator.openAppSettings();
        return false;
      }

      return true;
    } catch (e) {
      _setError('Error checking location permissions: ${e.toString()}');
      return false;
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_isLoading) {
      setState(() => _errorMessage = null);
    }

    try {
      final position = await _getCurrentPosition();
      if (!mounted) return;

      final location = await _getLocationFromPosition(position);
      final weatherResponse = await _fetchWeatherFromApi(position);

      if (!mounted) return;

      setState(() {
        _weatherData = WeatherData(
          temperature: '${weatherResponse['main']['temp'].round()}°C',
          description: weatherResponse['weather'][0]['description'],
          weatherMain: weatherResponse['weather'][0]['main'],
          cityName: weatherResponse['name'],
          location: location,
          position: position,
        );
        _isLoading = false;
        _errorMessage = null;
      });

      _controller.reset();
      _controller.forward();
    } catch (e) {
      if (!mounted) return;
      _setError(_getErrorMessage(e));
    }
  }

  Future<Position> _getCurrentPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.reduced,
      timeLimit: const Duration(seconds: 20),
    );
    return position;
  }

  Future<String> _getLocationFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      return placemarks.isNotEmpty ? _formatAddress(placemarks[0]) : '';
    } catch (e) {
      print('Geocoding error: $e');
      return '';
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherFromApi(Position position) async {
    final url = Uri.https(
      WeatherConstants.baseUrl,
      WeatherConstants.weatherEndpoint,
      {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'appid': WeatherConstants.apiKey,
        'units': 'metric',
      },
    );

    final response = await _retryHttpGet(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw const HttpException('Invalid API key');
    } else {
      throw HttpException(
        'Failed to fetch weather data (${response.statusCode})',
      );
    }
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<http.Response> _retryHttpGet(Uri url, {int maxRetries = 3}) async {
    int retryCount = 0;
    const timeout = Duration(seconds: 15);

    while (retryCount < maxRetries) {
      try {
        return await http.get(url).timeout(timeout);
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          throw TimeoutException(
            'Failed to connect after $maxRetries attempts. Please check your internet connection.',
          );
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    throw TimeoutException('Failed to connect to weather service');
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timeout. Please check your internet connection and try again.';
    } else if (error is HttpException) {
      return error.message;
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }
    return 'Error: ${error.toString()}';
  }

  String _formatAddress(Placemark place) {
    return [
      place.locality,
      place.administrativeArea,
      place.country,
    ].where((e) => e?.isNotEmpty ?? false).join(', ');
  }

  IconData _getWeatherIcon(String? mainCondition) {
    if (mainCondition == null) return Icons.wb_sunny;

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'clear':
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String? mainCondition, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (mainCondition == null) {
      return Theme.of(context).colorScheme.primary;
    }

    switch (mainCondition.toLowerCase()) {
      case 'clear':
        return isDark ? Colors.amber[700]! : Colors.amber;
      case 'clouds':
        return isDark ? Colors.blueGrey[300]! : Colors.blueGrey;
      case 'rain':
      case 'drizzle':
        return isDark ? Colors.indigo[300]! : Colors.indigo;
      case 'thunderstorm':
        return isDark ? Colors.deepPurple[300]! : Colors.deepPurple;
      case 'snow':
        return isDark ? Colors.lightBlue[200]! : Colors.lightBlue;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildWeatherAnimation(String weatherMain, String description) {
    return Builder(
      builder: (context) {
        try {
          // Try to load Lottie animation first
          return Lottie.asset(
            'assets/${description.toLowerCase().replaceAll(' ', '_')}.json',
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if Lottie fails
              return Icon(
                _getWeatherIcon(weatherMain),
                size: 120,
                color: _getWeatherColor(weatherMain, context),
              );
            },
          );
        } catch (e) {
          // Fallback to icon if any error occurs
          return Icon(
            _getWeatherIcon(weatherMain),
            size: 120,
            color: _getWeatherColor(weatherMain, context),
          );
        }
      },
    );
  }

  ThemeData _getWeatherTheme(BuildContext context, String? weatherMain) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (weatherMain == null) {
      return Theme.of(context);
    }

    // Get base colors
    final primaryColor = _getWeatherColor(weatherMain, context);

    // Create a custom theme based on weather condition
    return Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: primaryColor,
            secondary: primaryColor.withOpacity(0.8),
            tertiary: primaryColor.withOpacity(0.6),
          ),
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
            foregroundColor: primaryColor,
          ),
      floatingActionButtonTheme:
          Theme.of(context).floatingActionButtonTheme.copyWith(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? Colors.black87 : Colors.white,
              ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: isDark ? Colors.black87 : Colors.white,
          backgroundColor: primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply weather-based theme if we have weather data
    final theme = _weatherData != null
        ? _getWeatherTheme(context, _weatherData!.weatherMain)
        : Theme.of(context);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Live Weather',
            style: TextStyle(fontFamily: 'poppy'),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                // This is just a placeholder for theme toggle
                // You would need to implement theme switching in your app
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Theme toggle clicked')),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            setState(() => _isLoading = true);
            await _fetchWeatherData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildContent(theme),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() => _isLoading = true);
            _fetchWeatherData();
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Geolocator.openLocationSettings(),
                  child: const Text('Open Location Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_weatherData == null) {
      return Center(
        child: Text(
          'No weather data available',
          style: theme.textTheme.titleLarge,
        ),
      );
    }

    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Column(
                    children: [
                      Text(
                        _weatherData!.cityName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (_weatherData!.location.isNotEmpty &&
                          _weatherData!.location != _weatherData!.cityName) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Current location: ${_weatherData!.location}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      AnimatedScale(
                        scale: _isLoading ? 0.8 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _weatherData!.temperature,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _weatherData!.description,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (_weatherData!.position != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Coordinates: ${_weatherData!.position!.latitude.toStringAsFixed(2)}, '
                          '${_weatherData!.position!.longitude.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildWeatherAnimation(
                _weatherData!.weatherMain,
                _weatherData!.description,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this to your main.dart file to implement theme switching
class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  ThemeMode _themeMode = ThemeMode.system;

  // ignore: unused_element
  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      themeMode: _themeMode,
      home: const WeatherPage(),
    );
  }
}
