import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'globals.dart';
import 'translations.dart';
import 'user_profile_icon.dart';
import 'common_diseases_screen.dart';
import 'vaccination_screen.dart';
import 'healthy_habits_screen.dart';
import 'prevention_tips_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';

class DiseasesScreen extends StatelessWidget {
  const DiseasesScreen({super.key});

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
                // Custom Top Bar
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
                        AppTranslations.get('health_info', lang).toUpperCase(),
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
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.get('health_resources_title', lang).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppTranslations.get('health_resources_desc', lang),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0D2B28),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                                children: [
                                  _buildFeatureCard(
                                    context,
                                    title: AppTranslations.get('common_diseases', lang),
                                    description: AppTranslations.get('common_diseases_desc', lang),
                                    icon: Icons.coronavirus_rounded,
                                    color: Colors.blue,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommonDiseasesScreen())),
                                  ),
                                  _buildFeatureCard(
                                    context,
                                    title: AppTranslations.get('vaccination', lang),
                                    description: AppTranslations.get('vaccination_desc', lang),
                                    icon: Icons.vaccines_rounded,
                                    color: Colors.green,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VaccinationScheduleScreen())),
                                  ),
                                  _buildFeatureCard(
                                    context,
                                    title: AppTranslations.get('healthy_habits', lang),
                                    description: AppTranslations.get('healthy_habits_desc', lang),
                                    icon: Icons.favorite_rounded,
                                    color: Colors.orange,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthyHabitsScreen())),
                                  ),
                                  _buildFeatureCard(
                                    context,
                                    title: AppTranslations.get('preventive_care', lang),
                                    description: AppTranslations.get('preventive_care_desc', lang),
                                    icon: Icons.shield_rounded,
                                    color: Colors.purple,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PreventiveCareScreen())),
                                  ),
                                ],
                              );
                            },
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

  Widget _headerLogo() {
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00D1C1).withOpacity(0.1)),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D1C1).withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D1C1).withOpacity(0.4),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Icon(Icons.favorite, size: 16, color: Color(0xFF00D1C1)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0FFFE),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D2B28),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(Icons.arrow_forward_rounded, color: const Color(0xFF00A98F), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Placeholder Screens ---




