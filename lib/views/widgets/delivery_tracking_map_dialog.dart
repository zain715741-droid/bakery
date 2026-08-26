import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

enum TrackingMapTileType {
  googleStreet,
  googleSatellite,
  googleTerrain,
  openStreetMap,
}

class DeliveryTrackingMapDialog extends StatefulWidget {
  final OrderModel order;
  final Color primaryColor;
  final Color accentColor;
  final bool isDriverView;
  final OrderProvider? orderProvider;

  const DeliveryTrackingMapDialog({
    super.key,
    required this.order,
    required this.primaryColor,
    required this.accentColor,
    this.isDriverView = false,
    this.orderProvider,
  });

  @override
  State<DeliveryTrackingMapDialog> createState() => _DeliveryTrackingMapDialogState();
}

class _DeliveryTrackingMapDialogState extends State<DeliveryTrackingMapDialog> {
  late final LatLng _bakeryLocation;
  late final LatLng _customerLocation;
  late final MapController _mapController;
  TrackingMapTileType _selectedMapType = TrackingMapTileType.googleStreet;
  double _currentZoom = 14.5;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final custLat = widget.order.latitude ?? 31.5204;
    final custLng = widget.order.longitude ?? 74.3587;
    _customerLocation = LatLng(custLat, custLng);

    // Dynamic Bakery Location depending on customer region
    if (custLat > 20 && custLat < 40 && custLng > 60 && custLng < 80) {
      _bakeryLocation = const LatLng(31.5120, 74.3450); // Central Bakery Hub
    } else {
      _bakeryLocation = const LatLng(51.5074, -0.1278);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) *
            cos(p2.latitude * p) *
            (1 - cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _openGoogleMapsNavigation() async {
    final lat = _customerLocation.latitude;
    final lng = _customerLocation.longitude;
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch Google Maps: $googleMapsUrl");
    }
  }

