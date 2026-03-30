import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:farmlink/ApiKey.dart';
import 'package:farmlink/src/pages/Home_pages/Farmers_HomeScreen/weather_pages/CloudsDay.dart';
import 'package:farmlink/src/pages/Home_pages/Farmers_HomeScreen/weather_pages/Rainyday.dart';
import 'package:farmlink/src/pages/Home_pages/Farmers_HomeScreen/weather_pages/SunnyDay.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'ApiModels/Apimodel.dart';

class Farmerweather extends StatefulWidget {
  const Farmerweather({super.key});

  @override
  State<Farmerweather> createState() => _FarmerweatherState();
}

class _FarmerweatherState extends State<Farmerweather> {
  final Color _green = const Color.fromRGBO(51, 114, 51, 1.0);

  final List<Widget> _weatherPages = const [
    SunnyDay(),
    Rainyday(),
    CloudsDay(),
  ];

  ApiModel? _apiData;
  int _pageIndex = 0;
  bool _isLoading = true;

  // FIX: store as non-nullable doubles with a sentinel
  double? _lat;
  double? _lon;

  // FIX: separate error state so we can show a proper UI instead of
  //      silently falling back to 0,0 (which gives "Mountain View")
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  // ─── Location helper (replaces GetLocation to handle all permission cases) ─

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          "Location services are disabled. Please turn on GPS and try again.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            "Location permission denied. Please allow location access.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          "Location permission is permanently denied. Enable it in app settings.");
    }

    // FIX: timeout prevents hanging indefinitely
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );
  }

  // ─── Main fetch ────────────────────────────────────────────────────────────

  Future<void> _fetchWeatherData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _locationError = null;
    });

    try {
      final position = await _getCurrentPosition();

      // FIX: guard against the OpenWeather "Mountain View" default (0,0)
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        throw Exception("Device returned an invalid location (0, 0). "
            "Please enable GPS and retry.");
      }

      _lat = position.latitude;
      _lon = position.longitude;

      final res = await http
          .get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
              '?lat=$_lat&lon=$_lon'
              '&appid=${ApiKey.weatherApiKey}'
              '&units=metric'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _apiData = ApiModel.fromMap(data);
          _updatePageIndex();
        });
      } else {
        throw Exception("Weather API error: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Weather fetch error: $e");
      if (!mounted) return;
      setState(() => _locationError = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updatePageIndex() {
    // FIX: weatherMain is non-nullable in ApiModel — do NOT use ?.toLowerCase()
    final condition = _apiData!.weatherMain.toLowerCase();
    if (condition.contains("cloud")) {
      _pageIndex = 2;
    } else if (condition.contains("rain") ||
        condition.contains("drizzle") ||
        condition.contains("thunderstorm")) {
      _pageIndex = 1;
    } else {
      _pageIndex = 0;
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon: const Icon(CupertinoIcons.bars, color: Colors.white, size: 26),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchWeatherData,
            icon: const Icon(CupertinoIcons.refresh_circled,
                color: Colors.white, size: 26),
            tooltip: "Refresh",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 15, color: _green),
            const SizedBox(height: 16),
            const Text("Fetching weather…",
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      )
          : _locationError != null
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: _fetchWeatherData,
        color: _green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Weather animation
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                width: double.infinity,
                child: _weatherPages[_pageIndex],
              ),

              // Stats glass card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildWeatherCard(),
              ),

              // Bottom nav breathing room
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Error state ───────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.location_slash_fill,
                color: _green, size: 56),
            const SizedBox(height: 20),
            Text(
              _locationError ?? "Unknown error",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _fetchWeatherData,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 18),
              label: const Text("Try Again",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Weather card ──────────────────────────────────────────────────────────

  Widget _buildWeatherCard() {
    // FIX: temp & windSpeed are non-nullable doubles — call .round() directly
    final tempStr =
    _apiData != null ? "${_apiData!.temp.round()}°C" : "--";
    final humidityStr =
    _apiData != null ? "${_apiData!.humidity.round()}%" : "--";
    final windStr =
    _apiData != null ? "${_apiData!.windSpeed.round()} m/s" : "--";

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              // Stat row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn("Temp", tempStr, CupertinoIcons.thermometer),
                  _divider(),
                  _statColumn("Humidity", humidityStr, CupertinoIcons.drop),
                  _divider(),
                  _statColumn("Wind", windStr, CupertinoIcons.wind),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 16),

              // City name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.location_solid, color: _green, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _apiData?.cityName ?? "---",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),

              const SizedBox(height: 10),
              if (_apiData != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _apiData!.weatherDescription
                        .split(' ')
                        .map((w) =>
                    w[0].toUpperCase() + w.substring(1))
                        .join(' '),
                    style: TextStyle(
                        color: _green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _green, size: 18),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08));

  // ─── Drawer ────────────────────────────────────────────────────────────────
  // FIX: removed NetworkImage (Unsplash) — replaced with a simple gradient
  //      header so the drawer always renders offline without any errors.

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: Column(
        children: [
          // Header — no network dependency
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _green.withOpacity(0.7),
                  const Color(0xFF0A2E0A),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Farmlink Weather",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_apiData != null)
                  Text(
                    _apiData!.cityName,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
              ],
            ),
          ),

          // Tiles
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _drawerTile(
                  "Condition",
                  _apiData?.weatherDescription ?? "---",
                  CupertinoIcons.cloud_sun_fill,
                ),
                _drawerTile(
                  "Pressure",
                  _apiData != null
                      ? "${_apiData!.pressure.round()} hPa"
                      : "---",
                  CupertinoIcons.gauge,
                ),
                _drawerTile(
                  "Humidity",
                  _apiData != null
                      ? "${_apiData!.humidity.round()}%"
                      : "---",
                  CupertinoIcons.drop_fill,
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.07)),
                const SizedBox(height: 8),
                _drawerTile(
                  "Latitude",
                  _lat != null ? _lat!.toStringAsFixed(5) : "---",
                  Icons.pin_drop_outlined,
                ),
                _drawerTile(
                  "Longitude",
                  _lon != null ? _lon!.toStringAsFixed(5) : "---",
                  Icons.explore_outlined,
                ),
              ],
            ),
          ),

          // Refresh button at bottom of drawer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // close drawer
                  _fetchWeatherData();
                },
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
                label: const Text("Refresh Weather",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: _green, size: 20),
        title: Text(title,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        trailing: Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}