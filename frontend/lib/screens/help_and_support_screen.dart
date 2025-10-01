// lib/screens/help_and_support_screen.dart
import 'package:flutter/material.dart';
import 'package:chat_app/screens/faq_screen.dart';
// import 'package:url_launcher/url_launcher.dart'; // For email/phone links

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  // Future<void> _launchEmail() async {
  //   final Uri emailLaunchUri = Uri(
  //     scheme: 'mailto',
  //     path: 'support@yourcompany.com',
  //     queryParameters: {
  //       'subject': 'Enginuity App Support Request',
  //     },
  //   );
  //   if (await canLaunchUrl(emailLaunchUri)) {
  //     await launchUrl(emailLaunchUri);
  //   } else {
  //     // Handle error (e.g., no email app found)
  //     debugPrint('Could not launch email');
  //   }
  // }

  // Future<void> _launchPhone() async {
  //   final Uri phoneLaunchUri = Uri(
  //     scheme: 'tel',
  //     path: '+1234567890', // Replace with your support phone number
  //   );
  //   if (await canLaunchUrl(phoneLaunchUri)) {
  //     await launchUrl(phoneLaunchUri);
  //   } else {
  //     debugPrint('Could not launch phone dialer');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // For back button
        elevation: 1, // Subtle shadow
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHelpOption(
            context,
            // FIX IS HERE: Corrected icon name
            icon: Icons.question_mark, // Changed from Icons.Youtube_outlined
            title: 'Frequently Asked Questions (FAQs)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),
          _buildHelpOption(
            context,
            icon: Icons.contact_support_outlined,
            title: 'Contact Us',
            onTap: () {
              // _launchEmail(); // Uncomment and enable url_launcher for this
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Contact support at jhoms1118@gmail.')),
              );
            },
          ),
          _buildHelpOption(
            context,
            icon: Icons.phone_outlined,
            title: 'Call Support',
            onTap: () {
              // _launchPhone(); // Uncomment and enable url_launcher for this
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call support at 0916 325 9464')),
              );
            },
          ),
          _buildHelpOption(
            context,
            icon: Icons.info_outline,
            title: 'About Enginuity',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Enginuity App',
                applicationVersion: '1.0.0', // Your app version
                applicationLegalese:
                    '© 2023 Your Company. All rights reserved.',
                children: [
                  const Text(
                      'This app helps clients manage their projects efficiently.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
