import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'globals.dart';
import 'translations.dart';

class Habit {
  final String title;
  final String description;
  final IconData icon;

  const Habit({required this.title, required this.description, required this.icon});
}

final List<Habit> habits = [
  const Habit(title: "Drink Water", description: "Drink at least 8 glasses (2-3 liters) of water daily to stay hydrated and flush toxins.", icon: Icons.local_drink),
  const Habit(title: "Balanced Diet", description: "Eat a mix of fruits, vegetables, proteins, and whole grains. Avoid processed foods.", icon: Icons.restaurant),
  const Habit(title: "Regular Sleep", description: "Aim for 7-9 hours of quality sleep every night to repair your body and mind.", icon: Icons.bed),
  const Habit(title: "Daily Exercise", description: "Engage in at least 30 minutes of moderate activity like walking or jogging daily.", icon: Icons.directions_run),
  const Habit(title: "Hand Hygiene", description: "Wash hands properly with soap for 20 seconds before eating and after using the restroom.", icon: Icons.wash),
  const Habit(title: "Mental Break", description: "Take 5-10 minutes to meditate or practice deep breathing to reduce stress.", icon: Icons.self_improvement),
  const Habit(title: "Morning Sunlight", description: "Get 15 mins of morning sun for Vitamin D, which boosts immunity and bone health.", icon: Icons.wb_sunny),
  const Habit(title: "Limit Sugar", description: "Reduce intake of sugary drinks and snacks to prevent obesity and diabetes risks.", icon: Icons.no_food),
  const Habit(title: "Oral Care", description: "Brush teeth twice a day and floss daily to prevent gum disease and cavities.", icon: Icons.cleaning_services),
  const Habit(title: "Eye Rest", description: "Follow the 20-20-20 rule: Every 20 mins, look at something 20 feet away for 20 secs.", icon: Icons.visibility),
  const Habit(title: "Good Posture", description: "Sit straight with back support. Avoid hunching over phones or laptops for long periods.", icon: Icons.accessibility_new),
  const Habit(title: "Read Daily", description: "Stimulate your brain by reading a book or article for 15-30 minutes daily.", icon: Icons.book),
  const Habit(title: "Social Connection", description: "Talk to a friend or family member daily. Social bonds boost mental health.", icon: Icons.people),
  const Habit(title: "Limit Screen Time", description: "Avoid screens 1 hour before bed to improve sleep quality.", icon: Icons.phone_android),
  const Habit(title: "No Smoking", description: "Avoid smoking and secondhand smoke to protect your lungs and heart.", icon: Icons.smoke_free),
  const Habit(title: "Limit Alcohol", description: "Drink in moderation or not at all. Excessive alcohol harms the liver and brain.", icon: Icons.wine_bar),
  const Habit(title: "Stretching", description: "Stretch your muscles after waking up or sitting for long to improve flexibility.", icon: Icons.sports_gymnastics),
  const Habit(title: "Eat Slowly", description: "Chew food thoroughly and eat slowly to aid digestion and prevent overeating.", icon: Icons.timelapse),
  const Habit(title: "Gratitude", description: "Write down 3 things you are grateful for daily to improve emotional well-being.", icon: Icons.edit_note),
  const Habit(title: "Health Checkups", description: "Schedule annual checkups to catch potential issues early.", icon: Icons.medical_services),
  const Habit(title: "Stair Climbing", description: "Take stairs instead of elevators whenever possible for extra cardio.", icon: Icons.stairs),
];

class HealthyHabitsScreen extends StatelessWidget {
  const HealthyHabitsScreen({super.key});

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
                        AppTranslations.get('healthy_habits', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.spa_rounded, color: Color(0xFF00A98F)),
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
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFFE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A98F).withOpacity(0.1), 
                                  borderRadius: BorderRadius.circular(16)
                                ),
                                child: Icon(habit.icon, color: const Color(0xFF00A98F), size: 28),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.title, 
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF0D2B28))
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      habit.description, 
                                      style: GoogleFonts.poppins(color: const Color(0xFF64748B), height: 1.5, fontSize: 12)
                                    ),
                                  ],
                                ),
                              )
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
