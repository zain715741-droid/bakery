import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationSearchResult {
  final String title;
  final String fullAddress;
  final LatLng latLng;
  final String? postcode;
  final String? city;

  const LocationSearchResult({
    required this.title,
    required this.fullAddress,
    required this.latLng,
    this.postcode,
    this.city,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0.0;
    final addressMap = json['address'] as Map<String, dynamic>? ?? {};

    final name = json['name']?.toString();
    final road = addressMap['road']?.toString();
    final suburb = addressMap['suburb']?.toString();
    final city = addressMap['city']?.toString() ??
        addressMap['town']?.toString() ??
        addressMap['state']?.toString() ??
        '';
    final postcode = addressMap['postcode']?.toString();

    String title = name?.isNotEmpty == true
        ? name!
        : (road?.isNotEmpty == true ? road! : (suburb?.isNotEmpty == true ? suburb! : city));
    if (title.isEmpty) {
      title = json['display_name']?.toString().split(',').first ?? 'Location';
    }

    return LocationSearchResult(
      title: title,
      fullAddress: json['display_name']?.toString() ?? '',
      latLng: LatLng(lat, lon),
      postcode: postcode,
      city: city,
    );
  }
}

class GeocodingService {
  static const String _nominatimSearchUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _nominatimReverseUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const Map<String, String> _headers = {
    'User-Agent': 'BakeryPosStorefront/1.0 (com.bakery.app)',
    'Accept-Language': 'en',
  };

  /// Search locations by text query using OpenStreetMap Nominatim
  static Future<List<LocationSearchResult>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final uri = Uri.parse(
        '$_nominatimSearchUrl?q=${Uri.encodeQueryComponent(trimmed)}&format=json&addressdetails=1&limit=6',
      );
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => LocationSearchResult.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Geocoding search error: $e');
    }
    return [];
  }

  /// Reverse geocode coordinates to human-readable address
  static Future<LocationSearchResult?> reverseGeocode(LatLng latLng) async {
    try {
      final uri = Uri.parse(
        '$_nominatimReverseUrl?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json&addressdetails=1',
      );
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return LocationSearchResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }
}
