import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'globals.dart';
import 'translations.dart';
import 'user_profile_icon.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  // UI State
  bool _isLoading = false;
  String? _errorMessage;
  double _distanceKm = 10.0;
  String _selectedFilter = 'All'; // All, Government, Private
  final TextEditingController _searchController = TextEditingController();
  
  // Map State
  final MapController _mapController = MapController();
  bool _isMapView = false;

  // Data
  List<dynamic> _hospitals = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetch();
  }

  Future<void> _checkLocationAndFetch() async {
    setState(() => _isLoading = true);
    
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Location permissions are denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
         _isLoading = false;
         _errorMessage = "Location permissions are permanently denied.";
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _fetchHospitals(); 
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error getting location: $e";
      });
    }
  }

  Future<void> _fetchHospitals({String? query}) async {
    setState(() {
        _isLoading = true;
        _errorMessage = null; 
    });

    try {
      final String url;
      if (query != null && query.isNotEmpty) {
           url = "https://nominatim.openstreetmap.org/search?q=hospital+in+$query&format=json&addressdetails=1&limit=20";
      } else if (_currentPosition != null) {
          final double lat = _currentPosition!.latitude;
          final double lon = _currentPosition!.longitude;
          
          double distDegLat = _distanceKm / 111.0;
          double distDegLon = _distanceKm / (111.0 * (1.0)); 

          double left = lon - distDegLon;
          double right = lon + distDegLon;
          double top = lat + distDegLat; 
          double bottom = lat - distDegLat;

          url = "https://nominatim.openstreetmap.org/search?q=hospital&format=json&limit=50&viewbox=$left,$top,$right,$bottom&bounded=1&addressdetails=1";
      } else {
        setState(() => _isLoading = false);
        return;
      }

      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
            'User-Agent': 'CareConnect_App_Student_Project/1.0' 
        }
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
            _hospitals = data;
            _isLoading = false;
        });
      } else {
        setState(() {
             _errorMessage = "Network Error: ${response.statusCode}";
             _isLoading = false;
        });
      }
    } catch (e) {
         setState(() {
             _errorMessage = "Exception: $e";
             _isLoading = false;
        });
    }
  }

  List<dynamic> get _filteredHospitals {
      if (_selectedFilter == 'All') return _hospitals;
      
      return _hospitals.where((hospital) {
          final name = (hospital['name'] as String? ?? '').toLowerCase();
          final displayName = (hospital['display_name'] as String? ?? '').toLowerCase();

          if (_selectedFilter == 'Government') {
              return name.contains('govt') || name.contains('government') || name.contains('public') || name.contains('gh') || displayName.contains('government');
          } else {
              return !(name.contains('govt') || name.contains('government') || name.contains('public') || name.contains('gh') || displayName.contains('government'));
          }
      }).toList();
  }

  Future<void> _openDirections(double lat, double lng) async {
    // Try Google Maps deep link first for better mobile experience
    final Uri googleMapsIntent = Uri.parse("google.navigation:q=$lat,$lng");
    final Uri googleMapsWeb = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    try {
      if (await canLaunchUrl(googleMapsIntent)) {
        await launchUrl(googleMapsIntent, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsWeb)) {
        await launchUrl(googleMapsWeb, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch directions';
      }
    } catch (e) {
      debugPrint("Error launching directions: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening maps: $e")),
        );
      }
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
                // Custom Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      _headerLogo(),
                      const SizedBox(width: 12),
                      Text(
                        AppTranslations.get('find_hospitals_title', lang).toUpperCase(),
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
                    child: Column(
                      children: [
                        // Search & Filters Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Modern Search Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FFFE),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: AppTranslations.get('search_city', lang),
                                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00A98F), size: 20),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF00A98F)),
                                      onPressed: () => _fetchHospitals(query: _searchController.text),
                                    ),
                                  ),
                                  onSubmitted: (val) => _fetchHospitals(query: val),
                                ),
                              ),
                              
                              if (!_isMapView) ...[
                                const SizedBox(height: 24),
                                // Radius Control
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppTranslations.get('search_radius', lang).toUpperCase(),
                                      style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                                    ),
                                    Text(
                                      '${_distanceKm.toStringAsFixed(0)} KM',
                                      style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: const Color(0xFF00A98F),
                                    inactiveTrackColor: const Color(0xFFE2F7F5),
                                    thumbColor: const Color(0xFF00A98F),
                                  ),
                                  child: Slider(
                                    value: _distanceKm,
                                    min: 5,
                                    max: 50,
                                    onChanged: (val) => setState(() => _distanceKm = val),
                                    onChangeEnd: (val) => _fetchHospitals(),
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 12),
                              // Filter Tabs
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterTab(AppTranslations.get('all_hospitals', lang), 'All'),
                                    const SizedBox(width: 8),
                                    _buildFilterTab(AppTranslations.get('govt_hospitals', lang), 'Government'),
                                    const SizedBox(width: 8),
                                    _buildFilterTab(AppTranslations.get('pvt_hospitals', lang), 'Private'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // View Mode Toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildToggleItem(AppTranslations.get('list_view', lang), Icons.list_rounded, !_isMapView)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildToggleItem(AppTranslations.get('map_view', lang), Icons.map_rounded, _isMapView)),
                              ],
                            ),
                          ),
                        ),

                        // Main List/Map Area
                        Expanded(
                          child: _isLoading 
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A98F)))
                            : _errorMessage != null
                                ? Center(child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.redAccent)))
                                : _isMapView 
                                    ? _buildMap() 
                                    : _buildList(lang),
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

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A98F).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A98F).withOpacity(0.3) : const Color(0xFFD1F0EC),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? const Color(0xFF00A98F) : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(String label, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isMapView = (label == AppTranslations.get('map_view', languageNotifier.value))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00A98F).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF00A98F).withOpacity(0.3) : const Color(0xFFD1F0EC),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF00A98F) : const Color(0xFF64748B), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? const Color(0xFF00A98F) : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String lang) {
    final list = _filteredHospitals;
    if (list.isEmpty) {
      return Center(
        child: Text(
          AppTranslations.get('no_hospitals', lang), 
          style: GoogleFonts.poppins(color: const Color(0xFF64748B))
        )
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildHospitalCard(list[index], lang),
    );
  }

  Widget _buildHospitalCard(dynamic hospital, String lang) {
    final lat = double.tryParse(hospital['lat'] ?? '') ?? 0.0;
    final lon = double.tryParse(hospital['lon'] ?? '') ?? 0.0;
    final displayName = hospital['display_name'] ?? 'Unknown';
    final name = displayName.split(',').first; 

    String distanceStr = "";
    if (_currentPosition != null) {
      double dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lon) / 1000;
      distanceStr = "${dist.toStringAsFixed(1)} KM";
    }

    final isGovt = displayName.toLowerCase().contains('government') || displayName.toLowerCase().contains('govt');
    final tagText = isGovt ? AppTranslations.get('govt_hospitals', lang) : AppTranslations.get('pvt_hospitals', lang);
    final tagColor = isGovt ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEFBFA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF00A98F), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontWeight: FontWeight.w600, fontSize: 16)
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tagColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        tagText, 
                        style: GoogleFonts.poppins(color: tagColor, fontSize: 10, fontWeight: FontWeight.w600)
                      ),
                    ),
                  ],
                ),
              ),
              if (distanceStr.isNotEmpty)
                Text(
                  distanceStr, 
                  style: GoogleFonts.poppins(color: const Color(0xFF00A98F), fontWeight: FontWeight.w700, fontSize: 12)
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName, 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis, 
            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12, height: 1.4)
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF00A98F), Color(0xFF00D1C1)]),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _openDirections(lat, lon),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: Text(
                AppTranslations.get('directions', lang),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    List<Marker> markers = [];
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 50,
          height: 50,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
            child: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF00A98F), size: 32),
          ),
        ),
      );
    }

    for (var hospital in _filteredHospitals) {
      final lat = double.tryParse(hospital['lat'] ?? '');
      final lon = double.tryParse(hospital['lon'] ?? '');
      if (lat != null && lon != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 40,
            height: 40,
            child: const Icon(Icons.location_on_rounded, color: Color(0xFFCF6679), size: 36),
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition != null 
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(20.5937, 78.9629), 
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.careconnect',
            tileDisplay: const TileDisplay.fadeIn(),
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
