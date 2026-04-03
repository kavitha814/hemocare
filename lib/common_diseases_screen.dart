import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'globals.dart';
import 'translations.dart';

class Disease {
  final String name;
  final String what;
  final String why;
  final String cure;
  final String tips;

  const Disease({
    required this.name,
    required this.what,
    required this.why,
    required this.cure,
    required this.tips,
  });
}

final List<Disease> commonDiseases = [
  const Disease(
    name: "Influenza (Flu)",
    what: "A contagious respiratory illness caused by influenza viruses that infect the nose, throat, and lungs.",
    why: "Caused by influenza viruses spreading through droplets when people cough, sneeze, or talk. Weak immune system and close contact increase risk.",
    cure: "Rest, hydration, and over-the-counter fever reducers. Antiviral drugs may be prescribed by a doctor within 48 hours of symptoms.",
    tips: "Get a yearly flu vaccine. Wash hands frequently. Cover your mouth when coughing. Stay home if sick.",
  ),
  const Disease(
    name: "Common Cold",
    what: "A viral infection of your nose and throat (upper respiratory tract). It's usually harmless.",
    why: "Caused by many different types of viruses (rhinoviruses are most common). Spreads through air or direct contact.",
    cure: "No cure for the common cold. Recovery usually takes 7-10 days. Rest, fluids, and soothing remedies help symptoms.",
    tips: "Wash hands often. Avoid touching your face. Stay away from sick people. Keep your immune system strong.",
  ),
  const Disease(
    name: "COVID-19",
    what: "A disease caused by a coronavirus called SARS-CoV-2. It can trigger respiratory tract infection.",
    why: "Spreads when an infected person breathes out droplets and very small particles that contain the virus.",
    cure: "Mild cases recover at home with rest/fluids. Severe cases need hospital care. Consult a doctor immediately for breathing trouble.",
    tips: "Wear masks in crowded places. Vaccinate. Maintain distance. Wash hands. Monitor oxygen levels if positive.",
  ),
  const Disease(
    name: "Diabetes (Type 2)",
    what: "A chronic condition that affects the way the body processes blood sugar (glucose).",
    why: "Cells don't respond normally to insulin (insulin resistance). Risk factors: weight, inactivity, family history, age.",
    cure: "No cure, but managed via diet, exercise, and medication (metformin, insulin) as advised by a doctor.",
    tips: "Eat a balanced diet low in sugar. Exercise 30 mins daily. Monitor blood sugar regularly. Lose excess weight.",
  ),
  const Disease(
    name: "Hypertension (High BP)",
    what: "A condition in which the force of the blood against the artery walls is too high.",
    why: "Risks: High salt intake, lack of exercise, obesity, stress, smoking, and genetics.",
    cure: "Lifestyle changes and daily medication prescribed by cardiologists to lower pressure and prevent heart attacks.",
    tips: "Reduce salt. Exercise specific cardio. Manage stress. Limiting alcohol and quitting smoking are vital.",
  ),
  const Disease(
    name: "Migraine",
    what: "A headache of varying intensity, often accompanied by nausea and sensitivity to light and sound.",
    why: "Abnormal brain activity affecting nerve signals, chemicals, and blood vessels. Triggers: stress, foods, hormonal changes.",
    cure: "Pain relief medications and preventive drugs. Resting in a dark, quiet room often helps mild attacks.",
    tips: "Identify and avoid triggers. Maintain regular sleep. Stay hydrated. Manage stress. Keep a headache diary.",
  ),
  const Disease(
    name: "Gastroenteritis (Stomach Flu)",
    what: "Intestinal infection marked by diarrhea, cramps, nausea, vomiting, and fever.",
    why: "Contact with an infected person or consuming contaminated food or water (Viral or Bacterial).",
    cure: "Main focus is preventing dehydration. Oral Rehydration Solution (ORS) is key. Antibiotics only if bacterial.",
    tips: "Drink plenty of fluids. Eat bland foods (BRAT diet). Wash hands rigorously before eating.",
  ),
  const Disease(
    name: "Malaria",
    what: "A disease caused by a plasmodium parasite, transmitted by the bite of infected mosquitoes.",
    why: "Bite of infected female Anopheles mosquitoes. Not contagious from person to person basically.",
    cure: "Prescription antimalarial drugs. Early treatment is crucial to prevent severe complications.",
    tips: "Use mosquito nets and repellents. Wear long sleeves. Eliminate standing water where mosquitoes breed.",
  ),
  const Disease(
    name: "Dengue",
    what: "A mosquito-borne viral disease occurring in tropical and subtropical areas.",
    why: " transmitted by female mosquitoes mainly of the species Aedes aegypti.",
    cure: "No specific medicine. Pain relievers (avoid aspirin), plenty of fluids, and rest. Hospitalization for severe cases.",
    tips: "Prevent mosquito bites. Check for stagnant water. Wear protective clothing. Use screens on windows.",
  ),
  const Disease(
    name: "Typhoid",
    what: "A bacterial infection that can lead to high fever, diarrhea, and vomiting.",
    why: "Caused by Salmonella typhi bacteria via contaminated food or water.",
    cure: "Antibiotics prescribed by a doctor are effective. Finishing the full course is essential.",
    tips: "Drink only boiled/bottled water. Eat thoroughly cooked food. Vaccinate if traveling to high-risk areas.",
  ),
  const Disease(
    name: "Jaundice (Hepatitis A)",
    what: "A liver infection causing yellowing of skin/eyes, fatigue, and nausea.",
    why: "Ingestion of fecal matter, even in microscopic amounts, from close contact or contaminated food/water.",
    cure: "Body usually clears it over time. Rest and adequate nutrition/hydration. Avoid alcohol completely.",
    tips: "Vaccinate against Hepatitis A. Practice good hygiene. Sanitize water and food sources.",
  ),
  const Disease(
    name: "Asthma",
    what: "A condition in which your airways narrow and swell and may produce extra mucus.",
    why: "Genetic and environmental factors (pollen, dust mites, smoke, cold air, stress).",
    cure: "Inhalers (rescue and controller) to manage symptoms. No permanent cure, but controllable.",
    tips: "Know and avoid triggers. Use prescribed inhalers correctly. Get a flu shot. Keep home dust-free.",
  ),
  const Disease(
    name: "Tuberculosis (TB)",
    what: "A potentially serious infectious bacterial disease that mainly affects the lungs.",
    why: "Bacteria spread from person to person through microscopic droplets released into the air.",
    cure: "A long course of antibiotics (6-9 months). It is vital to finish medicine precisely to avoid drug resistance.",
    tips: "Cover mouth when coughing. Good ventilation. BCG vaccine for infants. Screen if exposed to active cases.",
  ),
  const Disease(
    name: "Chickenpox",
    what: "A highly contagious viral infection causing an itchy, blister-like rash on the skin.",
    why: "Varicella-zoster virus. Spreads via air or direct contact with blisters.",
    cure: "Symptomatic relief (calamine lotion, cool baths). Antivirals for high-risk groups.",
    tips: "Vaccination is 90% effective. Keep infected person isolated until blisters crust over. Don't scratch.",
  ),
  const Disease(
    name: "Pneumonia",
    what: "Infection that inflames air sacs in one or both lungs, which may fill with fluid.",
    why: "Bacteria, viruses, or fungi. Risk is higher in infants, elderly, and those with weak immunity.",
    cure: "Antibiotics for bacterial pneumonia. Rest and fluids for viral. Hospitalization if oxygen is low.",
    tips: "Vaccinate against pneumococcal pneumonia. Quit smoking. Practice good hygiene to prevent respiratory infections.",
  ),
  const Disease(
    name: "Conjunctivitis (Pink Eye)",
    what: "Inflammation or infection of the transparent membrane (conjunctiva) that lines your eyelid.",
    why: "Viruses, bacteria, or allergies. Highly contagious if viral or bacterial.",
    cure: "Antibiotic drops for bacterial. Viral clears on its own. Allergy drops for allergic type.",
    tips: "Don't touch eyes. Wash hands often. Use a clean towel. Don't share eye cosmetics.",
  ),
  const Disease(
    name: "Acne",
    what: "A skin condition that occurs when hair follicles become plugged with oil and dead skin cells.",
    why: "Excess oil production, clogged follicles, bacteria, inflammation. Hormonal changes often trigger it.",
    cure: "Topical creams (retinoids, benzoyl peroxide), oral antibiotics in severe cases.",
    tips: "Wash face twice daily. Don't pop pimples. Use non-comedogenic (oil-free) makeup and sunscreens.",
  ),
  const Disease(
    name: "Acid Reflux (GERD)",
    what: "Stomach acid frequently flows back into the tube connecting your mouth and stomach (esophagus).",
    why: "Weak lower esophageal sphincter. Triggers: spicy food, obesity, smoking, eating late.",
    cure: "Antacids, H2 blockers. Lifestyle changes are the primary long-term treatment.",
    tips: "Eat smaller meals. Avoid trigger foods. Don't lie down after eating. Raise head of bed.",
  ),
  const Disease(
    name: "Anemia",
    what: "A condition in which you lack enough healthy red blood cells to carry adequate oxygen.",
    why: "Iron deficiency is most common. Also vitamin deficiency or chronic diseases.",
    cure: "Iron supplements, vitamin B12 shots, or dietary changes. Treating the underlying cause.",
    tips: "Eat iron-rich foods (spinach, red meat, beans). Take Vitamin C to help absorption.",
  ),
  const Disease(
    name: "Urinary Tract Infection (UTI)",
    what: "An infection in any part of your urinary system — your kidneys, ureters, bladder and urethra.",
    why: "Bacteria (usually E. coli) enter the urinary tract. More common in women.",
    cure: "Antibiotics are the standard treatment. Symptoms usually improve within a few days.",
    tips: "Drink plenty of water. Wipe front to back. Empty bladder after intercourse. Avoid irritating products.",
  ),
];

