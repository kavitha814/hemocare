import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart'; 
import 'home_screen.dart';
import 'notification_service.dart';
import 'auth_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const String bloodRequestTask = "checkBloodRequests";

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // If you want to show a local notification even when data-only message is sent
  if (message.notification == null && message.data.isNotEmpty) {
      final ns = NotificationService();
      await ns.init();
      await ns.showInstantNotification(
        id: 111,
        title: message.data['title'] ?? 'CareConnect Alert',
        body: message.data['body'] ?? 'You have a new update.',
      );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case bloodRequestTask:
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token == null) {
             debugPrint("Background Task: No auth token found. Skipping.");
             return true;
          }

          debugPrint("Background Task: Checking for blood requests...");

          final response = await http.get(
            Uri.parse('$apiBaseUrl/blood-requests/count'),
            headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final int newCount = data['count'] ?? 0;
            final int lastCount = prefs.getInt('last_blood_request_count') ?? 0;

            debugPrint("Background Task: New Count: $newCount, Last Count: $lastCount");

            if (newCount > lastCount) {
              final ns = NotificationService();
              await ns.init();
              await ns.showInstantNotification(
                id: 999,
                title: "New Blood Request",
                body: "Someone needs your blood group! Check the Request Hub.",
              );
              await prefs.setInt('last_blood_request_count', newCount);
              debugPrint("Background Task: Notification triggered.");
            } else {
              await prefs.setInt('last_blood_request_count', newCount);
            }
          } else {
            debugPrint("Background Task: API Error ${response.statusCode}");
          }
        } catch (e) {
          debugPrint("Background Task Error: $e");
        }
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request notification permissions for FCM
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM Token
    String? tokenFCM = await messaging.getToken();
    if (tokenFCM != null) {
      debugPrint("FCM Token: $tokenFCM");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', tokenFCM);
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Initialize notifications
  final ns = NotificationService();
  await ns.init();
  await ns.requestPermissions(); // Added to ensure Android 13+ permissions are granted

  // Handle Foreground FCM Messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("Received a foreground message: ${message.messageId}");
    if (message.notification != null) {
      ns.showInstantNotification(
        id: (message.messageId.hashCode),
        title: message.notification!.title ?? "Alert",
        body: message.notification!.body ?? "",
      );
    }
  });

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Turned off to stop debug notifications
  );
  
  final prefs = await SharedPreferences.getInstance();
  
  // Force white/light theme always
  themeNotifier.value = ThemeMode.light;
  
  final lang = prefs.getString('app_language') ?? 'English';
  languageNotifier.value = lang;
  
  final img = prefs.getString('profile_image');
  profileImageNotifier.value = img;

  // Check if user is already logged in
  final token = prefs.getString('auth_token');

  if (token != null) {
    Workmanager().registerPeriodicTask(
      "blood_check_task",
      bloodRequestTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  } else {
    Workmanager().cancelByUniqueName("blood_check_task");
  }

  // Explicitly cancel the old outbreak task from the system memory
  Workmanager().cancelByUniqueName("outbreak_check_periodic");

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CareConnect',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00A98F),
              primary: const Color(0xFF00A98F),
              brightness: Brightness.light,
              surface: Colors.white,
              onSurface: const Color(0xFF0D2B28),
            ),
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.poppinsTextTheme(),
            brightness: Brightness.light,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0D2B28),
              elevation: 0,
            ),
            dialogBackgroundColor: Colors.white,
            cardColor: const Color(0xFFF0FFFE),
            dividerColor: const Color(0xFFE2F7F5),
          ),
          darkTheme: ThemeData(
             useMaterial3: true,
             brightness: Brightness.light,
             colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A98F), brightness: Brightness.light),
             textTheme: GoogleFonts.poppinsTextTheme(),
             scaffoldBackgroundColor: Colors.white,
          ),
          themeMode: ThemeMode.light,
          home: isLoggedIn ? const HomeScreen() : const SignInScreen(),
        );
      },
    );
  }
}
