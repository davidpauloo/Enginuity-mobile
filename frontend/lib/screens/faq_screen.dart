// lib/screens/faq_screen.dart
import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQs',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // For back button
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          FAQItem(
            question: 'How do I view my projects?',
            answer:
                'Navigate to the "Home" tab. All your ongoing and finished projects will be listed there.',
          ),
          FAQItem(
            question: 'How can I contact my project manager?',
            answer:
                'Go to the "Chats" tab to view your active conversations, or navigate to a specific project\'s detail screen to find their contact information.',
          ),
          FAQItem(
            question: 'What if my project deadline is missed?',
            answer:
                'Please contact your assigned Project Manager immediately via the chat feature or their direct contact details listed on the project page.',
          ),
          FAQItem(
            question: 'How can I update my profile information?',
            answer:
                'Go to the "Profile" tab and click on the "Edit Profile" button to change your details.',
          ),
          // Add more FAQ items as needed
        ],
      ),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({super.key, required this.question, required this.answer});

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              widget.answer,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
