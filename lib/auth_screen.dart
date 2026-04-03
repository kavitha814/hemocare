import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'package:workmanager/workmanager.dart';

import 'package:flutter/foundation.dart';

import 'globals.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveBase64Image(String base64String, String username) async {
  if (kIsWeb) {
    return 'data:image/png;base64,$base64String';
  }

  final bytes = base64Decode(base64String);
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/user_profile_$username.png';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  
  await FileImage(file).evict();
  
  return filePath;
}

final String authBaseUrl = '$apiBaseUrl/auth';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSignIn() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Attempting login at: $authBaseUrl/login');
      final response = await http.post(
        Uri.parse('$authBaseUrl/login'),
        headers: apiHeaders,
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'fcmToken': (await SharedPreferences.getInstance()).getString('fcm_token'),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('profile_name', data['user']['username']);
        await prefs.setString('profile_email', data['user']['email']);
        
        final countResponse = await http.get(
          Uri.parse('$apiBaseUrl/blood-requests/count'),
          headers: {...apiHeaders, 'Authorization': 'Bearer ${data['token']}'},
        );
        if (countResponse.statusCode == 200) {
          final countData = jsonDecode(countResponse.body);
          await prefs.setInt('last_blood_request_count', countData['count'] ?? 0);
        }

        Workmanager().registerPeriodicTask(
          "blood_check_task",
          "checkBloodRequests",
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        
        if (data['user']['profileImage'] != null) {
          try {
             final imagePath = await saveBase64Image(data['user']['profileImage'], data['user']['username']);
             await prefs.setString('profile_image', imagePath);
             profileImageNotifier.value = imagePath;
          } catch(e) {
             print("Error saving image: $e");
          }
        } else {
           await prefs.remove('profile_image');
           profileImageNotifier.value = null;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['msg'] ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      print('LOGIN ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect to server: $e. Ensure backend is running.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              stackCircles(),
              const SizedBox(height: 32),
              Text(
                'CARECONNECT',
                style: GoogleFonts.poppins(
                  fontSize: 32, 
                  fontWeight: FontWeight.w400, 
                  color: const Color(0xFF0D2B28),
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'YOUR PERSONAL MEDICAL ASSISTANT',
                style: GoogleFonts.poppins(
                  fontSize: 12, 
                  fontWeight: FontWeight.w500, 
                  color: const Color(0xFF00A98F),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFFE),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A98F).withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign In',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24, 
                        fontWeight: FontWeight.w400, 
                        color: const Color(0xFF0D2B28),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    _buildLabel('IDENTITY'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Color(0xFF0D2B28)),
                      decoration: _inputDecoration('Email', Icons.email_outlined),
                    ),
                    const SizedBox(height: 32),

                    _buildLabel('ACCESS KEY'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Color(0xFF0D2B28)),
                      decoration: _inputDecoration('Password', Icons.lock_outline_rounded).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off, 
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A98F),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00A98F).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CONTINUE', 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w700, 
                                color: Colors.white,
                                letterSpacing: 1.0,
                              )
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "First time here? ", 
                    style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                    child: const Text(
                      'Register secure account', 
                      style: TextStyle(
                        color: Color(0xFF00A98F), 
                        fontWeight: FontWeight.w500,
                      )
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget stackCircles() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1), width: 1),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.2), width: 1),
            ),
          ),
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00A98F).withOpacity(0.12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A98F).withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.favorite, size: 32, color: Color(0xFF00A98F)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
    label, 
    style: GoogleFonts.poppins(
      fontWeight: FontWeight.w600, 
      color: const Color(0xFF64748B),
      fontSize: 12,
      letterSpacing: 1.5,
    )
  );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: const Color(0xFF00A98F)),
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), 
      borderSide: const BorderSide(color: Color(0xFFE2F7F5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), 
      borderSide: const BorderSide(color: Color(0xFFD1F0EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), 
      borderSide: const BorderSide(color: Color(0xFF00A98F)),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
  );
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSignUp() async {
    if (_fullNameController.text.isEmpty || _usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in required fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Attempting signup at: $authBaseUrl/register');
      final response = await http.post(
        Uri.parse('$authBaseUrl/register'),
        headers: apiHeaders,
        body: jsonEncode({
          'fullName': _fullNameController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'fcmToken': (await SharedPreferences.getInstance()).getString('fcm_token'),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_name', data['user']['username']);
        await prefs.setString('profile_email', data['user']['email']);

        await prefs.setInt('last_blood_request_count', 0);
        Workmanager().registerPeriodicTask(
          "blood_check_task",
          "checkBloodRequests",
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );

        if (data['user']['profileImage'] != null) {
          try {
             final imagePath = await saveBase64Image(data['user']['profileImage'], data['user']['username']);
             await prefs.setString('profile_image', imagePath);
             profileImageNotifier.value = imagePath;
          } catch(e) {
             print("Error saving image: $e");
          }
        } else {
           await prefs.remove('profile_image');
           profileImageNotifier.value = null;
        }

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg'] ?? 'Registration failed')));
        }
      }
    } catch (e) {
      print('SIGNUP ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect to server: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              stackCircles(),
              const SizedBox(height: 32),
              Text(
                'CARECONNECT',
                style: GoogleFonts.poppins(
                  fontSize: 32, 
                  fontWeight: FontWeight.w400, 
                  color: const Color(0xFF0D2B28),
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'YOUR PERSONAL MEDICAL ASSISTANT',
                style: GoogleFonts.poppins(
                  fontSize: 12, 
                  fontWeight: FontWeight.w500, 
                  color: const Color(0xFF00A98F),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFFE),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A98F).withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24, 
                        fontWeight: FontWeight.w400, 
                        color: const Color(0xFF0D2B28),
                      ),
                    ),
                    const SizedBox(height: 48),

                    _buildLabel('FULL NAME'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fullNameController,
                      style: const TextStyle(color: Color(0xFF0D2B28)),
                      decoration: _inputDecoration('Enter your name', Icons.person_outline),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('EMAIL'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Color(0xFF0D2B28)),
                      decoration: _inputDecoration('Enter your email', Icons.email_outlined),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('USERNAME'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Color(0xFF0D2B28)),
                      decoration: _inputDecoration('Enter your username', Icons.alternate_email_outlined),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('PASSWORD'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Color(0xFF0D2B28)),
                      decoration: _inputDecoration('Enter your password', Icons.lock_outline_rounded).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off, 
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A98F),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00A98F).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SIGN UP', 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w700, 
                                color: Colors.white,
                                letterSpacing: 1.0,
                              )
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ", 
                    style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In', 
                      style: TextStyle(
                        color: Color(0xFF00A98F), 
                        fontWeight: FontWeight.w500,
                      )
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget stackCircles() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1), width: 1),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.2), width: 1),
            ),
          ),
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00A98F).withOpacity(0.12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A98F).withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.favorite, size: 32, color: Color(0xFF00A98F)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
    label, 
    style: GoogleFonts.poppins(
      fontWeight: FontWeight.w600, 
      color: const Color(0xFF64748B),
      fontSize: 12,
      letterSpacing: 1.5,
    )
  );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: const Color(0xFF00A98F)),
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), 
      borderSide: const BorderSide(color: Color(0xFFE2F7F5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), 
      borderSide: const BorderSide(color: Color(0xFFD1F0EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), 
      borderSide: const BorderSide(color: Color(0xFF00A98F)),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
  );
}
