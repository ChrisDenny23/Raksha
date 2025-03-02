import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@raksha.app',
      queryParameters: {
        'subject': 'Support Request',
        'body': 'Please describe your issue here...',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email client';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Support",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'poppy'),
        ),
        // Using app theme AppBar styling
      ),
      // Using scaffold background color from theme
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Support intro card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How can we help you?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'poppy',
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We're here to assist with any issues you might be experiencing with Raksha.",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'poppylight',
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // FAQ Section
            Text(
              "Frequently Asked Questions",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'poppy',
                  color: Color(0xFF2196F3)),
            ),
            const SizedBox(height: 10),

            _buildFaqItem(
              context,
              "How do I set up emergency contacts?",
              "Go to the Emergency Contacts section in the app, tap the '+' button, and enter your contact's information.",
            ),

            _buildFaqItem(
              context,
              "How can I customize alert triggers?",
              "Navigate to Security Settings and select 'Alert Triggers' to customize when and how alerts are triggered.",
            ),

            _buildFaqItem(
              context,
              "Is my data secure?",
              "Yes, all your data is encrypted and stored securely. We never share your personal information with third parties.",
            ),

            _buildFaqItem(
              context,
              "Why isn't the location service working?",
              "Please ensure location permissions are enabled for Raksha in your device settings and that GPS is turned on.",
            ),

            const SizedBox(height: 20),

            // Contact Support Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contact Support",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'poppy',
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Need additional help? Our support team is available 24/7.",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'poppylight',
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _launchEmail,
                      icon: Icon(Icons.email,
                          color: theme.brightness == Brightness.light
                              ? Colors.white
                              : Colors.black),
                      label: Text(
                        "Email Support",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'poppy',
                          color: theme.brightness == Brightness.light
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Implement in-app chat support
                      },
                      icon: Icon(Icons.chat, color: theme.colorScheme.primary),
                      label: Text(
                        "Live Chat Support",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'poppy',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'poppy',
          color: theme.colorScheme.secondary,
        ),
      ),
      iconColor: theme.colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontFamily: 'poppylight',
              color: theme.colorScheme.onBackground,
            ),
          ),
        ),
      ],
    );
  }
}
