import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart';
import 'translations.dart';

class VaccineInfo {
  final String ageGroup;
  final String vaccineName;
  final String what;
  final String why;
  final String how;
  final String category; // Simplified category for UI (Polio, TB, etc.)

  const VaccineInfo({
    required this.ageGroup,
    required this.vaccineName,
    required this.what,
    required this.why,
    required this.how,
    this.category = "",
  });
}

final List<VaccineInfo> vaccines = [
  // BIRTH
  const VaccineInfo(
    ageGroup: "At Birth",
    vaccineName: "BCG",
    category: "Tuberculosis (TB)",
    what: "Tuberculosis (TB)",
    why: "Prevents severe forms of TB like meningitis.",
    how: "Injection usually given in the upper left arm.",
  ),
  const VaccineInfo(
    ageGroup: "At Birth",
    vaccineName: "OPV 0",
    category: "Polio",
    what: "Polio",
    why: "Oral drops to protect against Polio virus paralysis.",
    how: "Two drops given orally.",
  ),
  const VaccineInfo(
    ageGroup: "At Birth",
    vaccineName: "Hep B",
    category: "Hepatitis B",
    what: "Hepatitis B",
    why: "Prevents liver infection and liver cancer.",
    how: "Injection given in the thigh muscle.",
  ),

  // 6 WEEKS
  const VaccineInfo(
    ageGroup: "6 Weeks",
    vaccineName: "Pentavalent 1",
    category: "Diphtheria, Tetanus, etc.",
    what: "Diphtheria, Tetanus, etc.",
    why: "Combination vaccine for 5 killer diseases.",
    how: "Injection given in the thigh.",
  ),
  const VaccineInfo(
    ageGroup: "6 Weeks",
    vaccineName: "Rotavirus 1",
    category: "Diarrhea",
    what: "Rotavirus",
    why: "Prevents severe diarrhea and dehydration.",
    how: "Oral drops.",
  ),
  const VaccineInfo(
    ageGroup: "6 Weeks",
    vaccineName: "fIPV 1",
    category: "Polio",
    what: "Polio (Fractional Inactivated Polio Vaccine)",
    why: "Injectable polio vaccine for enhanced immunity.",
    how: "Intradermal injection.",
  ),

  // 10 WEEKS
  const VaccineInfo(
    ageGroup: "10 Weeks",
    vaccineName: "Pentavalent 2",
    category: "Diphtheria, Tetanus, etc.",
    what: "Second dose of combination vaccine.",
    why: "Boosts protection against 5 diseases.",
    how: "Injection.",
  ),

  // 14 WEEKS
  const VaccineInfo(
    ageGroup: "14 Weeks",
    vaccineName: "Pentavalent 3",
    category: "Diphtheria, Tetanus, etc.",
    what: "Third dose of combination vaccine.",
    why: "Completes primary series for 5 diseases.",
    how: "Injection.",
  ),

  // 9 MONTHS
  const VaccineInfo(
    ageGroup: "9 Months",
    vaccineName: "MR 1",
    category: "Measles & Rubella",
    what: "Measles and Rubella",
    why: "Prevents measles and maternal rubella transmission.",
    how: "Injection.",
  ),

  // 1 YEAR+
  const VaccineInfo(
    ageGroup: "1 Year",
    vaccineName: "DPT Booster 1",
    category: "Diphtheria, Pertussis, Tetanus",
    what: "Boosters",
    why: "Maintains immunity through early childhood.",
    how: "Injection.",
  ),

  // CHILDREN
  const VaccineInfo(
    ageGroup: "16-24 Months",
    vaccineName: "DPT Booster - 1",
    category: "Boosters",
    what: "Diphtheria, Pertussis, and Tetanus booster.",
    why: "Maintains immunity levels.",
    how: "Injection.",
  ),
  const VaccineInfo(
    ageGroup: "5-6 Years",
    vaccineName: "DPT Booster - 2",
    category: "Boosters",
    what: "Second booster for Diphtheria, Pertussis, and Tetanus.",
    why: "Ensures long-term protection.",
    how: "Injection.",
  ),

  // ADOLESCENTS
  const VaccineInfo(
    ageGroup: "9-14 Years",
    vaccineName: "HPV",
    category: "Cancer Prevention",
    what: "Human Papillomavirus vaccine.",
    why: "Prevents cervical cancer and other diseases.",
    how: "Injection series.",
  ),
  const VaccineInfo(
    ageGroup: "10-16 Years",
    vaccineName: "Td Booster",
    category: "Boosters",
    what: "Tetanus and Diphtheria booster.",
    why: "Maintains immunity through adolescence.",
    how: "Injection.",
  ),

  // ADULTS
  const VaccineInfo(
    ageGroup: "Adults",
    vaccineName: "Influenza (Flu Shot)",
    category: "Seasonal",
    what: "Yearly flu vaccine.",
    why: "Prevents seasonal flu and complications.",
    how: "Annual injection.",
  ),
  const VaccineInfo(
    ageGroup: "Adults",
    vaccineName: "Tdap Booster",
    category: "Boosters",
    what: "Tetanus, Diphtheria, and Pertussis booster.",
    why: "Boosters needed every 10 years.",
    how: "Injection.",
  ),
  const VaccineInfo(
    ageGroup: "Adults",
    vaccineName: "Hepatitis B (Adult)",
    category: "Liver Health",
    what: "3-dose series for adults.",
    why: "Protects against Hepatitis B.",
    how: "Injection.",
  ),

  // SENIORS
  const VaccineInfo(
    ageGroup: "Seniors (65+)",
    vaccineName: "Pneumococcal",
    category: "Pneumonia",
    what: "Vaccine against Streptococcus pneumoniae.",
    why: "Prevents pneumonia and meningitis.",
    how: "Injection.",
  ),
  const VaccineInfo(
    ageGroup: "Seniors (50+)",
    vaccineName: "Shingles",
    category: "Nerve Health",
    what: "Herpes Zoster vaccine.",
    why: "Prevents painful shingles rash.",
    how: "Injection.",
  ),
];

