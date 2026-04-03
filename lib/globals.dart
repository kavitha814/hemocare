import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// GLOBAL NOTIFIERS
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<String> languageNotifier = ValueNotifier('English');
final ValueNotifier<String?> profileImageNotifier = ValueNotifier(null);
final ValueNotifier<int> homeTabNotifier = ValueNotifier(0);

// API CONFIGURATION
// 1. For Web: Use http://127.0.0.1:5000
// 2. For Android Emulator: Use http://10.0.2.2:5000
// 3. For Real Android Device: Use your Host IP (e.g. 192.168.137.220)
// 4. For ngrok: Paste your ngrok URL here (e.g. https://xxxx.ngrok-free.app)
// PRODUCTIONS URL (Update this after Render deployment)
const String? liveUrl = 'https://commendably-shortish-verla.ngrok-free.dev'; 

final String apiBaseUrl = liveUrl != null 
    ? '$liveUrl/api'
    : (kIsWeb 
        ? 'http://127.0.0.1:5000/api' 
        : 'http://10.24.22.139:5000/api'); 

final String authBaseUrl = '$apiBaseUrl/auth';
final String contactsBaseUrl = '$apiBaseUrl/contacts';

// API HEADERS (Bypasses ngrok warning)
final Map<String, String> apiHeaders = {
  'Content-Type': 'application/json',
  'ngrok-skip-browser-warning': '69420',
};
