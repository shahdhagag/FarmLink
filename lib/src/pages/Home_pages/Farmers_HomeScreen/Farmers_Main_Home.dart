import 'package:farmlink/src/pages/Home_pages/Farmers_HomeScreen/widgets/modern_drawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Farmer_HomeScreen.dart';
import 'Farmer_AddScreen.dart';
import 'FarmerWeather.dart';

class FarmersMainHome extends StatefulWidget {
  const FarmersMainHome({super.key});

  @override
  State<FarmersMainHome> createState() => _FarmersMainHomeState();
}

class _FarmersMainHomeState extends State<FarmersMainHome> {
  int _selectedIndex = 0;
  final Color primaryGreen = const Color.fromRGBO(51, 114, 51, 1.0);


  // Pages to display
  List<Widget> get _pages => [
    const FarmerHomescreen(),
    FarmerAddScreen(onBackToHome: () => setState(() => _selectedIndex = 0)),
    const Farmerweather(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. The Drawer MUST be here
      drawer: const ModernDrawer(),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildModernNavBar(),
    );
  }

  Widget _buildModernNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_rounded, "Home", 0),
          _navItem(CupertinoIcons.plus_circle_fill, "Add", 1),
          _navItem(CupertinoIcons.cloud_sun_fill, "Weather", 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white60, size: isActive ? 26 : 24),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}