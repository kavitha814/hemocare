import 'package:flutter/material.dart';
import 'dart:io';
import 'globals.dart';

import 'emergency_screen.dart';

class UserProfileIcon extends StatelessWidget {
  final double radius;
  
  const UserProfileIcon({super.key, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: profileImageNotifier,
      builder: (context, imagePath, _) {
        return GestureDetector(
          onTap: () {
            homeTabNotifier.value = 3;
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A98F).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: const Color(0xFFF0FFFE),
              backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
              child: imagePath == null 
                 ? Icon(Icons.person, color: const Color(0xFF0D2B28), size: radius * 1.2)
                 : null,
            ),
          ),
        );
      },
    );
  }
}

final ValueNotifier<int> bloodRequestCountNotifier = ValueNotifier<int>(0);

class EmergencyHelpIcon extends StatelessWidget {
  const EmergencyHelpIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmergencyScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(
          Icons.sos_rounded,
          color: Color(0xFFEF5350), // Emergency Red
          size: 28,
        ),
      ),
    );
  }
}
