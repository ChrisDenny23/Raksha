// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raksha/incident_report.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_incidents.dart' as mock;

class VolunteerPage extends StatefulWidget {
  const VolunteerPage({super.key});

  @override
  _VolunteerPageState createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> {
  List<Incident> _incidents = [];
  bool _isLoading = true;
  Position? _currentPosition;
  List<String> _volunteeredIncidents = [];
  bool _showOnlyNeedsHelp = false;
  String _filterIncidentType = 'All';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadVolunteeredIncidents();
    _loadNearbyIncidents();
  }

  // Load volunteered incidents from SharedPreferences
  Future<void> _loadVolunteeredIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volunteeredIncidents = prefs.getStringList('volunteeredIncidents') ?? [];
    });
  }

  // Save volunteered incidents to SharedPreferences
  Future<void> _saveVolunteeredIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('volunteeredIncidents', _volunteeredIncidents);
  }

  Future<void> _loadNearbyIncidents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      // Get current location
      _currentPosition = await LocationService.getCurrentPosition();

      // USE MOCK DATA INSTEAD OF FIREBASE
      if (_currentPosition != null) {
        // Get mock incidents - but specify the type
        final mockIncidents = mock.getMockIncidents();

        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        // Convert mock incidents to the correct Incident type
        // Assuming you want to use the incident_report.dart Incident class
        setState(() {
          _incidents = mockIncidents
              .map((mockIncident) => Incident(
                    id: mockIncident.id,
                    name: mockIncident.name,
                    description: mockIncident.description,
                    incidentType: mockIncident.incidentType,
                    latitude: mockIncident.latitude,
                    longitude: mockIncident.longitude,
                    address: mockIncident.address,
                    contactNumber: mockIncident.contactNumber,
                    peopleAffected:
                        int.tryParse(mockIncident.peopleAffected) ?? 0,
                    helpNeeded: mockIncident.helpNeeded,
                    timestamp: Timestamp.fromDate(mockIncident.timestamp),
                    distance: mockIncident.distance,
                    // Add any other fields that need to be mapped
                  ))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading incidents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load incidents: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _toggleVolunteer(String incidentId) {
    setState(() {
      if (_volunteeredIncidents.contains(incidentId)) {
        _volunteeredIncidents.remove(incidentId);
      } else {
        _volunteeredIncidents.add(incidentId);
      }
      _saveVolunteeredIncidents();
    });
  }

  void _callEmergencyContact(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not call $phoneNumber'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  List<Incident> get _filteredIncidents {
    return _incidents.where((incident) {
      // Apply type filter
      final bool typeMatches = _filterIncidentType == 'All' ||
          incident.incidentType == _filterIncidentType;

      // Apply needs help filter
      final bool needsHelpMatches = !_showOnlyNeedsHelp ||
          (incident.helpNeeded.isNotEmpty &&
              !_volunteeredIncidents.contains(incident.id));

      return typeMatches && needsHelpMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nearby Incidents',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : null,
          ),
        ),
        elevation: 2,
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _loadNearbyIncidents,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Finding nearby incidents...',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? theme.colorScheme.secondary
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNearbyIncidents,
              color: theme.primaryColor,
              child: Column(
                children: [
                  _buildFilters(),
                  Expanded(child: _buildIncidentsList()),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IncidentReportPage()),
          ).then((_) => _loadNearbyIncidents());
        },
        icon: const Icon(Icons.add_alert),
        label: const Text('Report Incident'),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark
            ? theme.cardColor.withOpacity(0.5)
            : theme.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    color: isDark ? theme.cardColor : Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _filterIncidentType,
                      dropdownColor: isDark ? theme.cardColor : Colors.white,
                      hint: const Text('Filter by type'),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark
                            ? theme.colorScheme.secondary
                            : theme.primaryColor,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _filterIncidentType = value!;
                        });
                      },
                      items: [
                        const DropdownMenuItem(
                            value: 'All', child: Text('All Types')),
                        ...AppConstants.incidentTypes.map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type));
                        })
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    color: isDark ? theme.cardColor : Colors.white,
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      'Needs Help',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? theme.colorScheme.secondary : null,
                      ),
                    ),
                    value: _showOnlyNeedsHelp,
                    activeColor: theme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyNeedsHelp = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : theme.primaryColor.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color:
                      isDark ? theme.colorScheme.secondary : theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your location: ',
                  style: TextStyle(
                    color: isDark ? theme.colorScheme.secondary : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    _currentPosition != null
                        ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                        : 'Unknown',
                    style: TextStyle(
                      color: isDark
                          ? theme.colorScheme.secondary
                          : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? Colors.blueGrey.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? Colors.lightBlue : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Showing ${_filteredIncidents.length} incidents',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.lightBlue : Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_filteredIncidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No incidents match your filters',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? theme.colorScheme.secondary : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadNearbyIncidents,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80), // Add padding for FAB
      itemCount: _filteredIncidents.length,
      itemBuilder: (context, index) {
        var incident = _filteredIncidents[index];
        return _buildIncidentCard(incident);
      },
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool hasVolunteered = _volunteeredIncidents.contains(incident.id);

    // Use incident distance to determine urgency color
    final double? distanceValue =
        incident.distance != null ? double.tryParse(incident.distance!) : null;

    Color getUrgencyColor() {
      if (distanceValue == null) return Colors.orange;
      if (distanceValue < 2) return Colors.red;
      if (distanceValue < 5) return Colors.orange;
      if (distanceValue < 10) return Colors.amber;
      return Colors.green;
    }

    final urgencyColor = getUrgencyColor();

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasVolunteered
              ? theme.primaryColor.withOpacity(0.5)
              : Colors.transparent,
          width: hasVolunteered ? 2 : 0,
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getIncidentIcon(incident.incidentType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getIncidentColor(incident.incidentType)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              incident.incidentType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _getIncidentColor(incident.incidentType),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_walk,
                                  size: 14,
                                  color: urgencyColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${incident.distance}km',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: urgencyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Reported by: ${incident.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(incident.timestamp),
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.description,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isDark ? theme.colorScheme.secondary : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blueGrey.withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              incident.address,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: isDark ? Colors.blue[300] : Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'People affected: ${incident.peopleAffected}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color:
                                  isDark ? Colors.blue[300] : Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.error.withOpacity(0.15)
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? theme.colorScheme.error.withOpacity(0.3)
                          : Colors.red[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 18,
                        color:
                            isDark ? theme.colorScheme.error : Colors.red[700],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          incident.helpNeeded,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: isDark
                                ? theme.colorScheme.error
                                : Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () =>
                            _callEmergencyContact(incident.contactNumber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          hasVolunteered
                              ? Icons.check_circle
                              : Icons.volunteer_activism,
                          size: 18,
                        ),
                        label:
                            Text(hasVolunteered ? 'Volunteered' : 'Volunteer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasVolunteered
                              ? Colors.grey[600]
                              : theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _toggleVolunteer(incident.id ?? '');
                          if (!hasVolunteered) {
                            _showVolunteerConfirmation(incident);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _openMap(incident.latitude, incident.longitude);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVolunteerConfirmation(Incident incident) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? theme.cardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Thank You for Volunteering!',
              style: TextStyle(
                color: isDark ? theme.colorScheme.secondary : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have volunteered to help with this ${incident.incidentType} incident.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? theme.colorScheme.secondary : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Next steps:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? theme.colorScheme.secondary : null,
              ),
            ),
            const SizedBox(height: 10),
            _buildStepItem(
              context,
              '1',
              'Call the contact person to coordinate your help',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildStepItem(
              context,
              '2',
              'Provide only assistance you are qualified to give',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildStepItem(
              context,
              '3',
              'Stay safe and follow emergency protocols',
              isDark,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.primaryColor.withOpacity(0.1)
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          incident.contactNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? theme.colorScheme.secondary : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? theme.colorScheme.secondary : Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _callEmergencyContact(incident.contactNumber);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
      BuildContext context, String number, String text, bool isDark) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? theme.primaryColor : theme.primaryColor,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? theme.colorScheme.secondary : null,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open maps'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _getIncidentIcon(String incidentType) {
    IconData iconData;
    Color iconColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    iconColor = _getIncidentColor(incidentType);
    iconData = _getIncidentIconData(incidentType);

    // Adjust color opacity for dark mode
    if (isDark) {
      iconColor = iconColor.withOpacity(0.8);
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor, size: 26),
    );
  }

  IconData _getIncidentIconData(String incidentType) {
    switch (incidentType) {
      case 'Fire':
        return Icons.local_fire_department;
      case 'Flood':
        return Icons.water;
      case 'Earthquake':
        return Icons.terrain;
      case 'Hurricane':
        return Icons.cyclone;
      case 'Medical Emergency':
        return Icons.medical_services;
      case 'Building Collapse':
        return Icons.domain_disabled;
      case 'Landslide':
        return Icons.landscape;
      default:
        return Icons.warning;
    }
  }

  Color _getIncidentColor(String incidentType) {
    switch (incidentType) {
      case 'Fire':
        return Colors.red;
      case 'Flood':
        return Colors.blue;
      case 'Earthquake':
        return Colors.brown;
      case 'Hurricane':
        return Colors.purple;
      case 'Medical Emergency':
        return Colors.red[700]!;
      case 'Building Collapse':
        return Colors.amber[800]!;
      case 'Landslide':
        return Colors.green[800]!;
      default:
        return Colors.orange;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      // Default case if the timestamp is in an unexpected format
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