class VaccinationScheduleScreen extends StatefulWidget {
  const VaccinationScheduleScreen({super.key});

  @override
  State<VaccinationScheduleScreen> createState() => _VaccinationScheduleScreenState();
}

class _VaccinationScheduleScreenState extends State<VaccinationScheduleScreen> {
  Map<String, bool> _completedVaccines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/vaccinations'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<String, bool> progress = {};
        for (var item in data) {
          progress[item['vaccineName']] = item['isCompleted'];
        }
        setState(() {
          _completedVaccines = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching vaccination progress: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVaccine(String vaccineName, bool isCompleted) async {
    // Local update first for responsiveness
    setState(() {
      _completedVaccines[vaccineName] = isCompleted;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    try {
      await http.post(
        Uri.parse('$apiBaseUrl/vaccinations/toggle'),
        headers: {
          ...apiHeaders,
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vaccineName': vaccineName,
          'isCompleted': isCompleted,
        }),
      );
    } catch (e) {
      debugPrint("Error toggling vaccine: $e");
    }
  }

  double _calculateProgress() {
    if (vaccines.isEmpty) return 0.0;
    int completed = _completedVaccines.values.where((v) => v).length;
    return (completed / vaccines.length);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        double progress = _calculateProgress();
        int completedCount = _completedVaccines.values.where((v) => v).length;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(lang),
                _buildProgressHeader(progress, completedCount),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A98F)))
                    : _buildTimeline(lang),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D2B28), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.child_care_rounded, color: Color(0xFF00A98F), size: 24),
          const SizedBox(width: 8),
          Text(
            "VACCINATION SCHEDULE",
            style: GoogleFonts.poppins(
              color: const Color(0xFF0D2B28),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(double progress, int completedCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(progress * 100).toInt()}% Completed",
                style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                "$completedCount/${vaccines.length} Vaccines",
                style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFD1F0EC),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A98F)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String lang) {
    // Group vaccines by ageGroup
    Map<String, List<VaccineInfo>> grouped = {};
    for (var v in vaccines) {
      grouped.putIfAbsent(v.ageGroup, () => []).add(v);
    }

    List<String> sortedGroups = [
      "At Birth", 
      "6 Weeks", 
      "10 Weeks", 
      "14 Weeks", 
      "9 Months", 
      "1 Year",
      "16-24 Months",
      "5-6 Years",
      "9-14 Years",
      "10-16 Years",
      "Adults",
      "Seniors (50+)",
      "Seniors (65+)",
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: sortedGroups.length,
      itemBuilder: (context, index) {
        String group = sortedGroups[index];
        if (!grouped.containsKey(group)) return const SizedBox.shrink();
        
        return _buildTimelineGroup(group, grouped[group]!, index == sortedGroups.length - 1);
      },
    );
  }

  Widget _buildTimelineGroup(String age, List<VaccineInfo> groupVaccines, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: const Color(0xFF00A98F),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF00A98F).withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A98F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    age,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ...groupVaccines.map((v) => _buildVaccineItem(v)).toList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineItem(VaccineInfo v) {
    bool isCompleted = _completedVaccines[v.vaccineName] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleVaccine(v.vaccineName, !isCompleted),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF00A98F) : const Color(0xFFEEFBFA),
                    border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.3)),
                  ),
                  child: isCompleted 
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  v.vaccineName,
                  style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (v.category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    v.category,
                    style: GoogleFonts.poppins(color: const Color(0xFF0D2B28).withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Prevents:", v.what),
          const SizedBox(height: 4),
          _buildInfoRow("Uses:", v.why),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 11),
          ),
        ),
      ],
    );
  }
}