  Future<void> _callCustomer() async {
    if (widget.order.customerPhone.isEmpty) return;
    final telUri = Uri.parse('tel:${widget.order.customerPhone}');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 20.0);
      final center = LatLng(
        (_bakeryLocation.latitude + _customerLocation.latitude) / 2,
        (_bakeryLocation.longitude + _customerLocation.longitude) / 2,
      );
      _mapController.move(center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 20.0);
      final center = LatLng(
        (_bakeryLocation.latitude + _customerLocation.latitude) / 2,
        (_bakeryLocation.longitude + _customerLocation.longitude) / 2,
      );
      _mapController.move(center, _currentZoom);
    });
  }

  void _recenterRoute() {
    final center = LatLng(
      (_bakeryLocation.latitude + _customerLocation.latitude) / 2,
      (_bakeryLocation.longitude + _customerLocation.longitude) / 2,
    );
    _mapController.move(center, 14.5);
  }

  String _getTileUrl() {
    switch (_selectedMapType) {
      case TrackingMapTileType.googleStreet:
        return 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case TrackingMapTileType.googleSatellite:
        return 'https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case TrackingMapTileType.googleTerrain:
        return 'https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case TrackingMapTileType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getSubdomains() {
    switch (_selectedMapType) {
      case TrackingMapTileType.googleStreet:
      case TrackingMapTileType.googleSatellite:
      case TrackingMapTileType.googleTerrain:
        return ['mt0', 'mt1', 'mt2', 'mt3'];
      case TrackingMapTileType.openStreetMap:
        return ['a', 'b', 'c'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _calculateDistanceKm(_bakeryLocation, _customerLocation);
    final etaMinutes = max(5, (distanceKm * 4.5).round());

    final centerLat = (_bakeryLocation.latitude + _customerLocation.latitude) / 2;
    final centerLng = (_bakeryLocation.longitude + _customerLocation.longitude) / 2;
    final mapCenter = LatLng(centerLat, centerLng);

    return Dialog.fullscreen(
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Fullscreen Google Map Canvas
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: _currentZoom,
                  maxZoom: 20.0,
                  minZoom: 3.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    subdomains: _getSubdomains(),
                    userAgentPackageName: 'com.google.android.apps.maps',
                    maxZoom: 20,
                    maxNativeZoom: 20,
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_bakeryLocation, _customerLocation],
                        strokeWidth: 5.0,
                        color: Colors.blue.shade700,
                        pattern: StrokePattern.dashed(segments: const [12, 6]),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Bakery Marker
                      Marker(
                        point: _bakeryLocation,
                        width: 90,
                        height: 65,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6),
                                ],
                              ),
                              child: const Text(
                                '🥖 Bakery Hub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.storefront_rounded, color: widget.primaryColor, size: 30),
                          ],
                        ),
                      ),

                      // Customer Marker
                      Marker(
                        point: _customerLocation,
                        width: 120,
                        height: 70,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6),
                                ],
                              ),
                              child: Text(
                                '🏠 ${widget.order.customerName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.location_on, color: Colors.red.shade700, size: 34),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Top Floating Header Card
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Order #${widget.order.invoiceNumber}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: widget.primaryColor),
                          ),
                          Text(
                            'Distance: ~${distanceKm.toStringAsFixed(1)} km  •  Est. Time: ~$etaMinutes mins',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openGoogleMapsNavigation,
                      icon: const Icon(Icons.navigation_rounded, size: 15),
                      label: const Text('Google Nav'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Map Controls (Right Side)
            Positioned(
              right: 14,
              bottom: 230,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                    ),
                    child: PopupMenuButton<TrackingMapTileType>(
                      tooltip: 'Google Map Styles',
                      icon: Icon(Icons.layers_rounded, color: widget.primaryColor, size: 24),
                      onSelected: (type) => setState(() => _selectedMapType = type),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: TrackingMapTileType.googleStreet, child: Text('Google Maps (Street)')),
                        PopupMenuItem(value: TrackingMapTileType.googleSatellite, child: Text('Google Satellite')),
                        PopupMenuItem(value: TrackingMapTileType.googleTerrain, child: Text('Google Terrain')),
                        PopupMenuItem(value: TrackingMapTileType.openStreetMap, child: Text('OpenStreetMap')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFloatingBtn(Icons.add, 'Zoom In', _zoomIn),
                  const SizedBox(height: 6),
                  _buildFloatingBtn(Icons.remove, 'Zoom Out', _zoomOut),
                  const SizedBox(height: 10),
                  _buildFloatingBtn(Icons.center_focus_strong_rounded, 'Center Route', _recenterRoute, isPrimary: true),
                ],
              ),
            ),

            // 4. Bottom Order Details & Dispatch Actions Drawer
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery To: ${widget.order.customerName}',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.order.customerAddress}, ${widget.order.customerPostcode}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                ),
                                if (widget.order.notes.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Notes: ${widget.order.notes.replaceAll('[Online Storefront Order]', '').trim()}',
                                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.brown.shade800),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.order.customerPhone.isNotEmpty)
                            IconButton.filled(
                              icon: const Icon(Icons.call_rounded, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                              tooltip: 'Call Customer',
                              onPressed: _callCustomer,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (widget.isDriverView && widget.orderProvider != null)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  widget.orderProvider!.updateOrderStatus(
                                    widget.order.id,
                                    OrderStatus.ready,
                                  );
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.electric_moped_rounded, size: 18),
                                label: const Text('Out for Delivery'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade900,
                                  side: BorderSide(color: Colors.blue.shade400),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  widget.orderProvider!.updateOrderStatus(
                                    widget.order.id,
                                    OrderStatus.completed,
                                  );
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                label: const Text('Mark Delivered'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleMapsNavigation,
                            icon: const Icon(Icons.directions_rounded, size: 22),
                            label: const Text('Start Turn-by-Turn Navigation (Google Maps)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
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
