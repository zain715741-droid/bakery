import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

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
  State<DeliveryTrackingMapDialog> createState() =>
      _DeliveryTrackingMapDialogState();
}

class _DeliveryTrackingMapDialogState extends State<DeliveryTrackingMapDialog> {
  late final LatLng _bakeryLocation;
  late final LatLng _customerLocation;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Default Bakery Central Location
    _bakeryLocation = const LatLng(51.5074, -0.1278);

    // Customer Location (use saved coordinates or offset fallback)
    _customerLocation = LatLng(
      widget.order.latitude ?? 51.5180,
      widget.order.longitude ?? -0.1380,
    );
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) *
            cos(p2.latitude * p) *
            (1 - cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
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

  @override
  Widget build(BuildContext context) {
    final distanceKm = _calculateDistanceKm(_bakeryLocation, _customerLocation);
    final etaMinutes = max(5, (distanceKm * 4.5).round());

    final centerLat =
        (_bakeryLocation.latitude + _customerLocation.latitude) / 2;
    final centerLng =
        (_bakeryLocation.longitude + _customerLocation.longitude) / 2;
    final mapCenter = LatLng(centerLat, centerLng);

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 850 ? 800.0 : screenSize.width * 0.95;
    final dialogHeight = screenSize.height > 850 ? 720.0 : screenSize.height * 0.85;

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
                  Icon(Icons.map_rounded, color: widget.accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Live Delivery Route & Dispatch Map',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
                // Top Dispatch Summary Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: const Color(0xFFFBF8F2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delivery_dining_rounded,
                          color: widget.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice: ${widget.order.invoiceNumber}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: widget.primaryColor,
                              ),
                            ),
                            Text(
                              'Distance: ~${distanceKm.toStringAsFixed(1)} km  •  Est. Travel Time: ~$etaMinutes mins',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openGoogleMapsNavigation,
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: const Text('GPS Nav'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive Map with Polyline and Markers
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bakery.app',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_bakeryLocation, _customerLocation],
                            strokeWidth: 4.5,
                            color: widget.primaryColor,
                            pattern: StrokePattern.dashed(
                              segments: const [12, 6],
                            ),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // 1. Bakery Origin Marker
                          Marker(
                            point: _bakeryLocation,
                            width: 80,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '🥖 Bakery',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.store_mall_directory_rounded,
                                  color: widget.primaryColor,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),

                          // 2. Customer Destination Marker
                          Marker(
                            point: _customerLocation,
                            width: 100,
                            height: 65,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🏠 ${widget.order.customerName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.location_on,
                                  color: Colors.red.shade700,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Customer & Delivery Boy Actions Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery To: ${widget.order.customerName}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.order.customerAddress}, ${widget.order.customerPostcode}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (widget.order.notes.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Notes: ${widget.order.notes.replaceAll('[Online Storefront Order]', '').trim()}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.brown.shade800,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.order.customerPhone.isNotEmpty)
                              IconButton.filled(
                                icon: const Icon(Icons.call_rounded, size: 18),
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

                        // Delivery Driver Status Progress Actions
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
                                  icon: const Icon(
                                    Icons.electric_moped_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Out for Delivery'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue.shade900,
                                    side: BorderSide(
                                      color: Colors.blue.shade400,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                  icon: const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Mark Delivered'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                              icon: const Icon(Icons.directions_rounded),
                              label: const Text(
                                'Start Turn-by-Turn Navigation (Google Maps)',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
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
