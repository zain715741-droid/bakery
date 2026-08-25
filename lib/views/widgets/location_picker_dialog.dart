import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerDialog extends StatefulWidget {
  final LatLng initialLocation;
  final String initialAddress;
  final Color primaryColor;
  final Color accentColor;

  const LocationPickerDialog({
    super.key,
    required this.initialLocation,
    this.initialAddress = '',
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng _selectedPosition;
  late final MapController _mapController;
  final TextEditingController _addressController = TextEditingController();

  final List<Map<String, dynamic>> _quickLocations = [
    {'name': 'Central London', 'lat': 51.5074, 'lng': -0.1278},
    {'name': 'Westminster', 'lat': 51.4975, 'lng': -0.1357},
    {'name': 'Kensington', 'lat': 51.5014, 'lng': -0.1919},
    {'name': 'Camden Town', 'lat': 51.5390, 'lng': -0.1426},
    {'name': 'Lahore Gulberg', 'lat': 31.5204, 'lng': 74.3587},
    {'name': 'Karachi Clifton', 'lat': 24.8138, 'lng': 67.0300},
    {'name': 'Islamabad F-7', 'lat': 33.7215, 'lng': 73.0551},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialLocation;
    _mapController = MapController();
    _addressController.text = widget.initialAddress;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onTapMap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedPosition = latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 800 ? 750.0 : screenSize.width * 0.95;
    final dialogHeight = screenSize.height > 800 ? 680.0 : screenSize.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.add_location_alt_rounded, color: widget.accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Pin Delivery Location',
                    style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: Column(
              children: [
                // Quick Location Jump Chips
                Container(
                  height: 48,
                  color: const Color(0xFFFBF9F5),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: _quickLocations.length,
                    itemBuilder: (context, idx) {
                      final item = _quickLocations[idx];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: Icon(Icons.near_me_rounded, size: 14, color: widget.primaryColor),
                          label: Text(item['name'] as String, style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          onPressed: () {
                            final target = LatLng(item['lat'] as double, item['lng'] as double);
                            setState(() {
                              _selectedPosition = target;
                            });
                            _mapController.move(target, 15.0);
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Interactive FlutterMap View
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedPosition,
                          initialZoom: 14.5,
                          onTap: _onTapMap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.bakery.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedPosition,
                                width: 60,
                                height: 60,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: widget.primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.home_filled,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: widget.primaryColor,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Instruction Overlay Badge
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_rounded, color: widget.primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap anywhere on the map to place your delivery pin accurately.',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Coordinates Floating Badge
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'GPS: ${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Address Confirmation Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Building / Street / Landmark Details',
                            hintText: 'e.g. Flat 4B, Baker Street, near Central Park',
                            prefixIcon: Icon(Icons.place_outlined, color: widget.primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context, {
                                'latLng': _selectedPosition,
                                'address': _addressController.text.trim(),
                              });
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Confirm Delivery Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
