import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'translations.dart';
import 'globals.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_icon.dart'; // To refresh notifier
import 'notification_service.dart';

class BloodRequestsListScreen extends StatefulWidget {
  const BloodRequestsListScreen({super.key});

  @override
  State<BloodRequestsListScreen> createState() => _BloodRequestsListScreenState();
}

class _BloodRequestsListScreenState extends State<BloodRequestsListScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _receivedRequests = [];
  List<dynamic> _sentRequests = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchReceivedRequests(),
      _fetchSentRequests(),
    ]);
  }

  Future<void> _fetchReceivedRequests() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/blood-requests/received'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _receivedRequests = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching received requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSentRequests() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/blood-requests/sent'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _sentRequests = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching sent requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('$apiBaseUrl/blood-requests/$requestId'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        _fetchAllData();
        
        if (status == 'approved') {
          NotificationService().showInstantNotification(
            id: 300,
            title: "Request Approved",
            body: "You have approved the blood request. The requester will be notified!",
          );
        }

        // Update global badge count
        final countResponse = await http.get(
          Uri.parse('$apiBaseUrl/blood-requests/count'),
          headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
        );
        if (countResponse.statusCode == 200) {
          bloodRequestCountNotifier.value = jsonDecode(countResponse.body)['count'];
        }
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteRequest(String requestId) async {
    final lang = languageNotifier.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppTranslations.get('delete_request_confirm_title', lang),
          style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          AppTranslations.get('delete_request_confirm_msg', lang),
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.get('cancel', lang).toUpperCase(),
              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteRequest(requestId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              AppTranslations.get('remove_action', lang).toUpperCase(),
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteRequest(String requestId) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/blood-requests/$requestId'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchAllData();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request removed successfully'))
           );
        }
      }
    } catch (e) {
      debugPrint('Error deleting request: $e');
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
                        "REQUEST HUB",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00A98F),
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF00A98F),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: "RECEIVED"),
                    Tab(text: "SENT"),
                  ],
                ),

                // Main Container
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
                    margin: const EdgeInsets.only(top: 16),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRequestList(_receivedRequests, true, lang),
                        _buildRequestList(_sentRequests, false, lang),
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

  Widget _buildRequestList(List<dynamic> requests, bool isReceived, String lang) {
    if (_isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00A98F)));
    }
    
    if (requests.isEmpty) {
      return Center(
        child: Text(
          "No requests found here.",
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index], isReceived, lang);
      },
    );
  }

  Widget _buildRequestCard(dynamic request, bool isReceived, String lang) {
    if (request == null) return const SizedBox.shrink();
    
    final person = isReceived ? request['requesterId'] : request['donorId'];
    if (person == null) return const SizedBox.shrink();
    
    final String name = person['fullName'] ?? 'Anonymous';
    final String bloodGroup = person['bloodGroup'] ?? '?';
    final String status = request['status'] ?? 'pending';
    final String? phone = person['phone'];
    final String requestId = request['_id']?.toString() ?? '';

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1F0EC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  title: Text("Delete Request", style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.w500)),
                  subtitle: Text("This will remove the request from your hub", style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteRequest(requestId);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FFFE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(color: Color(0xFFEEFBFA), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      bloodGroup,
                      style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        isReceived ? "Needs your blood group" : "Request sent to donor",
                        style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status)
              ],
            ),
            
            if (status == 'approved' && phone != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A98F).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, color: Color(0xFF00A98F), size: 18),
                      const SizedBox(width: 12),
                      Text(
                        "Contact: $phone",
                        style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
    
            if (isReceived && status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateRequestStatus(requestId, 'declined'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF5350)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Decline", style: GoogleFonts.poppins(color: const Color(0xFFEF5350), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateRequestStatus(requestId, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A98F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text("Approve", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'approved') color = Colors.green;
    if (status == 'declined') color = Colors.red;
    if (status == 'pending') color = const Color(0xFFF59E0B); // Better orange/amber for light theme

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
