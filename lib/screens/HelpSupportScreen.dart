import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/services/inquiry_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:yempover_app/widgets/app_text_field.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const String _supportPhoneNumber = '9010931034';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final InquiryService _inquiryService = InquiryService();
  final TokenService _tokenService = TokenService();

  bool _isGuestUser = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadGuestState();
  }

  Future<void> _loadGuestState() async {
    final isGuest = await _tokenService.isGuestUser();
    if (!mounted) return;
    setState(() => _isGuestUser = isGuest);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                    if (_isGuestUser) ...[
                      AppTextField(
                        label: 'Name',
                        hint: 'Enter your name',
                        controller: _nameController,
                        fillColor: const Color(0xFFF6F6F6),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        fillColor: const Color(0xFFF6F6F6),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Phone',
                        hint: 'Enter your phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        fillColor: const Color(0xFFF6F6F6),
                      ),
                      const SizedBox(height: 20),
                    ],
                    AppTextField(
                      label: 'Subject',
                      hint: 'Enter subject/title',
                      controller: _subjectController,
                      fillColor: const Color(0xFFF6F6F6),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Message',
                      hint: 'Describe your issue or question...',
                      controller: _messageController,
                      maxLines: 5,
                      alignLabelWithHint: true,
                      fillColor: const Color(0xFFF6F6F6),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Inquiry',
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
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqTile(
              'How do I create a post?',
              'Go to the Marketplace tab and click the "+" button to create a new post. Fill in the required details and submit.',
            ),
            const SizedBox(height: 8),
            _buildFaqTile(
              'How does the barter system work?',
              'You can list items you want to trade and specify what you\'re looking for in return. Other users can make offers, and you can negotiate until reaching an agreement.',
            ),
            const SizedBox(height: 8),
            _buildFaqTile(
              'How do I complete a trade?',
              'Once both parties agree on the trade terms, mark the deal as completed in the chat. You can then rate the transaction and provide feedback.',
            ),
            const SizedBox(height: 8),
            _buildFaqTile(
              'What payment methods are accepted?',
              'We accept major credit cards and digital payment methods through secure in-app payment processing.',
            ),
            const SizedBox(height: 32),
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
                      'support@yempover.com',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfo(
                      Icons.phone,
                      'Phone',
                      '+91 9010931034',
                      Colors.green,
                      onTap: _openWhatsAppSupport,
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfo(
                      Icons.chat,
                      'WhatsApp',
                      'Chat with support',
                      const Color(0xFF25D366),
                      onTap: _openWhatsAppSupport,
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
                      'www.yempover.com',
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

  Widget _buildFaqTile(String question, String answer) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF1F1F1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        iconColor: Colors.black54,
        collapsedIconColor: Colors.black54,
        title: Text(question, style: const TextStyle(color: Colors.black87)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
    IconData icon,
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    final content = Row(
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: onTap != null ? const Color(0xFF2E5BFF) : Colors.black87,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }

  String _buildInquiryMessage() {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty) return message;

    if (message.isEmpty) {
      return 'Subject: $subject';
    }

    return 'Subject: $subject\n\n$message';
  }

  Future<void> _submitForm() async {
    final message = _buildInquiryMessage();
    if (message.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please enter a message');
      return;
    }

    if (_isGuestUser) {
      final email = _emailController.text.trim();
      if (email.isNotEmpty &&
          !ValidationRegex.emailRegex.hasMatch(email)) {
        SnackbarUtils.showError(context, ErrorMessages.invalidEmail);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await _inquiryService.submitInquiry(
        message: message,
        name: _isGuestUser ? _nameController.text : null,
        email: _isGuestUser ? _emailController.text : null,
        phoneNumber: _isGuestUser ? _phoneController.text : null,
      );

      if (!mounted) return;

      _subjectController.clear();
      _messageController.clear();
      if (_isGuestUser) {
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
      }

      SnackbarUtils.showSuccess(
        context,
        'Your inquiry was submitted successfully. We\'ll get back to you soon.',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openWhatsAppSupport() async {
    const text = 'Hi BarterX Support, I need help with the app.';
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
      } else if (mounted) {
        SnackbarUtils.showError(
          context,
          'Unable to open WhatsApp right now. Please try again.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'Failed to open WhatsApp. Please try again.',
      );
    }
  }
}
