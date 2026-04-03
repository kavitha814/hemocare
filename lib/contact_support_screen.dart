import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'globals.dart';
import 'translations.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _problemController = TextEditingController();

  void _showComingSoon(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppTranslations.get('helpline', lang),
          style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppTranslations.get('coming_soon', lang),
          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D2B28), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppTranslations.get('contact_support', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FFFE),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Contact Buttons
                          _buildQuickContactCard(
                            lang: lang,
                            icon: Icons.language_rounded,
                            title: AppTranslations.get('website', lang),
                            color: const Color(0xFF3B82F6),
                            onTap: () => _launchURL('https://careconnect-oy63.onrender.com'),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickContactCard(
                            lang: lang,
                            icon: Icons.forum_rounded,
                            title: AppTranslations.get('whatsapp', lang),
                            color: const Color(0xFF25D366),
                            onTap: () => _showComingSoon(context, lang),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickContactCard(
                            lang: lang,
                            icon: Icons.alternate_email_rounded,
                            title: AppTranslations.get('email', lang),
                            color: const Color(0xFFEA4335),
                            onTap: () => _launchURL('mailto:careconnectindiaofficial@gmail.com'),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickContactCard(
                            lang: lang,
                            icon: Icons.headset_mic_rounded,
                            title: AppTranslations.get('helpline', lang),
                            color: const Color(0xFF8B5CF6),
                            onTap: () => _launchURL('tel:6383687902'),
                          ),

                          const SizedBox(height: 32),

                          // Support Form
                          Text(
                            AppTranslations.get('problem_faced', lang).toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B), letterSpacing: 1),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FFFE),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    label: AppTranslations.get('full_name', lang),
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: AppTranslations.get('support_email', lang),
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _problemController,
                                    label: AppTranslations.get('message_placeholder', lang),
                                    icon: Icons.edit_note_rounded,
                                    maxLines: 4,
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(colors: [Color(0xFF00A98F), Color(0xFF00D1C1)]),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(AppTranslations.get('send_request', lang))),
                                          );
                                          _nameController.clear();
                                          _emailController.clear();
                                          _problemController.clear();
                                        }
                                      },
                                      child: Text(
                                        AppTranslations.get('send_request', lang).toUpperCase(),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickContactCard({
    required String lang,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FFFE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: const Color(0xFF0D2B28).withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEFBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF00A98F), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }
}
