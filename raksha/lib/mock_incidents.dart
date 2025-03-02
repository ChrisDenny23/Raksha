// Mock data for testing the VolunteerPage in the Raksha app
// Create a function that returns a list of Incident objects

import 'package:cloud_firestore/cloud_firestore.dart';

List<Incident> getMockIncidents() {
  final now = DateTime.now();

  return [
    Incident(
      id: "incident1",
      name: "Rahul Sharma",
      incidentType: "Fire",
      description:
          "Small fire in residential building, need help evacuating elderly residents from 2nd floor.",
      address: "42, Lakshmi Apartments, Koramangala 5th Block, Bengaluru",
      latitude: 12.9279,
      longitude: 77.6271,
      timestamp: now.subtract(const Duration(minutes: 28)),
      peopleAffected: "6",
      helpNeeded:
          "Need volunteers to help with evacuation and temporary shelter arrangement",
      contactNumber: "9876543210",
      distance: "1.2",
    ),
    Incident(
      id: "incident2",
      name: "Priya Patel",
      incidentType: "Flood",
      description:
          "Street flooding after heavy rain. Water entering ground floor houses. Need help with sandbags.",
      address: "23, Lake View Road, HSR Layout, Bengaluru",
      latitude: 12.9116,
      longitude: 77.6741,
      timestamp: now.subtract(const Duration(hours: 2)),
      peopleAffected: "12",
      helpNeeded:
          "Need help with water pumps and moving belongings to higher ground",
      contactNumber: "8765432109",
      distance: "3.5",
    ),
    Incident(
      id: "incident3",
      name: "Dr. Anjali Singh",
      incidentType: "Medical Emergency",
      description:
          "Elderly patient needs transportation to hospital. Ambulance delayed due to traffic.",
      address: "108, Green Park Colony, JP Nagar, Bengaluru",
      latitude: 12.8993,
      longitude: 77.5913,
      timestamp: now.subtract(const Duration(minutes: 45)),
      peopleAffected: "1",
      helpNeeded:
          "Need someone with a car who can help transport patient to nearby hospital",
      contactNumber: "7654321098",
      distance: "2.1",
    ),
    Incident(
      id: "incident4",
      name: "Vikram Malhotra",
      incidentType: "Building Collapse",
      description:
          "Partial collapse of old building wall. No injuries but area needs to be cordoned off.",
      address: "17, Gandhi Road, Indiranagar, Bengaluru",
      latitude: 12.9784,
      longitude: 77.6408,
      timestamp: now.subtract(const Duration(hours: 5)),
      peopleAffected: "0",
      helpNeeded:
          "Need volunteers to help set up safety barriers and direct pedestrians away from danger",
      contactNumber: "6543210987",
      distance: "4.7",
    ),
    Incident(
      id: "incident5",
      name: "Meera Krishnan",
      incidentType: "Hurricane",
      description:
          "Strong winds have damaged roofs and brought down trees. Roads blocked by debris.",
      address: "56, Palm Avenue, Whitefield, Bengaluru",
      latitude: 12.9698,
      longitude: 77.7499,
      timestamp: now.subtract(const Duration(hours: 8)),
      peopleAffected: "25",
      helpNeeded:
          "Need help with clearing roads, distributing emergency supplies, and temporary repairs",
      contactNumber: "9876123450",
      distance: "8.3",
    ),
    Incident(
      id: "incident6",
      name: "Arjun Reddy",
      incidentType: "Earthquake",
      description:
          "Minor tremors felt. Some cracks in older buildings. Need help with assessment.",
      address: "32, Rocky Heights, Marathahalli, Bengaluru",
      latitude: 12.9591,
      longitude: 77.6974,
      timestamp: now.subtract(const Duration(hours: 12)),
      peopleAffected: "30",
      helpNeeded:
          "Need volunteers with engineering/construction experience to help assess building safety",
      contactNumber: "8765123409",
      distance: "6.2",
    ),
    Incident(
      id: "incident7",
      name: "Sunita Rao",
      incidentType: "Landslide",
      description:
          "Small landslide near hillside community after heavy rain. Road partially blocked.",
      address: "78, Hill View Road, Bannerghatta, Bengaluru",
      latitude: 12.8698,
      longitude: 77.5966,
      timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      peopleAffected: "15",
      helpNeeded:
          "Need help with clearing debris from access road and checking on isolated residents",
      contactNumber: "7654987650",
      distance: "9.5",
    ),
    Incident(
      id: "incident8",
      name: "Mohammed Hussain",
      incidentType: "Fire",
      description:
          "Kitchen fire in restaurant. Fire extinguished but smoke damage. Need cleanup help.",
      address: "12, Food Street, Jayanagar, Bengaluru",
      latitude: 12.9299,
      longitude: 77.5932,
      timestamp: now.subtract(const Duration(hours: 18)),
      peopleAffected: "8",
      helpNeeded:
          "Need volunteers to help with cleanup and temporary arrangements for affected staff",
      contactNumber: "6543987650",
      distance: "5.3",
    ),
    Incident(
      id: "incident9",
      name: "Kavita Nair",
      incidentType: "Flood",
      description:
          "Sewage backup causing flooding in basement apartments. Health hazard.",
      address: "45, River View Apartments, Bellandur, Bengaluru",
      latitude: 12.9254,
      longitude: 77.6771,
      timestamp: now.subtract(const Duration(hours: 6)),
      peopleAffected: "20",
      helpNeeded:
          "Need urgent help with pumping water, sanitation, and providing alternative accommodation",
      contactNumber: "9876543215",
      distance: "3.8",
    ),
    Incident(
      id: "incident10",
      name: "Rajesh Kumar",
      incidentType: "Medical Emergency",
      description:
          "Community health crisis - several cases of food poisoning from local event.",
      address: "89, Community Hall, Electronic City, Bengaluru",
      latitude: 12.8399,
      longitude: 77.6770,
      timestamp: now.subtract(const Duration(hours: 10)),
      peopleAffected: "35",
      helpNeeded:
          "Need volunteers with medical background to help assess patients and arrange transport",
      contactNumber: "8765432156",
      distance: "7.6",
    ),
  ];
}

// You'll also need this class definition to match your application's data model

class Incident {
  final String? id;
  final String name;
  final String incidentType;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final dynamic timestamp;
  final String peopleAffected;
  final String helpNeeded;
  final String contactNumber;
  final String? distance;

  Incident({
    this.id,
    required this.name,
    required this.incidentType,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.peopleAffected,
    required this.helpNeeded,
    required this.contactNumber,
    this.distance,
  });

  // Add a factory constructor to convert from Firestore document
  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      name: data['name'] ?? '',
      incidentType: data['incidentType'] ?? 'Other',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['location'] != null)
          ? data['location']['latitude'] ?? 0.0
          : 0.0,
      longitude: (data['location'] != null)
          ? data['location']['longitude'] ?? 0.0
          : 0.0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      peopleAffected: data['peopleAffected']?.toString() ?? '0',
      helpNeeded: data['helpNeeded'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
    );
  }

  // Add a method to create a copy with distance
  Incident copyWithDistance(String distanceValue) {
    return Incident(
      id: id,
      name: name,
      incidentType: incidentType,
      description: description,
      address: address,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      peopleAffected: peopleAffected,
      helpNeeded: helpNeeded,
      contactNumber: contactNumber,
      distance: distanceValue,
    );
  }
}
