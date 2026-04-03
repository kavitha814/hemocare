import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'globals.dart';
import 'translations.dart';

class Tip {
  final String title;
  final String advice;

  const Tip({required this.title, required this.advice});
}

final List<Tip> tips = [
  const Tip(title: "Heart Health", advice: "Reduce salt intake to less than 5g per day to prevent hypertension and heart disease risk."),
  const Tip(title: "Cancer Screening", advice: "Women over 40 should get mammograms; Men over 50 should check prostate health regularily."),
  const Tip(title: "Diabetes Control", advice: "Maintain a healthy weight. Losing just 5-7% of body weight can prevent Type 2 diabetes."),
  const Tip(title: "Bone Health", advice: "Consume adequate Calcium and Vitamin D. Resistance training helps bone density."),
  const Tip(title: "Skin Protection", advice: "Wear sunscreen with SPF 30+ daily, even on cloudy days, to prevent skin cancer."),
  const Tip(title: "Hearing Protection", advice: "Avoid loud environments or wear earplugs. Keep headphone volume below 60%."),
  const Tip(title: "Liver Care", advice: "Avoid sharing needles or razors. Vaccinate against Hepatitis B. Limit alcohol."),
  const Tip(title: "Kidney Health", advice: "Stay hydrated. Avoid overuse of painkillers like ibuprofen which can harm kidneys."),
  const Tip(title: "Eye Health", advice: "Wear sunglasses that block 100% of UV rays. Don't smoke, as it damages optic nerves."),
  const Tip(title: "Dental Hygiene", advice: "Replace your toothbrush every 3 to 4 months. Floss daily to prevent heart-linked gum disease."),
  const Tip(title: "Cholesterol", advice: "Replace saturated fats (butter, fatty meat) with unsaturated fats (olive oil, nuts)."),
  const Tip(title: "Blood Pressure", advice: "Check your blood pressure regularly at home. Silent hypertension damages organs."),
  const Tip(title: "Stress Management", advice: "Chronic stress weakens immunity. Practice yoga, hobbies, or talk therapy."),
  const Tip(title: "Safe Driving", advice: "Wear seatbelts and helmets. Road accidents are a leading cause of preventable injury."),
  const Tip(title: "Food Safety", advice: "Cook meat thoroughly. Avoid cross-contamination between raw meat and vegetables."),
  const Tip(title: "Immunity Boost", advice: "Eat probiotics (yogurt) and prebiotics (fiber) to support gut health and immunity."),
  const Tip(title: "Stroke Prevention", advice: "Know the FAST signs: Face drooping, Arm weakness, Speech difficulty, Time to call."),
  const Tip(title: "Sexual Health", advice: "Practice safe precautions. Get regular screenings for STIs if sexually active."),
  const Tip(title: "Mental Health", advice: "Don't ignore persistent sadness or anxiety. Seek professional help early."),
  const Tip(title: "Medication Safety", advice: "Take medicines exactly as prescribed. Don't self-medicate with antibiotics."),
];

class PreventiveCareScreen extends StatelessWidget {
  const PreventiveCareScreen({super.key});

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
                        AppTranslations.get('preventive_care', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.shield_rounded, color: Color(0xFF00A98F)),
                        onPressed: () {},
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
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      itemCount: tips.length,
                      itemBuilder: (context, index) {
                        final tip = tips[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFFE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00A98F).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.shield_outlined, color: Color(0xFF00A98F), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tip.title, 
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF0D2B28))
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                tip.advice, 
                                style: GoogleFonts.poppins(color: const Color(0xFF64748B), height: 1.5, fontSize: 13)
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
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
}
