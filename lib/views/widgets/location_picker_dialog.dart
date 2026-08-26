import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../services/geocoding_service.dart';

enum MapTileType {
  googleStreet,
  googleSatellite,
  googleTerrain,
  openStreetMap,
}

class LocationPickerDialog extends StatefulWidget {
  final LatLng initialLocation;
  final String initialAddress;
  final String initialPostcode;
  final Color primaryColor;
  final Color accentColor;

  const LocationPickerDialog({
    super.key,
    required this.initialLocation,
    this.initialAddress = '',
    this.initialPostcode = '',
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng _selectedPosition;
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();

  MapTileType _selectedMapType = MapTileType.googleStreet;
  double _currentZoom = 16.0;

  bool _isSearching = false;
  bool _isReverseGeocoding = false;
  List<LocationSearchResult> _searchResults = [];
  Timer? _debounceTimer;

  final List<Map<String, dynamic>> _quickLocations = [
    {'name': '📍 Lahore (Gulberg)', 'lat': 31.5204, 'lng': 74.3587},
    {'name': '📍 Lahore (DHA)', 'lat': 31.4697, 'lng': 74.3973},
    {'name': '📍 Karachi (Clifton)', 'lat': 24.8138, 'lng': 67.0300},
    {'name': '📍 Islamabad (F-7)', 'lat': 33.7215, 'lng': 73.0551},
    {'name': '📍 Rawalpindi (Saddar)', 'lat': 33.5989, 'lng': 73.0543},
    {'name': '📍 Faisalabad', 'lat': 31.4187, 'lng': 73.0791},
    {'name': '📍 Multan', 'lat': 30.1575, 'lng': 71.5249},
    {'name': '📍 Gujranwala', 'lat': 32.1877, 'lng': 74.1945},
    {'name': '📍 London Central', 'lat': 51.5074, 'lng': -0.1278},
    {'name': '📍 Dubai Mall', 'lat': 25.1972, 'lng': 55.2744},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialLocation;
    _mapController = MapController();
    _addressController.text = widget.initialAddress;
    _postcodeController.text = widget.initialPostcode;

    // Auto-reverse geocode if initial address is empty
    if (widget.initialAddress.trim().isEmpty) {
      _performReverseGeocode(_selectedPosition);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await GeocodingService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(LocationSearchResult result) {
    setState(() {
      _selectedPosition = result.latLng;
      _searchResults = [];
      _searchController.clear();
      _addressController.text = result.fullAddress;
      if (result.postcode != null && result.postcode!.isNotEmpty) {
        _postcodeController.text = result.postcode!;
      }
    });
    _mapController.move(result.latLng, 17.0);
    _currentZoom = 17.0;
  }

  Future<void> _performReverseGeocode(LatLng latLng) async {
    setState(() {
      _isReverseGeocoding = true;
    });
    final result = await GeocodingService.reverseGeocode(latLng);
    if (mounted) {
      setState(() {
        _isReverseGeocoding = false;
        if (result != null && result.fullAddress.isNotEmpty) {
          _addressController.text = result.fullAddress;
          if (result.postcode != null && result.postcode!.isNotEmpty) {
            _postcodeController.text = result.postcode!;
          }
        }
      });
    }
  }

  void _onTapMap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedPosition = latLng;
      _searchResults = [];
    });
    _performReverseGeocode(latLng);
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 20.0);
      _mapController.move(_selectedPosition, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 20.0);
      _mapController.move(_selectedPosition, _currentZoom);
    });
  }

  void _recenterToPin() {
    _mapController.move(_selectedPosition, _currentZoom);
  }

  String _getTileUrl() {
    switch (_selectedMapType) {
      case MapTileType.googleStreet:
        // Google Maps Standard Street Map with full detail (streets, shops, chowks, lanes)
        return 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapTileType.googleSatellite:
        // Google Maps Satellite + Street Names Hybrid
        return 'https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapTileType.googleTerrain:
        // Google Maps Terrain
        return 'https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case MapTileType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getSubdomains() {
    switch (_selectedMapType) {
      case MapTileType.googleStreet:
      case MapTileType.googleSatellite:
      case MapTileType.googleTerrain:
        return ['mt0', 'mt1', 'mt2', 'mt3'];
      case MapTileType.openStreetMap:
        return ['a', 'b', 'c'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1. Full Screen Interactive Google Maps View
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPosition,
                  initialZoom: _currentZoom,
                  maxZoom: 20.0,
                  minZoom: 3.0,
                  onTap: _onTapMap,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    subdomains: _getSubdomains(),
                    userAgentPackageName: 'com.google.android.apps.maps',
                    maxZoom: 20,
                    maxNativeZoom: 20,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPosition,
                        width: 80,
                        height: 80,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Top Floating Header & Google Search Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 14,
              right: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Top Floating Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Back / Close Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                          tooltip: 'Back to Store',
                          onPressed: () => Navigator.pop(context),
                        ),

                        // Search Input
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search any street, shop, mohallah, area...',
                              hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                            ),
                          ),
                        ),

                        // Loading or Clear Button
                        if (_isSearching)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                              ),
                            ),
                          )
                        else if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.search_rounded, color: widget.primaryColor, size: 22),
                          ),
                      ],
                    ),
                  ),

                  // Search Results Dropdown List
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, idx) {
                            final result = _searchResults[idx];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: widget.primaryColor.withValues(alpha: 0.1),
                                child: Icon(Icons.place_rounded, color: widget.primaryColor, size: 18),
                              ),
                              title: Text(
                                result.title,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                result.fullAddress,
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.north_west_rounded, size: 16, color: Colors.grey),
                              onTap: () => _selectSearchResult(result),
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Quick City / Area Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickLocations.length,
                      itemBuilder: (context, idx) {
                        final item = _quickLocations[idx];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              item['name'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: 0.15),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () {
                              final target = LatLng(item['lat'] as double, item['lng'] as double);
                              setState(() {
                                _selectedPosition = target;
                                _searchResults = [];
                              });
                              _mapController.move(target, 16.5);
                              _currentZoom = 16.5;
                              _performReverseGeocode(target);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 3. Floating Map Style & Zoom Navigation Controls (Right Side)
            Positioned(
              right: 14,
              bottom: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Map Layers Menu (Google Streets, Satellite, Terrain)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
                      ],
                    ),
                    child: PopupMenuButton<MapTileType>(
                      tooltip: 'Google Map Styles',
                      icon: Icon(Icons.layers_rounded, color: widget.primaryColor, size: 24),
                      onSelected: (MapTileType type) {
                        setState(() {
                          _selectedMapType = type;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: MapTileType.googleStreet,
                          child: Row(
                            children: [
                              Icon(Icons.map_rounded, color: Colors.blue, size: 20),
                              SizedBox(width: 10),
                              Text('Google Maps (Default Detail)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: MapTileType.googleSatellite,
                          child: Row(
                            children: [
                              Icon(Icons.satellite_alt_rounded, color: Colors.green, size: 20),
                              SizedBox(width: 10),
                              Text('Google Satellite (Real Aerial)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: MapTileType.googleTerrain,
                          child: Row(
                            children: [
                              Icon(Icons.terrain_rounded, color: Colors.orange, size: 20),
                              SizedBox(width: 10),
                              Text('Google Terrain'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: MapTileType.openStreetMap,
                          child: Row(
                            children: [
                              Icon(Icons.streetview_rounded, color: Colors.purple, size: 20),
                              SizedBox(width: 10),
                              Text('OpenStreetMap Standard'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Zoom In (+)
                  _buildFloatingBtn(Icons.add, 'Zoom In', _zoomIn),

                  const SizedBox(height: 6),

                  // Zoom Out (-)
                  _buildFloatingBtn(Icons.remove, 'Zoom Out', _zoomOut),

                  const SizedBox(height: 10),

                  // Recenter to Pin (My Pin)
                  _buildFloatingBtn(Icons.my_location_rounded, 'Recenter to Pin', _recenterToPin, isPrimary: true),
                ],
              ),
            ),

            // 4. Coordinates Badge (Above bottom drawer)
            Positioned(
              left: 14,
              bottom: 215,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.greenAccent, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'GPS: ${_selectedPosition.latitude.toStringAsFixed(5)}, ${_selectedPosition.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Sleek Bottom Address Drawer & Confirmation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle & Status
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: widget.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isReverseGeocoding
                                  ? 'Fetching exact street details from Google Maps...'
                                  : 'Pinned Delivery Location',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _isReverseGeocoding ? widget.primaryColor : Colors.black87,
                              ),
                            ),
                          ),
                          if (_isReverseGeocoding)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Address inputs
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _addressController,
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Street / Building / House #',
                                labelStyle: GoogleFonts.outfit(fontSize: 12),
                                hintText: 'Tap on map or type landmark details...',
                                prefixIcon: Icon(Icons.home_outlined, color: widget.primaryColor, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _postcodeController,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Postcode',
                                labelStyle: GoogleFonts.outfit(fontSize: 12),
                                hintText: '54000',
                                prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Confirm Location Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, {
                              'latLng': _selectedPosition,
                              'address': _addressController.text.trim(),
                              'postcode': _postcodeController.text.trim(),
                            });
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 22),
                          label: Text(
                            'Confirm Delivery Location',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBtn(IconData icon, String tooltip, VoidCallback onPressed, {bool isPrimary = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isPrimary ? widget.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: isPrimary ? Colors.white : widget.primaryColor, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
