import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Constants to avoid magic strings
class AppConstants {
  static const String incidentsCollection = 'incidents';
  static const String activeStatus = 'active';
  static const List<String> incidentTypes = [
    'Fire',
    'Flood',
    'Earthquake',
    'Hurricane',
    'Landslide',
    'Medical Emergency',
    'Building Collapse',
    'Other'
  ];
}

// Incident model class
class Incident {
  final String name;
  final String incidentType;
  final String description;
  final int peopleAffected;
  final String helpNeeded;
  final String contactNumber;
  final double latitude;
  final double longitude;
  final String address;
  final String? id;
  final String? distance;
  final Timestamp? timestamp;
  final String status;

  Incident({
    required this.name,
    required this.incidentType,
    required this.description,
    required this.peopleAffected,
    required this.helpNeeded,
    required this.contactNumber,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.id,
    this.distance,
    this.timestamp,
    this.status = 'active',
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'incidentType': incidentType,
      'description': description,
      'peopleAffected': peopleAffected,
      'helpNeeded': helpNeeded,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  // Create from Firestore document
  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      name: data['name'] ?? '',
      incidentType: data['incidentType'] ?? '',
      description: data['description'] ?? '',
      peopleAffected: data['peopleAffected'] ?? 0,
      helpNeeded: data['helpNeeded'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      address: data['address'] ?? '',
      timestamp: data['timestamp'],
      status: data['status'] ?? '',
    );
  }
}

// Location service
class LocationService {
  static Future<Position> getCurrentPosition() async {
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  static Future<String> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];
      return '${place.street}, ${place.subLocality}, '
          '${place.locality}, ${place.postalCode}, ${place.country}';
    } catch (e) {
      throw Exception('Unable to get address from location: $e');
    }
  }
}

// Incident service
class IncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addIncident(Incident incident) async {
    await _firestore
        .collection(AppConstants.incidentsCollection)
        .add(incident.toMap());
  }

  Future<List<Incident>> getNearbyIncidents(Position position) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.incidentsCollection)
          .where('status', isEqualTo: AppConstants.activeStatus)
          .orderBy('timestamp', descending: true)
          .get();

      List<Incident> incidents = [];

      for (var doc in snapshot.docs) {
        Incident incident = Incident.fromFirestore(doc);

        // Calculate distance from current position
        double distanceInMeters = Geolocator.distanceBetween(position.latitude,
            position.longitude, incident.latitude, incident.longitude);

        // Create a new instance with distance
        incidents.add(Incident(
          id: incident.id,
          name: incident.name,
          incidentType: incident.incidentType,
          description: incident.description,
          peopleAffected: incident.peopleAffected,
          helpNeeded: incident.helpNeeded,
          contactNumber: incident.contactNumber,
          latitude: incident.latitude,
          longitude: incident.longitude,
          address: incident.address,
          distance: (distanceInMeters / 1000).toStringAsFixed(1),
          timestamp: incident.timestamp,
          status: incident.status,
        ));
      }

      // Sort by distance
      incidents.sort((a, b) => double.parse(a.distance ?? '0')
          .compareTo(double.parse(b.distance ?? '0')));

      return incidents;
    } catch (e) {
      print('Error loading incidents: $e');
      return [];
    }
  }
}

class DisasterReportApp extends StatelessWidget {
  const DisasterReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Report App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const IncidentReportPage(),
    );
  }
}

class IncidentReportPage extends StatefulWidget {
  const IncidentReportPage({super.key});

  @override
  _IncidentReportPageState createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _incidentService = IncidentService();

  // Form data
  String _name = '';
  String _incidentType = AppConstants.incidentTypes[0];
  String _description = '';
  int _peopleAffected = 0;
  String _helpNeeded = '';
  String _contactNumber = '';

