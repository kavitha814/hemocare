import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';
import 'translations.dart';
import 'user_profile_icon.dart';
import 'profile_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final List<Map<String, String>> _contacts = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadContacts(); 
  }

  Future<void> _loadContacts() async {
    // 1. Load from local cache first for instant feedback
    final prefs = await SharedPreferences.getInstance();
    final String? contactString = prefs.getString('emergency_contacts');
    if (contactString != null) {
      List<dynamic> decoded = jsonDecode(contactString);
      setState(() {
        _contacts.clear();
        _contacts.addAll(decoded.map((e) => Map<String, String>.from(e)));
      });
    }

    // 2. Fetch from Backend
    final token = prefs.getString('auth_token');
    if (token == null) return;

    setState(() => _isSyncing = true);
    try {
      final response = await http.get(
        Uri.parse(contactsBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, String>> fetchedContacts = data.map((e) => {
          'id': e['_id'].toString(),
          'name': e['name'].toString(),
          'phone': e['phone'].toString(),
        }).toList();

        setState(() {
          _contacts.clear();
          _contacts.addAll(fetchedContacts);
        });
        
        // Update local cache
        await prefs.setString('emergency_contacts', jsonEncode(fetchedContacts));
      }
    } catch (e) {
      print('Error fetching contacts: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _saveContactsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contacts', jsonEncode(_contacts));
  }

  Future<void> _callNumber(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.get('dialer_error', languageNotifier.value))));
    }
  }

  Future<void> _shareLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.get('location_denied', languageNotifier.value))));
          return;
      }
    }
    
    try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        String googleUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
        final helpMsg = AppTranslations.get('help_message', languageNotifier.value);
        await Share.share("$helpMsg $googleUrl");
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${AppTranslations.get('location_error', languageNotifier.value)}: $e")));
    }
  }

  void _addContact() {
       TextEditingController nameCtrl = TextEditingController();
       TextEditingController phoneCtrl = TextEditingController();
        showDialog(
            context: context, 
            builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text(
                  AppTranslations.get('add_contact_title', languageNotifier.value),
                  style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold, fontSize: 18),
                ),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          "NAME",
                          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFFE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: nameCtrl, 
                            style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
                            decoration: InputDecoration(
                              hintText: AppTranslations.get('name_label', languageNotifier.value),
                              hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "PHONE",
                          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFFE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: phoneCtrl, 
                            keyboardType: TextInputType.phone, 
                            style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
                            decoration: InputDecoration(
                              hintText: AppTranslations.get('phone_label', languageNotifier.value),
                              hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
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
                            onPressed: () => Navigator.pop(context), 
                            child: Text(
                              AppTranslations.get('cancel', languageNotifier.value).toUpperCase(),
                              maxLines: 1,
                              softWrap: false,
                              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(colors: [Color(0xFF00A98F), Color(0xFF00D1C1)]),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                    if(nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                                        final newContact = {'name': nameCtrl.text, 'phone': phoneCtrl.text};
                                        Navigator.pop(context); // Close dialog first

                                        // Update locally
                                        setState(() => _contacts.add(newContact));
                                        _saveContactsLocally();

                                        // Sync to backend
                                        final prefs = await SharedPreferences.getInstance();
                                        final token = prefs.getString('auth_token');
                                        if (token != null) {
                                            try {
                                                final response = await http.post(
                                                    Uri.parse(contactsBaseUrl),
                                                    headers: {'Content-Type': 'application/json', 'x-auth-token': token},
                                                    body: jsonEncode(newContact),
                                                );
                                                if (response.statusCode == 200) {
                                                    _loadContacts(); // Reload to get the ID from backend
                                                }
                                            } catch (e) {
                                                print('Error adding contact: $e');
                                            }
                                        }
                                    }
                                }, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text(
                                  AppTranslations.get('save', languageNotifier.value).toUpperCase(),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
            )
        );
  }

  void _editContact(int index) {
      TextEditingController nameCtrl = TextEditingController(text: _contacts[index]['name']);
       TextEditingController phoneCtrl = TextEditingController(text: _contacts[index]['phone']);
        showDialog(
            context: context, 
            builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text(
                  AppTranslations.get('edit_contact_title', languageNotifier.value),
                  style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold, fontSize: 18),
                ),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          "NAME",
                          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFFE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: nameCtrl, 
                            style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
                            decoration: InputDecoration(
                              hintText: AppTranslations.get('name_label', languageNotifier.value),
                              hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "PHONE",
                          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFFE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: phoneCtrl, 
                            keyboardType: TextInputType.phone, 
                            style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
                            decoration: InputDecoration(
                              hintText: AppTranslations.get('phone_label', languageNotifier.value),
                              hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
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
                            onPressed: () => Navigator.pop(context), 
                            child: Text(
                              AppTranslations.get('cancel', languageNotifier.value).toUpperCase(),
                              maxLines: 1,
                              softWrap: false,
                              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(colors: [Color(0xFF00A98F), Color(0xFF00D1C1)]),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                    if(nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                                        final contactId = _contacts[index]['id'];
                                        final updatedContact = {'name': nameCtrl.text, 'phone': phoneCtrl.text};
                                        if (contactId != null) updatedContact['id'] = contactId;
                                        
                                        Navigator.pop(context);

                                        setState(() => _contacts[index] = updatedContact);
                                        _saveContactsLocally();

                                        if (contactId != null) {
                                            final prefs = await SharedPreferences.getInstance();
                                            final token = prefs.getString('auth_token');
                                            if (token != null) {
                                                try {
                                                    await http.put(
                                                        Uri.parse('$contactsBaseUrl/$contactId'),
                                                        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
                                                        body: jsonEncode({'name': nameCtrl.text, 'phone': phoneCtrl.text}),
                                                    );
                                                } catch (e) {
                                                    print('Error updating contact: $e');
                                                }
                                            }
                                        }
                                    }
                                }, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text(
                                  AppTranslations.get('save', languageNotifier.value).toUpperCase(),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
            )
        );
  }

  void _deleteContact(int index) async {
      final contactId = _contacts[index]['id'];
      setState(() => _contacts.removeAt(index));
      _saveContactsLocally();

      if (contactId != null) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
              try {
                  await http.delete(
                      Uri.parse('$contactsBaseUrl/$contactId'),
                      headers: {'x-auth-token': token},
                  );
              } catch (e) {
                  print('Error deleting contact: $e');
              }
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: Colors.white, // Deep dark background
          body: SafeArea(
            child: Column(
              children: [
                // Sub-page Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppTranslations.get('emergency_help', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                
                // Main Content Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FFFE),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Quick Dial Buttons
                          Row(
                            children: [
                              Expanded(child: _buildQuickDial(AppTranslations.get('ambulance', lang), "108", Icons.medical_services_outlined, const Color(0xFFC62828))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildQuickDial(AppTranslations.get('police', lang), "100", Icons.local_police_outlined, const Color(0xFF1565C0))),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Location Share
                          _buildSectionTitle(AppTranslations.get('location_sharing', lang)),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00A98F), Color(0xFF00D1C1)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00A98F).withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _shareLocation,
                              icon: const Icon(Icons.share_location_rounded, size: 22),
                              label: Text(
                                AppTranslations.get('share_location_btn', lang),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),
                          
                          // Emergency Contacts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle(AppTranslations.get('emergency_contacts', lang)),
                              GestureDetector(
                                onTap: _addContact,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A98F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add_rounded, size: 18, color: Color(0xFF00A98F)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ADD',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF00A98F),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_contacts.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FFFE),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.contact_phone_outlined, size: 48, color: const Color(0xFFD1F0EC)),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppTranslations.get('no_contacts', lang),
                                    style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppTranslations.get('set_emergency_contacts', lang),
                                    style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._contacts.asMap().entries.map((entry) {
                               int idx = entry.key;
                               var contact = entry.value;
                               return Container(
                                   margin: const EdgeInsets.only(bottom: 12),
                                   decoration: BoxDecoration(
                                       color: const Color(0xFFF0FFFE),
                                       borderRadius: BorderRadius.circular(20),
                                       border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                                   ),
                                   child: ListTile(
                                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                       leading: Container(
                                         width: 48,
                                         height: 48,
                                         decoration: BoxDecoration(
                                           color: const Color(0xFFEEFBFA),
                                           shape: BoxShape.circle,
                                         ),
                                         child: Center(
                                           child: Text(
                                             contact['name']![0].toUpperCase(),
                                             style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontWeight: FontWeight.w600, fontSize: 18),
                                           ),
                                         ),
                                       ),
                                       title: Text(contact['name']!, style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.w600)),
                                       subtitle: Text(contact['phone']!, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13)),
                                       trailing: Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                             IconButton(
                                               icon: const Icon(Icons.call_outlined, color: Color(0xFF00A98F)), 
                                               onPressed: () => _callNumber(contact['phone']!)
                                             ),
                                             PopupMenuButton(
                                               icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B)),
                                               color: Colors.white,
                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                               itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'edit', 
                                                    child: Text(AppTranslations.get('edit_contact', lang), style: const TextStyle(color: Color(0xFF0D2B28), fontSize: 14))
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete', 
                                                    child: Text(AppTranslations.get('delete_contact', lang), style: const TextStyle(color: Colors.redAccent, fontSize: 14))
                                                  ),
                                               ],
                                               onSelected: (val) {
                                                   if (val == 'edit') _editContact(idx);
                                                   if (val == 'delete') _deleteContact(idx);
                                               },
                                             )
                                         ],
                                       ),
                                   ),
                               );
                           }).toList(),
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
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
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
                  color: const Color(0xFF00A98F).withOpacity(0.4),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(), 
      style: GoogleFonts.poppins(
        fontSize: 13, 
        fontWeight: FontWeight.w600, 
        color: const Color(0xFF64748B),
        letterSpacing: 1.2,
      )
    );
  }

  Widget _buildQuickDial(String title, String number, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _callNumber(number),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title, 
                  textAlign: TextAlign.center, 
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, 
                    color: const Color(0xFF0D2B28),
                    fontSize: 14,
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
