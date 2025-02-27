// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';

class DisasterScreen extends StatefulWidget {
  const DisasterScreen({super.key});

  @override
  _DisasterScreenState createState() => _DisasterScreenState();
}

class _DisasterScreenState extends State<DisasterScreen> {
  final Map<String, Map<String, List<String>>> disasterGuidelines = {
    "Earthquake": {
      "Dos": [
        "Drop, Cover, and Hold On.",
        "Stay indoors until the shaking stops.",
        "Move away from windows and heavy objects."
      ],
      "Don'ts": ["Do not use elevators.", "Do not run outside during shaking."]
    },
    "Floods": {
      "Dos": [
        "Move to higher ground.",
        "Avoid walking or driving through floodwaters."
      ],
      "Don'ts": [
        "Do not touch electrical equipment with wet hands.",
        "Do not drink floodwater."
      ]
    },
    "Landslides": {
      "Dos": [
        "Stay alert in hilly areas.",
        "Move to stable ground if signs appear."
      ],
      "Don'ts": [
        "Do not build near steep slopes.",
        "Do not ignore warning signs."
      ]
    },
    "Cyclone": {
      "Dos": [
        "Stay indoors and close windows.",
        "Keep emergency supplies ready."
      ],
      "Don'ts": [
        "Do not go outside during the storm.",
        "Do not ignore weather alerts."
      ]
    },
    "Tsunami": {
      "Dos": [
        "Move to higher ground immediately.",
        "Follow evacuation orders."
      ],
      "Don'ts": [
        "Do not go near the shore to watch waves.",
        "Do not ignore official warnings."
      ]
    },
    "Heat Wave": {
      "Dos": ["Drink plenty of water.", "Stay in cool, shaded areas."],
      "Don'ts": [
        "Do not go out in the sun unnecessarily.",
        "Do not consume alcohol or caffeine."
      ]
    },
    "Urban Floods": {
      "Dos": ["Avoid flooded streets.", "Disconnect electrical appliances."],
      "Don'ts": [
        "Do not attempt to walk through deep water.",
        "Do not drive through flooded roads."
      ]
    },
    "Fire": {
      "Dos": [
        "Use fire extinguishers if trained.",
        "Evacuate calmly using marked exits."
      ],
      "Don'ts": ["Do not use elevators.", "Do not panic."]
    },
    "Chemical Hazards": {
      "Dos": [
        "Wear protective gear if available.",
        "Follow emergency protocols."
      ],
      "Don'ts": [
        "Do not touch unknown substances.",
        "Do not ignore symptoms of exposure."
      ]
    },
    "Airport Emergency": {
      "Dos": ["Follow crew instructions.", "Use emergency exits calmly."],
      "Don'ts": ["Do not panic.", "Do not block aisles."]
    },
    "Bomb Blast": {
      "Dos": [
        "Take cover under sturdy furniture.",
        "Stay away from glass and debris."
      ],
      "Don'ts": ["Do not touch suspicious objects.", "Do not spread rumors."]
    },
    "Building Collapse": {
      "Dos": [
        "Cover your head and take shelter.",
        "Listen for rescue instructions."
      ],
      "Don'ts": ["Do not use lifts.", "Do not move too much if trapped."]
    },
    "Nuclear and Radiological Emergency": {
      "Dos": [
        "Stay indoors and close windows.",
        "Follow government instructions."
      ],
      "Don'ts": [
        "Do not consume open food/water.",
        "Do not try to self-evacuate without guidance."
      ]
    },
    "Stampede": {
      "Dos": [
        "Stay calm and move in the direction of the crowd.",
        "Protect your chest with arms."
      ],
      "Don'ts": ["Do not push others.", "Do not bend down to pick up objects."]
    },
    "Terrorist Activities": {
      "Dos": [
        "Report suspicious activities immediately.",
        "Stay indoors and secure all entry points."
      ],
      "Don'ts": [
        "Do not spread misinformation.",
        "Do not approach suspicious objects."
      ]
    }
  };

  final List<String> naturalDisasters = [
    "Earthquake",
    "Floods",
    "Landslides",
    "Cyclone",
    "Tsunami",
    "Heat Wave",
    "Urban Floods"
  ];
  final List<String> manMadeDisasters = [
    "Fire",
    "Chemical Hazards",
    "Airport Emergency",
    "Bomb Blast",
    "Building Collapse",
    "Nuclear and Radiological Emergency",
    "Stampede",
    "Terrorist Activities"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Disaster Guidelines",
          style: TextStyle(
            fontFamily: 'poppy',
            fontWeight: FontWeight.bold,
          ),
        ),
        // Let app theme control appearance
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildCategorySection("Natural Disasters", naturalDisasters),
            const SizedBox(height: 20),
            _buildCategorySection("Man-Made Disasters", manMadeDisasters),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<String> disasters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'poppy',
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 10),
        ...disasters.map((disaster) => _buildDisasterTile(disaster)).toList(),
      ],
    );
  }

  Widget _buildDisasterTile(String disaster) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        iconColor: Theme.of(context).primaryColor,
        collapsedIconColor: Theme.of(context).colorScheme.secondary,
        title: Text(
          disaster,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'poppy',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        children: _buildGuidelines(disaster),
      ),
    );
  }

  List<Widget> _buildGuidelines(String disaster) {
    final guidelines = disasterGuidelines[disaster] ?? {};
    return [
      if (guidelines.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (guidelines.containsKey("Dos"))
                ...guidelines["Dos"]!
                    .map((text) => _buildGuidelineItem(text, true))
                    .toList(),
              if (guidelines.containsKey("Don'ts"))
                ...guidelines["Don'ts"]!
                    .map((text) => _buildGuidelineItem(text, false))
                    .toList(),
            ],
          ),
        ),
    ];
  }

  Widget _buildGuidelineItem(String text, bool isDo) {
    return ListTile(
      leading: Icon(
        isDo ? Icons.check_circle : Icons.cancel,
        color:
            isDo ? Colors.green.shade600 : Theme.of(context).colorScheme.error,
      ),
      title: Text(
        text,
        style: TextStyle(
          fontFamily: 'poppylight',
          fontSize: 16,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      dense: true,
    );
  }
}
