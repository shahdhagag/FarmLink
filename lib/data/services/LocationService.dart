import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:farmlink/data/models/weather_model.dart';

import '../../core/constants/app_constants.dart';

class LocationService {
  // ─── Permission-safe location getter ─────────────────────────────────────

  Future<Position> getCurrentPosition() async {
    // 1. Check if GPS service is on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Prompt the user to turn on GPS
      await Geolocator.openLocationSettings();
      return _getPositionFromIp();
    }

    // 2. Handle permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return _getPositionFromIp();
    }
    if (permission == LocationPermission.denied) {
      return _getPositionFromIp();
    }

    // 3. Build platform-specific location settings (geolocator 13+)
    final LocationSettings settings = _buildLocationSettings();

    // 4. Use a position stream — most reliable on Android
    try {
      final position = await Geolocator.getPositionStream(
        locationSettings: settings,
      ).first.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw TimeoutException('GPS timed out'),
      );
      return position;
    } on TimeoutException {
      // GPS too slow — try cached position next
    } catch (_) {}

    // 5. Try last known position (instant)
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
    } catch (_) {}

    // 6. Final fallback: IP-based geolocation
    return _getPositionFromIp();
  }

  /// Build platform-appropriate LocationSettings for geolocator 13+
  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  // ─── IP-based geolocation fallback ───────────────────────────────────────

  /// Uses ip-api.com (free, no key needed) for city-level coordinates.
  Future<Position> _getPositionFromIp() async {
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=lat,lon,status'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          return Position(
            latitude: (json['lat'] as num).toDouble(),
            longitude: (json['lon'] as num).toDouble(),
            timestamp: DateTime.now(),
            accuracy: 5000,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      }
    } catch (_) {}
    throw Exception(
        'Could not get your location.\nPlease enable GPS in your device settings and try again.');
  }

  // ─── Geocoding ────────────────────────────────────────────────────────────

  Future<String> getAddressFromPosition(Position position) async {
    try {
      final placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) return 'Unknown location';
      final p = placemarks.first;
      return [
        if (p.name?.isNotEmpty == true) p.name,
        if (p.locality?.isNotEmpty == true) p.locality,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea,
        if (p.country?.isNotEmpty == true) p.country,
      ].join(', ');
    } catch (_) {
      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }

  // ─── Weather API ──────────────────────────────────────────────────────────

  Future<WeatherModel> getWeather(double lat, double lon) async {
    if (lat == 0.0 && lon == 0.0) {
      throw Exception('Invalid coordinates. Please enable GPS.');
    }

    final response = await http
        .get(Uri.parse('https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon'
        '&appid=${AppConstants.weatherApiKey}'
        '&units=metric'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return WeatherModel.fromMap(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Weather API error: ${response.statusCode}');
  }
}