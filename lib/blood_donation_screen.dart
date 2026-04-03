import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'globals.dart';
import 'translations.dart';
import 'user_profile_icon.dart';
import 'donor_registration_screen.dart';
import 'request_blood_screen.dart';

class BloodDonationScreen extends StatelessWidget {
  const BloodDonationScreen({super.key});

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      _headerLogo(),
                      const SizedBox(width: 12),
                      Text(
                        AppTranslations.get('blood', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      const EmergencyHelpIcon(),
                    ],
                  ),
                ),

                // Main Container
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
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.get('welcome_back', lang),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D2B28),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppTranslations.get('choose_proceed', lang),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 64),
                          
                          // Action Cards
                          _buildActionCard(
                            title: AppTranslations.get('register_donor', lang),
                            description: AppTranslations.get('register_donor_desc', lang),
                            icon: Icons.water_drop_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DonorRegistrationScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildActionCard(
                            title: AppTranslations.get('request_blood', lang),
                            description: AppTranslations.get('request_blood_desc', lang),
                            icon: Icons.volunteer_activism_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RequestBloodScreen()),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Info Banner
                          _buildInfoBanner(
                            message: AppTranslations.get('blood_contribution_hint', lang),
                            icon: Icons.info_outline_rounded,
                          ),
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

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A98F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFF00A98F), size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD1F0EC), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner({required String message, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEFBFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00A98F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerLogo() {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00A98F).withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A98F).withOpacity(0.4),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Icon(Icons.favorite, size: 16, color: Color(0xFF00A98F)),
          ),
        ],
      ),
    );
  }
}
