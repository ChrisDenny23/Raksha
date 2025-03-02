import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "About",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'poppy'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // App logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shield,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 16),

            // App name and version
            Text(
              "Raksha",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'poppy',
                  color: Color(0xFF2196F3)),
            ),

            Text(
              "Version $_version",
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'poppylight',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),

            const SizedBox(height: 32),

            // App description
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "About Raksha",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'poppy',
                        color: Color(0xFF2196F3)
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Raksha is a personal safety app designed to help users stay safe and connected with trusted contacts in emergency situations. Our mission is to provide peace of mind through technology that's reliable, easy to use, and always there when you need it most.",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'poppylight',
                        color: Theme.of(context).colorScheme.onBackground,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Features
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Key Features",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'poppy',
                        color: Color(0xFF2196F3)
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      Icons.notifications_active,
                      "Emergency Alerts",
                      "Send instant alerts to your emergency contacts",
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.location_on,
                      "Location Sharing",
                      "Share your real-time location with trusted contacts",
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.timer,
                      "Safety Check Timer",
                      "Set timers for automatic safety checks",
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.mic,
                      "Audio Recording",
                      "Discretely record audio in emergency situations",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Legal links
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      "Terms of Service",
                      style: TextStyle(
                        fontFamily: 'poppy',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onTap: () => _launchUrl("https://raksha.app/terms"),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      "Privacy Policy",
                      style: TextStyle(
                        fontFamily: 'poppy',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onTap: () => _launchUrl("https://raksha.app/privacy"),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.public,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      "Visit Website",
                      style: TextStyle(
                        fontFamily: 'poppy',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onTap: () => _launchUrl("https://raksha.app"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Text(
              "© 2025 Raksha Technologies. All rights reserved.",
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'poppylight',
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'poppy',
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'poppylight',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