class CommonDiseasesScreen extends StatelessWidget {
  const CommonDiseasesScreen({super.key});

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
                        AppTranslations.get('common_diseases', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF00A98F)),
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
                      itemCount: commonDiseases.length,
                      itemBuilder: (context, index) {
                        final disease = commonDiseases[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFFE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A98F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${index + 1}",
                                style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(
                              disease.name, 
                              style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.w600, fontSize: 15)
                            ),
                            subtitle: Text(
                              disease.what, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF64748B)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DiseaseDetailScreen(disease: disease, lang: lang)),
                              );
                            },
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

class DiseaseDetailScreen extends StatelessWidget {
  final Disease disease;
  final String lang;

  const DiseaseDetailScreen({super.key, required this.disease, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D2B28), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      disease.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0D2B28),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    children: [
                      // Warning Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800), size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                AppTranslations.get('disclaimer', lang),
                                style: GoogleFonts.poppins(color: const Color(0xFFE65100), fontSize: 11, fontWeight: FontWeight.w500, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSection(
                        title: AppTranslations.get('what_is_it', lang).toUpperCase(),
                        content: disease.what,
                        icon: Icons.info_outline_rounded,
                        color: const Color(0xFF3B82F6),
                      ),
                      _buildSection(
                        title: AppTranslations.get('why_it_happens', lang).toUpperCase(),
                        content: disease.why,
                        icon: Icons.help_outline_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                      _buildSection(
                        title: AppTranslations.get('cure_and_care', lang).toUpperCase(),
                        content: disease.cure,
                        icon: Icons.medical_services_outlined,
                        color: const Color(0xFF10B981),
                      ),
                      _buildSection(
                        title: AppTranslations.get('prevention_and_tips', lang).toUpperCase(),
                        content: disease.tips,
                        icon: Icons.lightbulb_outline_rounded,
                        color: const Color(0xFF8B5CF6),
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
  }

  Widget _buildSection({required String title, required String content, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: const Color(0xFF0D2B28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
