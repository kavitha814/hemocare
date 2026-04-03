import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'globals.dart';
import 'translations.dart';
import 'notification_service.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  String _selectedBloodGroup = 'O+';
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  
  List<dynamic> _donors = [];
  Map<String, String> _sentRequests = {}; // donorId -> status
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDonors();
    _fetchSentRequests();
  }

  Future<void> _fetchSentRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/blood-requests/sent'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<String, String> statusMap = {};
        for (var req in data) {
          statusMap[req['donorId']] = req['status'];
        }
        setState(() {
          _sentRequests = statusMap;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sent requests: $e');
    }
  }

  Future<void> _fetchDonors() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/donors?bloodGroup=${Uri.encodeComponent(_selectedBloodGroup)}'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _donors = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching donors: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(String donorId, String donorName) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/blood-requests'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'donorId': donorId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _sentRequests[donorId] = 'pending';
        });
        
        // Show local notification confirmation
        NotificationService().showInstantNotification(
          id: 200,
          title: "Request Sent!",
          body: "Your blood request has been successfully sent to $donorName.",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to $donorName')),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['msg'] ?? 'Failed to send request')),
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
                        AppTranslations.get('request_blood_title', lang),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FFFE),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.get('required_blood_group', lang),
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FFFE),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedBloodGroup,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
                                    style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 16, fontWeight: FontWeight.w500),
                                    onChanged: (val) {
                                      setState(() => _selectedBloodGroup = val!);
                                      _fetchDonors();
                                    },
                                    items: _bloodGroups.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppTranslations.get('compatible_donors', lang).toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                "${_donors.length} ${AppTranslations.get('found', lang)}",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF00A98F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Donor List
                        Expanded(
                          child: _isLoading 
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A98F)))
                            : _donors.isEmpty
                              ? Center(
                                  child: Text(
                                    lang == 'Tamil' ? 'நன்கொடையாளர்கள் யாரும் கிடைக்கவில்லை' : "No donors found for this group.",
                                    style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                  itemCount: _donors.length,
                                  itemBuilder: (context, index) {
                                    return _buildDonorCard(_donors[index], lang);
                                  },
                                ),
                        ),
                      ],
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

  Widget _buildDonorCard(dynamic donor, String lang) {
    if (donor == null) return const SizedBox.shrink();
    
    String donorId = '';
    final dynamic uId = donor['userId'];
    if (uId != null && uId is Map) {
      donorId = uId['_id']?.toString() ?? '';
    } else {
      donorId = uId?.toString() ?? '';
    }
    final String name = donor['fullName'] ?? 'Anonymous';
    final String location = donor['location'] ?? 'Unknown';
    final String bloodGroup = donor['bloodGroup'] ?? '?';
    final String? lastDonation = donor['lastDonation'];
    
    final String? requestStatus = _sentRequests[donorId];

    String donationInfo = "did not donate blood since registration";
    if (lastDonation != null && lastDonation.isNotEmpty) {
      try {
        final date = DateTime.parse(lastDonation);
        donationInfo = "Last donated: ${DateFormat('dd/MM/yyyy').format(date)}";
      } catch (e) {
        debugPrint('Error parsing donation date: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Blood Group Badge
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEEFBFA),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                bloodGroup,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00A98F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0D2B28),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  donationInfo,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00A98F).withOpacity(0.6),
                    fontSize: 11,
                    fontStyle: lastDonation == null ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
          // Request Button or Status
          if (requestStatus == 'approved')
            _buildStatusBadge('Approved', Colors.green)
          else if (requestStatus == 'declined')
             _buildStatusBadge('Declined', Colors.red)
          else
            ElevatedButton(
              onPressed: requestStatus == 'pending' ? null : () => _sendRequest(donorId, name),
              style: ElevatedButton.styleFrom(
                backgroundColor: requestStatus == 'pending' ? const Color(0xFFF59E0B) : const Color(0xFF00A98F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                requestStatus == 'pending' ? 'Pending' : AppTranslations.get('request', lang),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
