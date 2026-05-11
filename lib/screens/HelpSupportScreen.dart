import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const String _supportPhoneNumber = '9010931034';
  static const String _defaultSupportMessage =
      'Hi YemPower Support, I need help with the app.';

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill out the form below and we\'ll get back to you as soon as possible.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // Contact Form
            Card(
              elevation: 0,
              color: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Subject
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Subject',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _subjectController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Enter subject/title',
                        hintStyle: TextStyle(color: Colors.grey.shade700),
                        filled: true,
                        fillColor: const Color(0xFFF6F6F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E5BFF),
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Message
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Describe your issue or question...',
                        hintStyle: TextStyle(color: Colors.grey.shade700),
                        filled: true,
                        fillColor: const Color(0xFFF6F6F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E5BFF),
                            width: 1.6,
                          ),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Chat on WhatsApp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              color: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                iconColor: Colors.black54,
                collapsedIconColor: Colors.black54,
                title: const Text(
                  'How do I create a post?',
                  style: TextStyle(color: Colors.black87),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Go to the Marketplace tab and click the "+" button to create a new post. Fill in the required details and submit.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Card(
              elevation: 0,
              color: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                iconColor: Colors.black54,
                collapsedIconColor: Colors.black54,
                title: const Text(
                  'How does the barter system work?',
                  style: TextStyle(color: Colors.black87),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'You can list items you want to trade and specify what you\'re looking for in return. Other users can make offers, and you can negotiate until reaching an agreement.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Card(
              elevation: 0,
              color: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                iconColor: Colors.black54,
                collapsedIconColor: Colors.black54,
                title: const Text(
                  'How do I complete a trade?',
                  style: TextStyle(color: Colors.black87),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Once both parties agree on the trade terms, mark the deal as completed in the chat. You can then rate the transaction and provide feedback.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Card(
              elevation: 0,
              color: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                iconColor: Colors.black54,
                collapsedIconColor: Colors.black54,
                title: const Text(
                  'What payment methods are accepted?',
                  style: TextStyle(color: Colors.black87),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'We accept major credit cards and digital payment methods through secure in-app payment processing.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Information
            Card(
              elevation: 0,
              color: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Other Ways to Reach Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactInfo(
                      Icons.email,
                      'Email',
                      'support@YemPover.com',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfo(
                      Icons.phone,
                      'Phone',
                      '+91 9010931034',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfo(
                      Icons.access_time,
                      'Hours',
                      'Mon-Fri: 9 AM - 6 PM EST',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfo(
                      Icons.language,
                      'Website',
                      'www.YemPover.com',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    String text = _defaultSupportMessage;
    if (subject.isNotEmpty || message.isNotEmpty) {
      text =
          'Hi YemPower Support, I need help.\n\n'
          'Subject: ${subject.isEmpty ? 'General Support' : subject}\n'
          'Message: ${message.isEmpty ? 'Please contact me regarding app support.' : message}';
    }

    final encodedText = Uri.encodeComponent(text);
    final whatsappAppUri = Uri.parse(
      'whatsapp://send?phone=91$_supportPhoneNumber&text=$encodedText',
    );
    final whatsappWebUri = Uri.parse(
      'https://wa.me/91$_supportPhoneNumber?text=$encodedText',
    );

    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open WhatsApp right now. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to WhatsApp support...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open WhatsApp. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
