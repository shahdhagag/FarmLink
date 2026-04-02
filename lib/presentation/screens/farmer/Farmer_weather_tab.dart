import 'dart:ui';

import 'package:farmlink/core/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../data/models/weather_model.dart';
import '../../providers/app_provider.dart';

class FarmerWeatherTab extends ConsumerStatefulWidget {
  const FarmerWeatherTab({super.key});

  @override
  ConsumerState<FarmerWeatherTab> createState() => _FarmerWeatherTabState();
}

class _FarmerWeatherTabState extends ConsumerState<FarmerWeatherTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weatherProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon:
                const Icon(CupertinoIcons.bars, color: Colors.white, size: 26),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(weatherProvider.notifier).fetch(),
            icon: const Icon(CupertinoIcons.refresh_circled,
                color: Colors.white, size: 24),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(weather),
      body: _buildBody(weather),
    );
  }

  Widget _buildBody(WeatherState weather) {
    // 1. DATA PRESENT: Show the data (even if we are currently reloading in background)
    if (weather.data != null) {
      return _buildWeatherData(weather);
    }

    // 2. LOADING: Show spinner (only if no data)
    if (weather.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 16, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Fetching weather…',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }

    // 3. ERROR: Show error (only if no data)
    if (weather.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.location_slash_fill,
                  color: AppColors.primary, size: 56),
              const SizedBox(height: 20),
              Text(
                weather.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => ref.read(weatherProvider.notifier).fetch(),
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Try Again',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. IDLE / INITIAL STATE: (Should theoretically be handled by loading case)
    return Center(
        child: TextButton(
            onPressed: () => ref.read(weatherProvider.notifier).fetch(),
            child: const Text('Get Weather Data')));
  }

  Widget _buildWeatherData(WeatherState weather) {
    final data = weather.data!;
    final pageIndex = data.weatherPageIndex;

    return RefreshIndicator(
      onRefresh: () => ref.read(weatherProvider.notifier).fetch(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            children: [
              // Weather animation
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                width: double.infinity,
                child: _buildWeatherAnimation(pageIndex),
              ),

              // Glass info card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildWeatherCard(data, weather.lat, weather.lon),
              ),

              SizedBox(height: 110.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherAnimation(int index) {
    switch (index) {
      case 1:
        return const RainyDay();
      case 2:
        return const CloudyDay();
      default:
        return const SunnyDay();
    }
  }

  Widget _buildWeatherCard(WeatherModel d, double? lat, double? lon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20.r,
                spreadRadius: 5.r,
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCol('Temp', '${d.temp.round()}°C', CupertinoIcons.thermometer),
                  _vDivider(),
                  _StatCol('Humidity', '${d.humidity.round()}%', CupertinoIcons.drop),
                  _vDivider(),
                  _StatCol('Wind', '${d.windSpeed.round()} m/s', CupertinoIcons.wind),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(color: Colors.white.withOpacity(0.08)),
              SizedBox(height: 16.h),

              // City
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(CupertinoIcons.location_solid, color: AppColors.primary, size: 18.sp),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    d.cityName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              SizedBox(height: 6.h),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: TextStyle(color: Colors.white38, fontSize: 13.sp),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  d.displayDescription,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 10.h),
              // Extra stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ExtraStat('Feels Like', '${d.feelsLike.round()}°'),
                  const SizedBox(width: 20),
                  _ExtraStat('Pressure', '${d.pressure.round()} hPa'),
                  const SizedBox(width: 20),
                  _ExtraStat('Clouds', '${d.clouds}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _StatCol(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: AppColors.primary, size: 20.sp),
      SizedBox(height: 8.h),
      Text(value,
          style: TextStyle(
              color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w700)),
      SizedBox(height: 2.h),
      Text(label, style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
    ]);
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40.h, color: Colors.white.withOpacity(0.08));

  Widget _ExtraStat(String label, String value) {
    return Column(children: [
      Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
      SizedBox(height: 3.h),
      Text(value,
          style: TextStyle(
              color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildDrawer(WeatherState weather) {
    final d = weather.data;
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.7),
                const Color(0xFF0A2E0A),
              ],
            ),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white.withOpacity(0.15),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('FarmLink Weather',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            if (d != null)
              Text(d.cityName,
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _DrawerTile('Condition', d?.displayDescription ?? '---',
                  CupertinoIcons.cloud_sun_fill),
              _DrawerTile(
                  'Pressure',
                  d != null ? '${d.pressure.round()} hPa' : '---',
                  CupertinoIcons.gauge),
              _DrawerTile(
                  'Humidity',
                  d != null ? '${d.humidity.round()}%' : '---',
                  CupertinoIcons.drop_fill),
              _DrawerTile(
                  'Visibility',
                  d != null
                      ? '${(d.visibility / 1000).toStringAsFixed(1)} km'
                      : '---',
                  CupertinoIcons.eye),
              Divider(color: Colors.white.withOpacity(0.07)),
              _DrawerTile('Latitude', weather.lat?.toStringAsFixed(5) ?? '---',
                  Icons.pin_drop_outlined),
              _DrawerTile('Longitude', weather.lon?.toStringAsFixed(5) ?? '---',
                  Icons.explore_outlined),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ref.read(weatherProvider.notifier).fetch();
              },
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Refresh Weather',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _DrawerTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(title,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        trailing: Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}

class SunnyDay extends StatefulWidget {
  const SunnyDay({super.key});

  @override
  State<SunnyDay> createState() => _SunnyDayState();
}

class _SunnyDayState extends State<SunnyDay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.yellow,
                Colors.orange.withOpacity(0.8),
                Colors.transparent
              ],
              stops: const [0.4, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child:
              Icon(Icons.wb_sunny_rounded, size: 80, color: Colors.yellow[100]),
        ),
      ),
    );
  }
}

class RainyDay extends StatefulWidget {
  const RainyDay({super.key});

  @override
  State<RainyDay> createState() => _RainyDayState();
}

class _RainyDayState extends State<RainyDay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(
            child: Icon(CupertinoIcons.cloud_rain_fill,
                size: 100, color: Colors.blueGrey)),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: RainPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class RainPainter extends CustomPainter {
  final double progress;

  RainPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 2;
    for (int i = 0; i < 20; i++) {
      double x = (size.width / 20) * i + (i * 5);
      double y = (size.height * ((progress + (i * 0.1)) % 1.0));
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 15), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CloudyDay extends StatefulWidget {
  const CloudyDay({super.key});

  @override
  State<CloudyDay> createState() => _CloudyDayState();
}

class _CloudyDayState extends State<CloudyDay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _animation =
        Tween<Offset>(begin: const Offset(-0.1, 0), end: const Offset(0.1, 0))
            .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SlideTransition(
        position: _animation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(CupertinoIcons.cloud_fill,
                size: 120, color: Colors.white.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 60),
              child: Icon(CupertinoIcons.cloud_fill,
                  size: 80, color: Colors.white.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
