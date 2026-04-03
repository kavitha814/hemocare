import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'globals.dart';
import 'translations.dart';

class ECGMonitorScreen extends StatefulWidget {
  const ECGMonitorScreen({super.key});

  @override
  State<ECGMonitorScreen> createState() => _ECGMonitorScreenState();
}

class _ECGMonitorScreenState extends State<ECGMonitorScreen> {
  Socket? _socket;
  StreamSubscription<List<int>>? _socketSubscription;
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.100");

  bool isConnecting = false;
  String statusMessage = "Disconnected";
  bool leadsOff = false;

  List<FlSpot> ecgPoints = [];
  List<double> filterBuffer = [];
  double timeCount = 0;
  int currentBPM = 0;
  
  double minY = -500;
  double maxY = 500;
  double runningSum = 0;
  int filterWindow = 5; 

  @override
  void initState() {
    super.initState();
  }

  Future<void> _connectToWiFi() async {
    setState(() {
      isConnecting = true;
      statusMessage = "Connecting to ${_ipController.text}...";
    });

    try {
      _socket?.destroy();
      _socket = await Socket.connect(_ipController.text, 8080, timeout: const Duration(seconds: 5));
      
      setState(() {
        isConnecting = false;
        statusMessage = "Connected";
      });

      _socketSubscription = _socket!.listen(
        _onDataReceived,
        onDone: () => _handleDisconnect("Server Closed Connection"),
        onError: (e) => _handleDisconnect("Connection Error: $e"),
      );
    } catch (e) {
      debugPrint("WiFi Connection Error: $e");
      if (mounted) {
        setState(() {
          isConnecting = false;
          statusMessage = "Connection Failed";
        });
        _showError("Could not connect to ESP32 at ${_ipController.text}");
      }
    }
  }

  void _handleDisconnect(String reason) {
    debugPrint("Disconnected: $reason");
    if (mounted) {
      setState(() {
        _socket = null;
        statusMessage = "Disconnected";
        ecgPoints.clear();
        currentBPM = 0;
        timeCount = 0;
      });
    }
  }

  String _remainder = "";
  void _onDataReceived(List<int> data) {
    try {
      String rawChunk = _remainder + utf8.decode(data);
      List<String> lines = rawChunk.split('\n');
      
      // Keep the last partial line
      _remainder = lines.removeLast();

      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        List<String> parts = line.split(',');
        if (parts.length == 2) {
          if (mounted) {
            setState(() {
              int bpm = int.tryParse(parts[0]) ?? 0;
              double rawVal = double.tryParse(parts[1]) ?? 0;

              currentBPM = bpm;
              leadsOff = (rawVal == -5000); 

              if (leadsOff) {
                ecgPoints.clear();
                return; 
              }

              filterBuffer.add(rawVal);
              runningSum += rawVal;
              if (filterBuffer.length > filterWindow) {
                runningSum -= filterBuffer.removeAt(0);
              }
              double filteredVal = runningSum / filterBuffer.length;

              ecgPoints.add(FlSpot(timeCount, filteredVal));
              timeCount += 0.01;

              if (ecgPoints.length > 500) {
                ecgPoints.removeAt(0);
              }

              if (ecgPoints.length % 10 == 0) {
                double currentMin = 5000;
                double currentMax = -5000;
                for (var spot in ecgPoints) {
                  if (spot.y < currentMin) currentMin = spot.y;
                  if (spot.y > currentMax) currentMax = spot.y;
                }
                double range = currentMax - currentMin;
                if (range < 100) range = 100;
                minY = currentMin - (range * 0.1);
                maxY = currentMax + (range * 0.1);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Data Process Error: $e");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socket?.destroy();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = languageNotifier.value;
    bool isConnected = _socket != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D2B28), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'LIVE HEART MONITOR',
                        style: TextStyle(
                          color: Color(0xFF0D2B28),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // WiFi IP Input Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFFE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: _ipController,
                        style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Enter ESP32 IP",
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          prefixIcon: const Icon(Icons.wifi_rounded, color: Color(0xFF00A98F), size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: isConnecting ? null : (isConnected ? () => _handleDisconnect("Manual") : _connectToWiFi),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF00A98F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isConnected ? Colors.redAccent.withOpacity(0.5) : Colors.transparent
                        ),
                      ),
                      child: Text(
                        isConnected ? "STOP" : "CONNECT",
                        style: GoogleFonts.poppins(
                          color: isConnected ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Connection Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFFE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConnected ? const Color(0xFF00A98F).withOpacity(0.3) : const Color(0xFFD1F0EC)
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? const Color(0xFF00A98F) : isConnecting ? Colors.orange : Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (isConnected ? const Color(0xFF00A98F) : isConnecting ? Colors.orange : Colors.redAccent).withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusMessage.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: isConnected ? const Color(0xFF00A98F) : const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Main Monitor Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFFE),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.get('real_time_stream', lang),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF00A98F),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              leadsOff ? AppTranslations.get('leads_off', lang) : AppTranslations.get('sinus_rhythm', lang),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF0D2B28),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // BPM Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A98F).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Pulse(
                                infinite: true,
                                duration: Duration(milliseconds: (60000 / (currentBPM > 0 ? currentBPM : 70)).toInt()),
                                child: const Icon(Icons.favorite, color: Color(0xFFFF2D55), size: 24),
                              ),
                              const SizedBox(width: 12),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$currentBPM',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0D2B28),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' BPM',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF64748B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ECG Graph
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 500,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: const Color(0xFFD1F0EC).withOpacity(0.5),
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (value) => FlLine(
                              color: const Color(0xFFD1F0EC).withOpacity(0.5),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 2.5,
                                getTitlesWidget: (value, meta) {
                                  double diff = value - timeCount;
                                  if (diff > -10.1 && diff < 0.1) {
                                    return Text(
                                      '${diff.toStringAsFixed(1)}s',
                                      style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: timeCount - 5,
                          maxX: timeCount,
                          minY: minY,
                          maxY: maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: ecgPoints,
                              isCurved: true,
                              color: const Color(0xFF00A98F),
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00A98F).withOpacity(0.2),
                                    const Color(0xFF00A98F).withOpacity(0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 0),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stop Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  side: const BorderSide(color: Color(0xFFEC407A), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: const Color(0xFFEC407A).withOpacity(0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stop_circle_rounded, color: Color(0xFFEC407A)),
                    const SizedBox(width: 12),
                    Text(
                      AppTranslations.get('stop_monitoring', lang),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFEC407A),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFD1F0EC))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.chat_bubble_rounded, AppTranslations.get('chat', lang), false),
                  _navItem(Icons.volunteer_activism_outlined, AppTranslations.get('blood', lang), true),
                  _navItem(Icons.add_box_outlined, AppTranslations.get('hospitals', lang), false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF00A98F) : const Color(0xFF64748B), size: 24),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: isActive ? const Color(0xFF00A98F) : const Color(0xFF64748B),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
