import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart';
import 'translations.dart';

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({super.key});

  @override
  State<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isInterested = true;
  bool _isLoading = false;
  bool _isAlreadyRegistered = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedBloodGroup;
  DateTime? _dob;
  DateTime? _lastDonation;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkRegistrationStatus();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/auth/profile'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          if (_bloodGroups.contains(data['bloodGroup'])) {
            _selectedBloodGroup = data['bloodGroup'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/donors/check'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isRegistered'] == true) {
          setState(() {
            _isAlreadyRegistered = true;
            // Optionally fill fields with existing donor data
            final donor = data['donor'];
            _locationController.text = donor['location'] ?? '';
            _selectedBloodGroup = donor['bloodGroup'];
            if (donor['dob'] != null) _dob = DateTime.parse(donor['dob']);
            if (donor['lastDonation'] != null) _lastDonation = DateTime.parse(donor['lastDonation']);
            _isInterested = donor['isInterested'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking registration status: $e');
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null || _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select blood group and date of birth')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/donors'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': _nameController.text,
          'location': _locationController.text,
          'bloodGroup': _selectedBloodGroup,
          'dob': _dob!.toIso8601String(),
          'lastDonation': _lastDonation?.toIso8601String(),
          'isInterested': _isInterested,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['msg'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('$apiBaseUrl/donors'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'location': _locationController.text,
          'lastDonation': _lastDonation?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['msg'] ?? 'Update failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeRegistration() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/donors'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _isAlreadyRegistered = false;
          _locationController.clear();
          _lastDonation = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donor status revoked successfully')),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['msg'] ?? 'Revoke failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRevokeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Revoke Donor Status',
          style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to stop being a donor? Your information will be removed from our records.',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL', 
              maxLines: 1,
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _revokeRegistration();
            },
            child: Text(
              'CONFIRM REVOKE',
              style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Registration Successful',
          style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Thank you for registering as a blood donor. You are now a hero!',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Blood Screen
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDOB) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A98F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0D2B28),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF00A98F)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDOB) {
          _dob = picked;
        } else {
          _lastDonation = picked;
        }
      });
    }
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
                // Sub-page Header
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
                        AppTranslations.get('register_donor_title', lang),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Form
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Interest Toggle Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FFFE),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _isInterested,
                                    activeColor: const Color(0xFF00A98F),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => setState(() => _isInterested = val!),
                                  ),
                                  Expanded(
                                    child: Text(
                                      AppTranslations.get('donor_interest_label', lang),
                                      style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            _buildLabel(AppTranslations.get('full_name_label', lang)),
                            _buildTextField(
                              controller: _nameController,
                              hint: AppTranslations.get('enter_full_name', lang),
                              enabled: !_isAlreadyRegistered,
                            ),
                            const SizedBox(height: 24),

                            _buildLabel(AppTranslations.get('location_label', lang)),
                            _buildTextField(
                              controller: _locationController,
                              hint: AppTranslations.get('enter_city_name', lang),
                              icon: Icons.location_on,
                            ),
                            const SizedBox(height: 24),

                            _buildLabel(AppTranslations.get('blood_group', lang)),
                            _buildDropdown(
                              lang: lang,
                              items: _bloodGroups,
                              value: _selectedBloodGroup,
                              enabled: !_isAlreadyRegistered,
                              onChanged: _isAlreadyRegistered ? null : (val) => setState(() => _selectedBloodGroup = val),
                            ),
                            const SizedBox(height: 24),

                            _buildLabel(AppTranslations.get('dob_label', lang)),
                            _buildDatePicker(
                              context: context,
                              value: _dob,
                              enabled: !_isAlreadyRegistered,
                              onTap: _isAlreadyRegistered ? () {} : () => _selectDate(context, true),
                            ),
                            const SizedBox(height: 24),

                            _buildLabel(AppTranslations.get('last_donation_label', lang)),
                            _buildDatePicker(
                              context: context,
                              value: _lastDonation,
                              onTap: () => _selectDate(context, false),
                              hint: AppTranslations.get('first_time_hint', lang),
                            ),
                            
                            const SizedBox(height: 48),

                            // Submit/Update Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00A98F), Color(0xFF00D1C1)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00A98F).withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : (_isAlreadyRegistered ? _updateRegistration : _submitRegistration),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      _isAlreadyRegistered 
                                        ? 'UPDATE PROFILE'
                                        : AppTranslations.get('complete_registration', lang).toUpperCase(),
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 1),
                                    ),
                              ),
                            ),

                            if (_isAlreadyRegistered) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _showRevokeDialog,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: Text(
                                    'REVOKE DONOR STATUS',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, letterSpacing: 1),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, IconData? icon, bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF00A98F), size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String lang, required List<String> items, required String? value, required Function(String?)? onChanged, bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          hint: Text(AppTranslations.get('select_blood_group', lang), style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: enabled ? const Color(0xFF64748B) : Colors.white24),
          style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0D2B28),
                    fontSize: 14,
                  ),
                ),
              );
            }).toList();
          },
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildDatePicker({required BuildContext context, required DateTime? value, required VoidCallback onTap, String? hint, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFFE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
            ),
            child: Text(
              value != null ? DateFormat('dd/MM/yyyy').format(value) : (hint ?? ""),
              style: GoogleFonts.poppins(
                color: value != null ? (enabled ? const Color(0xFF0D2B28) : const Color(0xFF0D2B28)) : const Color(0xFF64748B), 
                fontSize: 14
              ),
            ),
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              hint,
              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11),
            ),
          ),
      ],
    );
  }
}
