// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
    };
  }

  factory EmergencyContact.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      relationship: data['relationship'] ?? '',
    );
  }
}

class EmergencyContactsSection extends StatefulWidget {
  const EmergencyContactsSection({super.key});

  @override
  State<EmergencyContactsSection> createState() =>
      _EmergencyContactsSectionState();
}

class _EmergencyContactsSectionState extends State<EmergencyContactsSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  // Get current user's email
  String get _userEmail => _auth.currentUser?.email ?? '';

  // Get reference to user's document in Users collection
  DocumentReference get _userDocument =>
      _firestore.collection('Users').doc(_userEmail);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  // Function to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching phone dialer: $e')),
        );
      }
    }
  }

  Future<void> _addContact() async {
    final theme = Theme.of(context);

    if (_userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to add contacts'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    // Reset controllers before showing dialog
    _nameController.clear();
    _phoneController.clear();
    _relationshipController.clear();

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) => AlertDialog(
        title: Text('Add Emergency Contact',
            style: TextStyle(
                color: theme.textTheme.titleLarge?.color, fontFamily: 'poppy')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter contact name',
                  labelStyle: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontFamily: 'poppylight'),
                  hintStyle: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  labelStyle: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontFamily: 'poppylight'),
                  hintStyle: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _relationshipController,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'E.g., Family, Doctor, etc.',
                  labelStyle: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontFamily: 'poppylight'),
                  hintStyle: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(), // Explicitly pop the dialog
            child: Text('Cancel',
                style:
                    TextStyle(color: theme.primaryColor, fontFamily: 'poppy')),
          ),
          TextButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty) {
                await _saveContact();
                if (mounted)
                  Navigator.of(context).pop(); // Explicitly pop the dialog
              } else {
                // Show error but keep dialog open
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Name and phone number are required',
                      style: TextStyle(fontFamily: 'poppy'),
                    ),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            child: Text('Save',
                style:
                    TextStyle(color: theme.primaryColor, fontFamily: 'poppy')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveContact() async {
    try {
      // Get the existing contacts array or create a new one
      final userDoc = await _userDocument.get();
      List<Map<String, dynamic>> contacts = [];

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        contacts =
            List<Map<String, dynamic>>.from(data['emergency_contacts'] ?? []);
      }

      // Add new contact to the array
      contacts.add({
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'relationship': _relationshipController.text,
        'timestamp': DateTime.now()
            .toIso8601String(), // Use ISO string instead of FieldValue
        'id': DateTime.now()
            .millisecondsSinceEpoch
            .toString(), // Unique ID for the contact
      });

      // Update the document with the new contacts array
      await _userDocument.set({
        'emergency_contacts': contacts,
        'email': _userEmail,
        'username': userDoc.exists
            ? (userDoc.data() as Map<String, dynamic>)['username']
            : '',
        'lastUpdated': FieldValue
            .serverTimestamp(), // Add server timestamp at the document level
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contact: $e')),
        );
      }
    }
  }

  Widget _buildContactAvatar(Map<String, dynamic> contact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showContactCallOptions(contact),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: isDark
                    ? theme.primaryColor.withOpacity(0.2)
                    : theme.primaryColor.withOpacity(0.1),
                child: Text(
                  contact['name'].isNotEmpty
                      ? contact['name'][0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontFamily: 'poppy'),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact['name'],
              style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color,
                  fontFamily: 'poppylight'),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () => _deleteContact(contact['id']),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                size: 12,
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteContact(String contactId) async {
    final theme = Theme.of(context);
    final contactsSnapshot = await _userDocument.get();

    if (!contactsSnapshot.exists) return;

    final data = contactsSnapshot.data() as Map<String, dynamic>;
    final contacts =
        List<Map<String, dynamic>>.from(data['emergency_contacts'] ?? []);

    // Find the contact to be deleted
    final contactToDelete = contacts.firstWhere(
      (contact) => contact['id'] == contactId,
      orElse: () => <String, dynamic>{},
    );

    if (contactToDelete.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Confirm Delete',
              style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontFamily: 'poppy'),
            ),
            content: Text(
              'Are you sure you want to delete ${contactToDelete['name']} from your emergency contacts?',
              style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontFamily: 'poppylight'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: TextStyle(
                        color: theme.primaryColor, fontFamily: 'poppy')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(fontFamily: 'poppy'),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      // Remove the contact with matching ID
      contacts.removeWhere((contact) => contact['id'] == contactId);

      // Update the document with the filtered contacts array
      await _userDocument.update({'emergency_contacts': contacts});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
      }
    }
  }

  void _showContactCallOptions(Map<String, dynamic> contact) {
    final theme = Theme.of(context);
    final phoneNumber = contact['phoneNumber'];
    final contactName = contact['name'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Emergency Contact',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.primaryColor.withOpacity(0.2),
              child: Text(
                contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contactName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            Text(
              phoneNumber,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              '(${contact['relationship']})',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showContactDetails(contact);
            },
            child: Text('View Details',
                style: TextStyle(color: theme.primaryColor)),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.phone),
            label: Text('Call Now'),
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCall(phoneNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDetails(Map<String, dynamic> contact) {
    final theme = Theme.of(context);
    final phoneNumber = contact['phoneNumber'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Details',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${contact['name']}',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Phone: $phoneNumber',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    _makePhoneCall(phoneNumber);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Relationship: ${contact['relationship']}',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            if (contact['timestamp'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Added: ${_formatDate(contact['timestamp'])}',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.primaryColor)),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.phone),
            label: Text('Call Now'),
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCall(phoneNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_userEmail.isEmpty) {
      return Center(
        child: Text(
          'Please sign in to view emergency contacts',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Emergency Contacts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            Text(
              "(Tap to call)",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: StreamBuilder<DocumentSnapshot>(
            stream: _userDocument.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                );
              }

              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final contacts = List<Map<String, dynamic>>.from(
                  data?['emergency_contacts'] ?? []);

              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...contacts.map((contact) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildContactAvatar(contact),
                      )),
                  GestureDetector(
                    onTap: _addContact,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: isDark
                              ? theme.cardColor
                              : theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.add,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add New',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
