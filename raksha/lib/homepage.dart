import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:raksha/do_dont.dart';
import 'package:raksha/emergency_contacts.dart';
import 'package:raksha/helpline.dart';
import 'package:raksha/location.dart';
import 'package:raksha/news_section.dart';
import 'package:raksha/risk_level_indicator.dart';
import 'package:raksha/safety_tips.dart';
import 'package:raksha/settings.dart';
import 'package:raksha/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<HomePage> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(20.5937, 78.9629);
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  int _currentIndex = 1;
  String _username = '';
  String? _profilePicturePath;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchUsername();
    _loadProfilePicture();
  }

  Future<void> _fetchUsername() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(currentUser.email).get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _username = userData['username'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error fetching username: $e');
      if (mounted) {
        setState(() {
          _username = 'User';
        });
      }
    }
  }

  Future<void> _loadProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_picture_path');

      if (mounted) {
        setState(() {
          _profilePicturePath = imagePath;
        });
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> refreshUserData() async {
    await _fetchUsername();
    await _loadProfilePicture();
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _center = LatLng(position.latitude, position.longitude);

        // Update markers with current location
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'My Location'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      // Update camera position to current location
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _center,
              zoom: 15.0,
            ),
          ),
        );
      }

      await fetchDisasterData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error getting location: $e';
          print('Location error: $e');
        });
      }
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorMessage =
          'Location services are disabled. Please enable the services');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorMessage = 'Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
          () => _errorMessage = 'Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> fetchDisasterData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Create a new http client
      final client = http.Client();

      try {
        // Make the API request
        final response = await client
            .get(
          Uri.parse(
              'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.geojson'),
        )
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
                'Connection timeout. Please check your internet connection.');
          },
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          // Parse the JSON response
          final data = jsonDecode(response.body);

          if (!data.containsKey('features')) {
            throw FormatException('Invalid data format received from server');
          }

          final features = data['features'] as List;

          // Initialize markers set with current location if available
          Set<Marker> markers = {};

          // Add current location marker if available
          if (_currentPosition != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('currentLocation'),
                position: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                infoWindow: const InfoWindow(title: 'My Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
              ),
            );
          }

          // Process earthquake features
          for (var feature in features) {
            try {
              final geometry = feature['geometry'];
              final properties = feature['properties'];

              if (geometry == null || properties == null) continue;

              final coords = geometry['coordinates'] as List;
              if (coords.length < 2) continue;

              final place =
                  properties['place'] as String? ?? 'Unknown Location';
              final magnitude = (properties['mag'] as num?)?.toDouble() ?? 0.0;
              final time = properties['time'] as int?;

              // Format the time if available
              String timeStr = 'Time not available';
              if (time != null) {
                final date = DateTime.fromMillisecondsSinceEpoch(time);
                timeStr =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              }

              // Create marker for each earthquake
              markers.add(
                Marker(
                  markerId: MarkerId(place),
                  position: LatLng(coords[1].toDouble(), coords[0].toDouble()),
                  infoWindow: InfoWindow(
                    title: 'Magnitude: $magnitude',
                    snippet: '$place\n$timeStr',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    magnitude >= 6.0
                        ? BitmapDescriptor.hueRed
                        : magnitude >= 5.0
                            ? BitmapDescriptor.hueOrange
                            : BitmapDescriptor.hueYellow,
                  ),
                ),
              );
            } catch (e) {
              print('Error processing feature: $e');
              continue;
            }
          }

          // Update state with new markers
          if (mounted) {
            setState(() {
              _markers = markers;
              _errorMessage = '';
            });

            // If map controller exists, animate to show all markers
            if (mapController != null && markers.isNotEmpty) {
              final bounds = _calculateBounds(markers);
              mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 50.0),
              );
            }
          }
        } else {
          throw HttpException('Failed to load data: ${response.statusCode}');
        }
      } catch (e) {
        rethrow;
      } finally {
        client.close();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is TimeoutException
              ? 'Connection timeout. Please check your internet connection.'
              : 'Failed to load disaster data: ${e.toString()}';
          print('Error fetching disaster data: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to calculate bounds for all markers
  LatLngBounds _calculateBounds(Set<Marker> markers) {
    if (markers.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double? minLat, maxLat, minLng, maxLng;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : min(minLat, lat);
      maxLat = maxLat == null ? lat : max(maxLat, lat);
      minLng = minLng == null ? lng : min(minLng, lng);
      maxLng = maxLng == null ? lng : max(maxLng, lng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Widget buildWeatherRiskIndicator() {
    return const WeatherRiskIndicator();
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    // Add padding to ensure positive width
    final buttonWidth = max((screenWidth - (3 * 20)) / 2, 0.0);

    return Container(
      width: buttonWidth,
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? theme.cardColor : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: theme.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'poppy',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Access",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
            fontFamily: 'poppy',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAccessButton(
              icon: Icons.warning,
              label: "Safety tips",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoListScreen()),
                );
              },
            ),
            _buildQuickAccessButton(
              icon: Icons.help,
              label: "Helpline",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelplinePage()),
                );
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAccessButton(
              icon: Icons.check_box,
              label: "Do's and Dont's",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DisasterScreen()),
                );
              },
            ),
            _buildQuickAccessButton(
              icon: Icons.cloud,
              label: "Live weather",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    if (_profilePicturePath != null) {
      final file = File(_profilePicturePath!);
      if (file.existsSync()) {
        return CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 20,
          backgroundImage: FileImage(file),
        );
      }
    }

    // Fallback to showing the first letter of username
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CircleAvatar(
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      radius: 20,
      child: Text(
        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'poppy',
        ),
      ),
    );
  }

  Widget _buildCompactMap() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 15.0,
                ),
                zoomControlsEnabled: true,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: true,
              ),
              if (_isLoading)
                Container(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              if (_errorMessage.isNotEmpty)
                Container(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  child: Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontFamily: 'poppylight',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget currentPage;
    switch (_currentIndex) {
      case 0:
        currentPage = LocationPage();
        break;
      case 2:
        currentPage = const NewsPage();
        break;
      case 1:
      default:
        currentPage = RefreshIndicator(
          onRefresh: fetchDisasterData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactMap(),
                  const SizedBox(height: 20),
                  buildWeatherRiskIndicator(),
                  const SizedBox(height: 20),
                  const EmergencyContactsSection(),
                  const SizedBox(height: 20),
                  _buildQuickAccess(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
    }

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: theme.secondaryHeaderColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? theme.cardColor : Colors.white,
                  width: 2,
                ),
              ),
              child: _buildProfileAvatar(),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _username.isNotEmpty ? _username : 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : theme.primaryColor,
                    fontFamily: 'poppy',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: 26,
              color: isDark ? Color(0xFF2196F3) : theme.primaryColor,
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                size: 26,
                color: isDark ? Color(0xFF2196F3) : theme.primaryColor,
              ),
              onPressed: () async {
                final shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );

                if (shouldRefresh == true && mounted) {
                  await refreshUserData();
                }
              },
            ),
          ),
        ],
      ),
      body: currentPage,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryHeaderColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor:
                    isDark ? Color(0xFF2196F3) : theme.primaryColor,
                unselectedItemColor: isDark ? Colors.grey : Colors.grey[700],
                selectedFontSize: 14,
                unselectedFontSize: 12,
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_on_outlined),
                    activeIcon: Icon(Icons.location_on),
                    label: "Location",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.article_outlined),
                    activeIcon: Icon(Icons.article),
                    label: "News",
                  ),
                ],
                selectedLabelStyle: TextStyle(fontFamily: 'poppy'),
                unselectedLabelStyle: TextStyle(fontFamily: 'poppylight'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