  // Location data
  Position? _currentPosition;
  String _currentAddress = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Position position = await LocationService.getCurrentPosition();

      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      String address = await LocationService.getAddressFromLatLng(position);
      setState(() {
        _currentAddress = address;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Submit incident report
  Future<void> _submitReport() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    _formKey.currentState!.save();

    if (_currentPosition == null) {
      setState(() {
        _errorMessage = 'Location data is required. Please try again.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Create incident data
      final incident = Incident(
        name: _name,
        incidentType: _incidentType,
        description: _description,
        peopleAffected: _peopleAffected,
        helpNeeded: _helpNeeded,
        contactNumber: _contactNumber,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress,
      );

      // Save to Firestore
      await _incidentService.addIncident(incident);

      // Show success and navigate to confirmation
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident reported successfully!')));

      // Navigate to confirmation page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncidentConfirmationPage(
            incidentType: _incidentType,
            location: _currentAddress,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit report: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Incident',
          style: TextStyle(fontFamily: 'poppy'),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildSectionHeader('Incident Details'),
            const SizedBox(height: 16),
            _buildFormFields(),
            const SizedBox(height: 24),
            _buildErrorMessage(),
            const SizedBox(height: 16),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Your Current Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentAddress.isNotEmpty
                  ? _currentAddress
                  : 'Unable to get location',
            ),
            const SizedBox(height: 8),
            if (_currentPosition != null)
              Text(
                'Coordinates: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                '${_currentPosition!.longitude.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Refresh Location',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Reporter name
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please enter your name'
              : null,
          onSaved: (value) {
            _name = value!;
          },
        ),

        const SizedBox(height: 16),

        // Incident type dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Incident Type',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.warning_amber),
          ),
          value: _incidentType,
          items: AppConstants.incidentTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _incidentType = newValue;
              });
            }
          },
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please select incident type'
              : null,
        ),

        const SizedBox(height: 16),

        // Incident description
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Incident Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please describe the incident'
              : null,
          onSaved: (value) {
            _description = value!;
          },
        ),

        const SizedBox(height: 16),

        // People affected
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Number of People Affected',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.people),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of people affected';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onSaved: (value) {
            _peopleAffected = int.parse(value!);
          },
        ),

        const SizedBox(height: 16),

        // Help needed
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Help Needed',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services),
            alignLabelWithHint: true,
          ),
          maxLines: 2,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please specify what help is needed'
              : null,
          onSaved: (value) {
            _helpNeeded = value!;
          },
        ),

        const SizedBox(height: 16),

        // Contact number
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Contact Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please enter a contact number'
              : null,
          onSaved: (value) {
            _contactNumber = value!;
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red[100],
      width: double.infinity,
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red[900]),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Report Incident',
          style: const TextStyle(fontSize: 18),
        ),
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
        ),
      ),
    );
  }
}

// Confirmation page shown after successful report
class IncidentConfirmationPage extends StatelessWidget {
  final String incidentType;
  final String location;

  const IncidentConfirmationPage(
      {super.key, required this.incidentType, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Submitted'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your $incidentType incident report has been submitted successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: $location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Emergency services and nearby users have been notified of your situation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Return to Home'),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nearby Incidents Page (for viewing reported incidents)
class NearbyIncidentsPage extends StatefulWidget {
  const NearbyIncidentsPage({super.key});

  @override
  _NearbyIncidentsPageState createState() => _NearbyIncidentsPageState();
}

class _NearbyIncidentsPageState extends State<NearbyIncidentsPage> {
  final IncidentService _incidentService = IncidentService();
  List<Incident> _incidents = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadNearbyIncidents();
  }

  Future<void> _loadNearbyIncidents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      _currentPosition = await LocationService.getCurrentPosition();

      // Get incidents
      if (_currentPosition != null) {
        final incidents =
            await _incidentService.getNearbyIncidents(_currentPosition!);

        if (!mounted) return;
        setState(() {
          _incidents = incidents;
        });
      }
    } catch (e) {
      print('Error loading incidents: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyIncidents,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IncidentReportPage()),
          ).then((_) => _loadNearbyIncidents());
        },
        tooltip: 'Report New Incident',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_incidents.isEmpty) {
      return const Center(
        child: Text(
          'No incidents reported nearby',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: _incidents.length,
      itemBuilder: (context, index) {
        var incident = _incidents[index];
        return _buildIncidentCard(incident);
      },
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: _getIncidentIcon(incident.incidentType),
        title: Text(
          '${incident.incidentType} - ${incident.distance}km away',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(incident.description),
            const SizedBox(height: 4),
            Text(
              'Location: ${incident.address}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Help Needed: ${incident.helpNeeded}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        trailing: ElevatedButton(
          child: const Text('Respond'),
          onPressed: () {
            // Navigate to incident details page
            // This would be implemented in a real app
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _getIncidentIcon(String incidentType) {
    IconData iconData;
    Color iconColor;

    switch (incidentType) {
      case 'Fire':
        iconData = Icons.local_fire_department;
        iconColor = Colors.red;
        break;
      case 'Flood':
        iconData = Icons.water;
        iconColor = Colors.blue;
        break;
      case 'Earthquake':
        iconData = Icons.terrain;
        iconColor = Colors.brown;
        break;
      case 'Hurricane':
        iconData = Icons.cyclone;
        iconColor = Colors.purple;
        break;
      case 'Medical Emergency':
        iconData = Icons.medical_services;
        iconColor = Colors.green;
        break;
      case 'Building Collapse':
        iconData = Icons.domain_disabled;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.warning;
        iconColor = Colors.orange;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }
}
