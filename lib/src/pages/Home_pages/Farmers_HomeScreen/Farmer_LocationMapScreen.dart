import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class FarmerLocationMapScreen extends StatefulWidget {
  final String locationText;
  final String cropName;
  final String? phoneNumber;

  const FarmerLocationMapScreen({
    super.key,
    required this.locationText,
    required this.cropName,
    this.phoneNumber,
  });

  @override
  State<FarmerLocationMapScreen> createState() => _FarmerLocationMapScreenState();
}

class _FarmerLocationMapScreenState extends State<FarmerLocationMapScreen> {
  LatLng? _position;
  String? _errorMessage;
  bool _loading = true;
  String _displayAddress = '';

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _geocodeLocation();
  }

  Future<void> _geocodeLocation() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final query = Uri.encodeComponent(widget.locationText.trim());
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FarmMate-App/1.0 (contact@farmmate.app)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat'].toString());
          final double lon = double.parse(data[0]['lon'].toString());
          if (!mounted) return;
          setState(() {
            _position = LatLng(lat, lon);
            _displayAddress = data[0]['display_name'] ?? widget.locationText;
            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Location not found. Try a more specific city or district.';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Service error. Please try again later.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Check your internet connection.';
        _loading = false;
      });
    }
  }

  Future<void> _openExternalMap() async {
    if (_position == null) return;
    final lat = _position!.latitude;
    final lon = _position!.longitude;

    // Fixed: Standard geo URI for Google Maps/Apple Maps
    final mapUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    final browserUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');

    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      await launchUrl(browserUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callFarmer() async {
    if (widget.phoneNumber == null || widget.phoneNumber!.isEmpty) return;
    final uri = Uri.parse('tel:${widget.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF337233),
        elevation: 0,
        title: Text(
          widget.cropName,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        actions: [
          if (_position != null)
            IconButton(
              onPressed: _openExternalMap,
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            ),
        ],
      ),
      body: _loading
          ? _buildLoader()
          : _errorMessage != null
          ? _buildError()
          : _buildMap(),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF337233)),
          SizedBox(height: 16),
          Text('Locating farmer...', style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, color: Color(0xFF9CA3AF), size: 64),
            const SizedBox(height: 20),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _geocodeLocation,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF337233)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _position!,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.farmmate.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _position!,
                    width: 80,
                    height: 80,
                    child: _FarmerMarker(cropName: widget.cropName),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildBottomCard(),
      ],
    );
  }

  Widget _buildBottomCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF337233)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _displayAddress.isNotEmpty ? _displayAddress : widget.locationText,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.map,
                  label: 'Directions',
                  color: const Color(0xFF337233),
                  onTap: _openExternalMap,
                ),
              ),
              if (widget.phoneNumber != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.call,
                    label: 'Call',
                    color: const Color(0xFF1A5276),
                    onTap: _callFarmer,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FarmerMarker extends StatelessWidget {
  final String cropName;
  const _FarmerMarker({required this.cropName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF337233),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cropName,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.location_on, color: const Color(0xFF337233), size: 40),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}