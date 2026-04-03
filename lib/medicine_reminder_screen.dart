import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart';
import 'notification_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'translations.dart';
import 'user_profile_icon.dart';

class MedicineReminderScreen extends StatefulWidget {
  const MedicineReminderScreen({super.key});

  @override
  State<MedicineReminderScreen> createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends State<MedicineReminderScreen> {
  List<dynamic> _reminders = [];
  bool _isLoading = true;
  Timer? _webTimer;
  final Set<String> _notifiedThisMinute = {};
  Set<String> _takenToday = {};

  @override
  void initState() {
    super.initState();
    _loadTakenStatus();
    _fetchReminders();
    NotificationService().requestPermissions();
    if (kIsWeb) _startWebAlarmSim();
  }

  Future<void> _loadTakenStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final taken = prefs.getStringList('taken_$dateKey') ?? [];
    setState(() => _takenToday = taken.toSet());
  }

  Future<void> _markAsTaken(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      if (_takenToday.contains(id)) _takenToday.remove(id);
      else _takenToday.add(id);
    });
    await prefs.setStringList('taken_$dateKey', _takenToday.toList());
  }

  void _startWebAlarmSim() {
    _webTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      for (var r in _reminders) {
        if (r['time'] == timeStr) {
          final notifyKey = "${r['_id']}_$timeStr";
          if (!_notifiedThisMinute.contains(notifyKey)) {
             _showWebAlarmDialog(r);
             _notifiedThisMinute.add(notifyKey);
          }
        }
      }
      if (now.hour == 0 && now.minute == 0) _notifiedThisMinute.clear();
    });
  }

  void _showWebAlarmDialog(dynamic r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("⏰ Medicine Alarm!", style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.w600)),
        content: Text("Time to take ${r['medicineName']} for ${r['condition']}.\nDosage: ${r['dosage']}", style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontWeight: FontWeight.w600)))],
      ),
    );
  }

  @override void dispose() { _webTimer?.cancel(); super.dispose(); }

  Future<void> _fetchReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) { setState(() => _isLoading = false); return; }
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/reminders'), headers: {...apiHeaders, 'Authorization': 'Bearer $token', 'x-auth-token': token});
      if (response.statusCode == 200) {
        setState(() { _reminders = jsonDecode(response.body); _isLoading = false; });
        _syncNotifications(_reminders);
      } else { throw Exception(); }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _syncNotifications(List<dynamic> reminders) async {
       await NotificationService().cancelAllNotifications();
       for (var r in reminders) {
            final parts = (r['time'] as String).split(':');
            await NotificationService().scheduleDailyNotification(
                id: r['_id'].toString().hashCode.abs(),
                title: 'Medicine Reminder!',
                body: 'Time to take ${r['medicineName']}',
                hour: int.parse(parts[0]), minute: int.parse(parts[1])
            );
       }
  }

  Future<void> _upsertReminder({String? id, required String patientName, required String condition, required String tabletName, required String dosage, required TimeOfDay time}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    try {
      final response = await (id == null ? http.post : http.put)(
        Uri.parse(id == null ? '$apiBaseUrl/reminders' : '$apiBaseUrl/reminders/$id'),
        headers: {...apiHeaders, 'Authorization': 'Bearer $token', 'x-auth-token': token ?? ""},
        body: jsonEncode({'patientName': patientName, 'condition': condition, 'medicineName': tabletName, 'dosage': dosage, 'time': timeStr}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) { _fetchReminders(); if (mounted) Navigator.pop(context); }
    } catch (e) {}
  }

  Future<void> _deleteReminder(String id) async {
    final lang = languageNotifier.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(AppTranslations.get('delete_confirm_title', lang), style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppTranslations.get('cancel', lang).toUpperCase())),
          TextButton(onPressed: () { Navigator.pop(context); _performDeleteReminder(id); }, child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _performDeleteReminder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try { await http.delete(Uri.parse('$apiBaseUrl/reminders/$id'), headers: {...apiHeaders, 'Authorization': 'Bearer $token', 'x-auth-token': token ?? ""}); _fetchReminders(); } catch(e) {}
  }

  void _showReminderDialog([dynamic r]) {
    final pC = TextEditingController(text: r?['patientName'] ?? ""), cC = TextEditingController(text: r?['condition'] ?? ""), tC = TextEditingController(text: r?['medicineName'] ?? ""), dC = TextEditingController(text: r?['dosage'] ?? "");
    TimeOfDay selectedTime = r != null ? TimeOfDay(hour: int.parse(r['time'].split(':')[0]), minute: int.parse(r['time'].split(':')[1])) : TimeOfDay.now();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: StatefulBuilder(builder: (context, setS) => SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r == null ? "ADD REMINDER" : "EDIT REMINDER", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 24),
            _buildField("Patient", pC, Icons.person), _buildField("Condition", cC, Icons.health_and_safety), _buildField("Medicine", tC, Icons.medication), _buildField("Dosage", dC, Icons.timer),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async { final t = await showTimePicker(context: context, initialTime: selectedTime); if (t != null) setS(() => selectedTime = t); },
              child: Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0FFFE), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [const Icon(Icons.access_time_rounded, color: Color(0xFF00A98F)), const SizedBox(width: 12), Text("Time: ${selectedTime.format(context)}")]),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A98F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () { if (pC.text.isNotEmpty && tC.text.isNotEmpty) _upsertReminder(id: r?['_id'], patientName: pC.text, condition: cC.text, tabletName: tC.text, dosage: dC.text, time: selectedTime); }, 
              child: const Text("SAVE REMINDER", style: TextStyle(fontWeight: FontWeight.bold))
            )),
            const SizedBox(height: 40),
          ]),
        )),
      ),
    );
  }

  Widget _buildField(String l, TextEditingController c, IconData i) => Padding(padding: const EdgeInsets.only(bottom: 16), child: TextField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: const Color(0xFF00A98F)), filled: true, fillColor: const Color(0xFFF8FFFE), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))));

  @override
  Widget build(BuildContext context) {
    final sorted = List.from(_reminders)..sort((a,b) => (a['time']??"").compareTo(b['time']??""));
    final nowM = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    dynamic next; List<dynamic> overdue = [], other = [];
    for (var r in sorted) {
      final id = r['_id']?.toString()??"";
      final parts = (r['time']??"00:00").split(':');
      final medM = int.parse(parts[0])*60 + int.parse(parts[1]);
      if (_takenToday.contains(id)) other.add(r);
      else if (medM < nowM) overdue.add(r);
      else { if (next == null) next = r; else other.add(r); }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: Container(
          decoration: const BoxDecoration(color: Color(0xFFF8FFFE), borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))),
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A98F))) : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildStatusCard(), const SizedBox(height: 24),
              if (next != null) ...[_buildSectionTitle("Next Medication"), _buildMedCard(next, isNext: true), const SizedBox(height: 24)],
              if (overdue.isNotEmpty) ...[_buildSectionTitle("Attention Needed"), ...overdue.map((m) => _buildMedCard(m, isOverdue: true)), const SizedBox(height: 24)],
              if (other.isNotEmpty || (next==null && overdue.isEmpty && _reminders.isNotEmpty)) ...[_buildSectionTitle("All Medications"), ...other.map((m) => _buildMedCard(m))],
              if (_reminders.isEmpty) _buildEmptyState(),
              const SizedBox(height: 80),
            ]),
          ),
        )),
      ])),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF00A98F), onPressed: () => _showReminderDialog(), child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  Widget _buildHeader() => Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Row(children: [
    if (Navigator.canPop(context)) IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)) else const SizedBox(width: 40),
    const Spacer(), const Icon(Icons.favorite, color: Color(0xFFEF5350)), const SizedBox(width: 8), Text("Medication", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)), const Spacer(),
    IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B)), onPressed: () {}), const EmergencyHelpIcon(),
  ]));

  Widget _buildStatusCard() {
    final progress = _reminders.isEmpty ? 0.0 : _takenToday.length / _reminders.length;
    return Container(
      padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.check_circle, color: Color(0xFF00A98F)), const SizedBox(width: 12), Text("Today's Status", style: GoogleFonts.poppins(fontWeight: FontWeight.w600))]),
        const SizedBox(height: 16), Text("${_takenToday.length} of ${_reminders.length} taken", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFFEEFBFA), valueColor: const AlwaysStoppedAnimation(Color(0xFF00A98F)), minHeight: 6)),
      ]),
    );
  }

  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 16, left: 4), child: Text(t.toUpperCase(), style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)));

  Widget _buildMedCard(dynamic r, {bool isNext = false, bool isOverdue = false}) {
    final id = r['_id']?.toString()??""; final isTaken = _takenToday.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isOverdue ? Icons.warning_amber_rounded : (isNext ? Icons.notifications_active : Icons.notifications_none), color: isOverdue ? Colors.red : (isNext ? const Color(0xFF00A98F) : Colors.grey)),
          const SizedBox(width: 12), Text(isOverdue ? "Attention Needed" : (isNext ? "Next Medication" : "Scheduled"), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isOverdue ? Colors.red : const Color(0xFF0D2B28))),
          const Spacer(), _miniI(Icons.edit, const Color(0xFF3B82F6), () => _showReminderDialog(r)), const SizedBox(width: 8), _miniI(Icons.delete, Colors.red, () => _deleteReminder(id)),
        ]),
        const SizedBox(height: 16), Text("${r['medicineName']} ${r['dosage']}", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(isOverdue ? "Overdue" : "Scheduled for ${r['time']}", style: GoogleFonts.poppins(color: isOverdue ? Colors.orange : Colors.grey)),
        const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isTaken ? const Color(0xFFEEFBFA) : const Color(0xFF00A98F), foregroundColor: isTaken ? const Color(0xFF00A98F) : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () => _markAsTaken(id), child: Text(isTaken ? "Taken" : "Mark as taken", style: const TextStyle(fontWeight: FontWeight.bold))
        )),
      ]),
    );
  }

  Widget _miniI(IconData i, Color c, VoidCallback o) => GestureDetector(onTap: o, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, color: c, size: 16)));
  Widget _buildEmptyState() => Center(child: Padding(padding: const EdgeInsets.all(40), child: Text("No medications scheduled", style: GoogleFonts.poppins(color: Colors.grey))));
}
