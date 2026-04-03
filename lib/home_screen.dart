import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'hospital_screen.dart';
import 'profile_screen.dart';
import 'globals.dart';
import 'translations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  // Pages: Home Dashboard (0), Chat (1), Hospitals (2), Profile (3)
  final List<Widget> _pages = const [
    DashboardScreen(),
    ChatScreen(),
    HospitalScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    homeTabNotifier.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (homeTabNotifier.value != _currentIndex) {
      _pageController.animateToPage(homeTabNotifier.value, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    homeTabNotifier.removeListener(_onTabChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() { _currentIndex = index; homeTabNotifier.value = index; });
        },
        children: _pages,
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: homeTabNotifier,
        builder: (context, currentTab, _) => ValueListenableBuilder<String>(
          valueListenable: languageNotifier,
          builder: (context, lang, _) => BottomNavigationBar(
            currentIndex: currentTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF00A98F),
            unselectedItemColor: const Color(0xFFB0BEC5),
            showUnselectedLabels: true,
            selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_rounded), label: 'HOME'),
              BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_rounded), label: AppTranslations.get('chat', lang).toUpperCase()),
              BottomNavigationBarItem(icon: const Icon(Icons.add_box_outlined), label: AppTranslations.get('hospitals', lang).toUpperCase()),
              BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), label: AppTranslations.get('profile', lang).toUpperCase()),
            ],
            onTap: (index) => homeTabNotifier.value = index,
          ),
        ),
      ),
    );
  }
}
