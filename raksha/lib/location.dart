// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPage extends StatefulWidget {
  // ignore: use_super_parameters
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isSendingSOS = false;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Show dialog to open app settings
        if (mounted) {
          _showPermissionSettingsDialog();
        }
        throw Exception('Location permissions permanently denied');
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showEnableLocationServiceDialog();
        }
        throw Exception('Location services disabled');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
            'Location permission is required for this app to function properly. '
            'Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showEnableLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content:
            const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOSWhatsApp() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send SOS: Location unavailable')),
      );
      return;
    }

    // Check if user is logged in
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use the SOS feature')),
      );
      return;
    }

    // Confirm before sending
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm SOS'),
        content: const Text(
            'Are you sure you want to send an SOS message to all your emergency contacts via WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSendingSOS = true;
    });

    try {
      // Get emergency contacts from Firestore
      final userDoc = await _firestore
          .collection('Users')
          .doc(_auth.currentUser?.email ?? '')
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final contacts =
          List<Map<String, dynamic>>.from(data['emergency_contacts'] ?? []);

      if (contacts.isEmpty) {
        throw Exception('No emergency contacts found');
      }

      // Create location message
      final String locationUrl =
          'https://maps.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final String message =
          'EMERGENCY SOS! I need help. My current location is: $locationUrl';

      // Send via WhatsApp
      bool atLeastOneSent = false;
      for (final contact in contacts) {
        final String phone =
            contact['phoneNumber'].replaceAll(RegExp(r'[^0-9]'), '');
        final Uri whatsappUrl = Uri.parse(
            'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          atLeastOneSent = true;

          // Add a small delay between launches to prevent UI freezing
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (atLeastOneSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp opened with SOS message')),
        );
      } else {
        throw Exception('Could not open WhatsApp for any contact');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending SOS: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSOS = false;
        });
      }
    }
  }

  Widget _buildLocationCard(String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _initializeLocation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Location Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Your Current Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isLoadingLocation)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_locationError.isNotEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                color: theme.colorScheme.error, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Location Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _locationError,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _initializeLocation,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_currentPosition != null) ...[
                      _buildLocationCard('Latitude',
                          _currentPosition!.latitude.toStringAsFixed(6)),
                      const SizedBox(height: 10),
                      _buildLocationCard('Longitude',
                          _currentPosition!.longitude.toStringAsFixed(6)),
                      const SizedBox(height: 10),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _initializeLocation,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh Location'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // SOS Button Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 32),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.emergency, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Emergency SOS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'In case of emergency, press the SOS button below to send your current location to all your emergency contacts via WhatsApp.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: ElevatedButton.icon(
                        onPressed: _isSendingSOS ||
                                _isLoadingLocation ||
                                _currentPosition == null ||
                                _auth.currentUser == null
                            ? null
                            : _sendSOSWhatsApp,
                        icon: _isSendingSOS
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : const Icon(FontAwesomeIcons.whatsapp, size: 30),
                        label: Text(
                          _isSendingSOS
                              ? 'SENDING SOS...'
                              : 'SEND SOS VIA WHATSAPP',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.green.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    if (_auth.currentUser == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Please sign in to use the SOS feature',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    // Add a link to manage emergency contacts
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: TextButton.icon(
                          icon: const Icon(Icons.people),
                          label: const Text('Manage Emergency Contacts'),
                          onPressed: () {
                            // Navigate to the homepage or wherever the emergency contacts section is
                            Navigator.pop(context); // Return to homepage
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
