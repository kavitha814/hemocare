import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'globals.dart'; 
import 'translations.dart';
import 'auth_screen.dart';
import 'package:antigravity/contact_support_screen.dart';
import 'chat_history_screen.dart';
import 'medicine_reminder_screen.dart';
import 'diseases_screen.dart';
import 'emergency_screen.dart';
import 'user_profile_icon.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Config
  final ImagePicker _picker = ImagePicker();
  
  // State
  String? _imagePath;
  bool _isEditing = false;
  bool _isLoadingData = true;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _bloodGroup = 'A+';

  // Prefs
  String _language = 'English';
  List<dynamic> _chatHistory = [];
  bool _isLoadingHistory = true;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _fetchProfile();
    _fetchChatHistory();
  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('profile_name') ?? '';
        _emailController.text = prefs.getString('profile_email') ?? '';
        _phoneController.text = prefs.getString('profile_phone') ?? '';
        _bloodGroup = prefs.getString('profile_blood') ?? 'A+';
        _imagePath = prefs.getString('profile_image');
      });
    }
  }

  Future<void> _fetchChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/chats'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _chatHistory = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching chat history: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      setState(() => _isLoadingData = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/auth/profile'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? downloadedImagePath;
        if (data['profileImage'] != null) {
           try {
              // Pass unique username to save function
              downloadedImagePath = await saveBase64Image(data['profileImage'], data['username'] ?? _nameController.text);
              await prefs.setString('profile_image', downloadedImagePath);
              profileImageNotifier.value = downloadedImagePath;
           } catch(e) {
              debugPrint("Error saving image: $e");
           }
        }

        setState(() {
          _nameController.text = data['fullName'] ?? data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _bloodGroup = data['bloodGroup'] ?? 'A+';
          
          if (downloadedImagePath != null) {
              _imagePath = downloadedImagePath;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      final lang = prefs.getString('app_language') ?? 'English';
      final img = prefs.getString('profile_image');
      setState(() {
        _language = lang;
        _imagePath = img;
        _isLoadingData = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    setState(() => _isLoadingData = true);

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/auth/profile'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'bloodGroup': _bloodGroup,
          'profileImage': _imagePath != null ? base64Encode(await XFile(_imagePath!).readAsBytes()) : null,
        }),
      );

      if (response.statusCode == 200) {
        // Also update local prefs for quick access if needed elsewhere
        await prefs.setString('profile_name', _nameController.text);
        await prefs.setString('profile_email', _emailController.text);
        await prefs.setString('profile_phone', _phoneController.text);
        await prefs.setString('profile_blood', _bloodGroup);

        if (_imagePath != null) {
          await prefs.setString('profile_image', _imagePath!);
          profileImageNotifier.value = _imagePath;
        }

        setState(() => _isEditing = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        debugPrint("Profile Update Failed: ${response.statusCode} - ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response.statusCode} - ${response.body}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
      _saveProfile(); // Auto-save image change (this will now also push other fields to server)
    }
  }

  // --- Setting Handlers ---



  Future<void> _changeLanguage(String? newValue) async {
    if (newValue == null || languageNotifier.value == newValue) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newValue);
    languageNotifier.value = newValue;
    
    // Also update local state if needed for other logic, but lang builder handles UI
    setState(() => _language = newValue);
  }

  Future<void> _logout() async {
    final lang = languageNotifier.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppTranslations.get('logout_confirm_title', lang),
          style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          AppTranslations.get('logout_confirm_msg', lang),
          style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.get('cancel', lang).toUpperCase(),
              style: GoogleFonts.poppins(color: const Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              AppTranslations.get('logout_action', lang).toUpperCase(),
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('profile_image'); // Clear local path reference
      profileImageNotifier.value = null; // Clear from UI

      
      if (mounted) {
         Navigator.of(context).pushAndRemoveUntil(
           MaterialPageRoute(builder: (context) => const SignInScreen()),
           (route) => false,
         );
      }
  }

  Future<void> _deleteAccount() async {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                "Delete Account?",
                style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This action is permanent and cannot be undone. All your data will be wiped from our servers.",
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Text(
                "ENTER PASSWORD TO CONFIRM:",
                style: GoogleFonts.poppins(color: const Color(0xFF475569), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFFE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: isDeleting ? null : () => Navigator.pop(context),
                    child: Text(
                      "CANCEL",
                      maxLines: 1,
                      style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.redAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      ),
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                if (passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please enter your password")),
                                  );
                                  return;
                                }

                                setDialogState(() => isDeleting = true);

                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString('auth_token');

                                  final response = await http.delete(
                                    Uri.parse('$apiBaseUrl/auth/'),
                                    headers: {
                                      ...apiHeaders,
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: jsonEncode({'password': passwordController.text}),
                                  );

                                  if (response.statusCode == 200) {
                                    if (mounted) {
                                      Navigator.pop(context); // Close dialog
                                      _logout(); // Log out and redirect
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Account deleted successfully"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } else {
                                    final error = jsonDecode(response.body);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(error['msg'] ?? "Failed to delete account"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                   if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                                      );
                                   }
                                } finally {
                                  if (mounted) setDialogState(() => isDeleting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isDeleting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("DELETE ACCOUNT", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D2B28), size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 48), // Match IconButton width for centering
                      const SizedBox(width: 12),
                      Text(
                        AppTranslations.get('my_profile_title', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      const EmergencyHelpIcon(),
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
                          // Avatar
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.5), width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundColor: const Color(0xFFEEFBFA),
                                    backgroundImage: _imagePath != null 
                                        ? (kIsWeb ? NetworkImage(_imagePath!) : FileImage(File(_imagePath!)) as ImageProvider)
                                        : null,
                                    child: _imagePath == null 
                                        ? Text(
                                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "U", 
                                            style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w600, color: const Color(0xFF00A98F))
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A98F),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black45, blurRadius: 8)
                                        ]
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Personal Info
                          _buildSectionCard(
                            title: AppTranslations.get('personal_info', lang).toUpperCase(),
                            trailing: GestureDetector(
                              onTap: () {
                                if (_isEditing) {
                                  _saveProfile();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              child: Text(
                                _isEditing ? "SAVE" : "EDIT",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF00A98F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTextField("Full Name", _nameController, Icons.person_outline_rounded),
                                const SizedBox(height: 16),
                                _buildTextField("Email Address", _emailController, Icons.email_outlined),
                                const SizedBox(height: 16),
                                _buildTextField("Phone Number", _phoneController, Icons.phone_outlined),
                                const SizedBox(height: 16),
                                _buildDropdown("Blood Group", _bloodGroup, _bloodGroups, (val) => setState(() => _bloodGroup = val!)),
                                const SizedBox(height: 24),
                                if (_isEditing)
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(colors: [Color(0xFF00A98F), Color(0xFF00D1C1)]),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: Text("SAVE CHANGES", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 1)),
                                    ),
                                  )
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Preferences
                          _buildSectionCard(
                            title: AppTranslations.get('preferences', lang).toUpperCase(),
                            child: Column(
                              children: [
                                _buildSettingRow(
                                  AppTranslations.get('app_language', lang), 
                                  Icons.translate_rounded, 
                                  const Color(0xFF3B82F6),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: lang,
                                      dropdownColor: Colors.white,
                                      style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
                                      items: ['English', 'Tamil', 'Hindi', 'Malayalam', 'Telugu', 'Kannada'].map((String val) {
                                        return DropdownMenuItem<String>(value: val, child: Text(val));
                                      }).toList(),
                                      onChanged: _changeLanguage,
                                    ),
                                  )
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Chat History
                          _buildSectionCard(
                            title: AppTranslations.get('recent_chat_history', lang).toUpperCase(), 
                            trailing: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ChatHistoryScreen())),
                              child: Text(
                                AppTranslations.get('view_all', lang).toUpperCase(), 
                                style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontSize: 11, fontWeight: FontWeight.w700)
                              ),
                            ),
                            child: _isLoadingHistory 
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D1C1)))
                            : Center(
                                child: Text(
                                  AppTranslations.get('view_history_desc', lang), // Note: need to add this translation too or just use simple text
                                  style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 13),
                                ),
                              ),
                          ),


                          const SizedBox(height: 24),

                          // Quick Actions
                          _buildSectionCard(
                            title: AppTranslations.get('quick_actions', lang).toUpperCase(),
                            child: Column(
                              children: [
                                _buildActionTile(AppTranslations.get('medicine_reminder', lang), Icons.notifications_active_rounded, const Color(0xFFA855F7), () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => const MedicineReminderScreen()));
                                }),
                                Divider(height: 24, color: Colors.white.withOpacity(0.05)),
                                _buildActionTile(AppTranslations.get('health_info', lang), Icons.coronavirus_outlined, const Color(0xFF00D1C1), () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => const DiseasesScreen()));
                                }),
                                Divider(height: 24, color: Colors.white.withOpacity(0.05)),
                                _buildActionTile(AppTranslations.get('emergency_help', lang), Icons.report_problem_outlined, const Color(0xFFEF5350), () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => const EmergencyScreen()));
                                }),
                                Divider(height: 24, color: Colors.white.withOpacity(0.05)),
                                _buildActionTile(AppTranslations.get('contact_support', lang), Icons.support_agent_rounded, const Color(0xFF06B6D4), () {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ContactSupportScreen()));
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Footer Buttons
                          _buildFooterButton(
                            icon: Icons.logout_rounded,
                            label: AppTranslations.get('logout', lang).toUpperCase(),
                            color: const Color(0xFF64748B),
                            onTap: _logout,
                          ),
                          const SizedBox(height: 12),
                          _buildFooterButton(
                            icon: Icons.delete_forever_rounded,
                            label: AppTranslations.get('delete_account', lang).toUpperCase(),
                            color: Colors.redAccent,
                            onTap: _deleteAccount,
                            isOutlined: true,
                          ),
                          const SizedBox(height: 40),
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
              color: const Color(0xFF00A98F).withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D1C1).withOpacity(0.4),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Icon(Icons.favorite, size: 16, color: Color(0xFF00A98F)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
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
          if (title.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
          ],
          child
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: _isEditing ? const Color(0xFFEEFBFA) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isEditing ? const Color(0xFF00A98F).withOpacity(0.3) : const Color(0xFFD1F0EC)),
      ),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFF00A98F), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _isEditing ? const Color(0xFFEEFBFA) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isEditing ? const Color(0xFF00A98F).withOpacity(0.3) : const Color(0xFFD1F0EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00A98F)),
              style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
              items: items.map((e) => DropdownMenuItem(
                value: e, 
                child: Text(e, style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14))
              )).toList(),
              onChanged: _isEditing ? onChanged : null,
              disabledHint: Text(value, style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String title, IconData icon, Color color, Widget trailing) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Text(title, style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        trailing,
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(title, style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF475569)),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon, 
    required String label, 
    required Color color, 
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label, 
              style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13)
            ),
          ],
        ),
      ),
    );
  }
}
