import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelplinePage extends StatefulWidget {
  const HelplinePage({super.key});

  @override
  State<HelplinePage> createState() => _HelplinePageState();
}

class _HelplinePageState extends State<HelplinePage> {
  final List<Map<String, dynamic>> helplines = [
    // Emergency Services
    {
      'name': 'National Emergency Number',
      'number': '112',
      'category': 'Emergency'
    },
    {'name': 'Police', 'number': '100', 'category': 'Emergency'},
    {'name': 'Fire', 'number': '101', 'category': 'Emergency'},
    {'name': 'Ambulance', 'number': '102', 'category': 'Emergency'},
    {
      'name': 'Disaster Management Services',
      'number': '108',
      'category': 'Emergency'
    },

    // Women Helplines
    {
      'name': 'Women Helpline (All India)',
      'number': '1091',
      'category': 'Women'
    },
    {
      'name': 'Women Helpline Domestic Abuse',
      'number': '181',
      'category': 'Women'
    },

    // Child Helplines
    {'name': 'Child Helpline', 'number': '1098', 'category': 'Children'},

    // Health Helplines
    {
      'name': 'National AIDS Control Organization',
      'number': '1097',
      'category': 'Health'
    },
    {
      'name': 'Mental Health Helpline',
      'number': '1800-599-0019',
      'category': 'Health'
    },
    {'name': 'COVID-19 Helpline', 'number': '1075', 'category': 'Health'},

    // Senior Citizen Helplines
    {
      'name': 'Senior Citizen Helpline',
      'number': '14567',
      'category': 'Senior Citizens'
    },

    // Railway Helplines
    {
      'name': 'Railway Accident Emergency Service',
      'number': '1072',
      'category': 'Transport'
    },
    {'name': 'Railway Enquiry', 'number': '139', 'category': 'Transport'},

    // Road Safety
    {
      'name': 'Road Accident Emergency Service',
      'number': '1073',
      'category': 'Transport'
    },
    {
      'name': 'Highway Police Helpline',
      'number': '1033',
      'category': 'Transport'
    },

    // Tourist Helplines
    {'name': 'Tourist Helpline', 'number': '1363', 'category': 'Tourism'},

    // Utility Services
    {'name': 'LPG Leak Helpline', 'number': '1906', 'category': 'Utility'},
    {'name': 'Electricity Complaints', 'number': '1912', 'category': 'Utility'},

    // Cyber Crime
    {
      'name': 'Cyber Crime Helpline',
      'number': '1930',
      'category': 'Cyber Crime'
    },
    {
      'name': 'National Cyber Crime Reporting Portal',
      'number': '155260',
      'category': 'Cyber Crime'
    },
  ];

  String selectedCategory = 'All';
  List<String> categories = ['All'];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Extract unique categories
    for (var helpline in helplines) {
      if (!categories.contains(helpline['category'])) {
        categories.add(helpline['category']);
      }
    }
  }

  List<Map<String, dynamic>> getFilteredHelplines() {
    if (searchController.text.isNotEmpty) {
      return helplines
          .where((helpline) =>
              helpline['name']
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase()) ||
              helpline['number'].contains(searchController.text))
          .toList();
    }

    if (selectedCategory == 'All') {
      return helplines;
    }

    return helplines
        .where((helpline) => helpline['category'] == selectedCategory)
        .toList();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors from your app's theme
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    // ignore: unused_local_variable
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor =
        theme.primaryColor; // Use theme's primaryColor from AppThemes

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Indian Helpline Directory",
          style: TextStyle(fontFamily: 'poppy'),
        ),
        // Use the appBarTheme defined in AppThemes
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search helplines',
                labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
                suffixIcon: Icon(Icons.search, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: primaryColor, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
              ),
              cursorColor: primaryColor,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Category filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      color: selectedCategory == category
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: selectedCategory == category
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: colorScheme.surfaceVariant,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Helpline list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: getFilteredHelplines().length,
              itemBuilder: (context, index) {
                final helpline = getFilteredHelplines()[index];
                // Color coding by category
                Color categoryColor;
                switch (helpline['category']) {
                  case 'Emergency':
                    categoryColor = Colors.red;
                    break;
                  case 'Women':
                    categoryColor = Colors.purple;
                    break;
                  case 'Children':
                    categoryColor = Colors.blue;
                    break;
                  case 'Health':
                    categoryColor = Colors.green;
                    break;
                  case 'Transport':
                    categoryColor = Colors.amber;
                    break;
                  case 'Cyber Crime':
                    categoryColor = Colors.deepOrange;
                    break;
                  default:
                    categoryColor =
                        primaryColor; // Use theme's primaryColor for default
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: categoryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      helpline['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            helpline['category'],
                            style: TextStyle(
                              fontSize: 12,
                              color: categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          helpline['number'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Material(
                          elevation: 2,
                          shape: const CircleBorder(),
                          color: categoryColor,
                          child: IconButton(
                            icon: const Icon(Icons.call, color: Colors.white),
                            onPressed: () {
                              _makePhoneCall(helpline['number']);
                            },
                            tooltip: 'Call ${helpline['number']}',
                          ),
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
