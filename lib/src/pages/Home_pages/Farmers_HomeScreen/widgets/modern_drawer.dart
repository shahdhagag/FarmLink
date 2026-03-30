import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Landing_pages/welcome.dart';
import '../Farmer_InventoryScreen.dart';

class ModernDrawer extends StatelessWidget {
  final Color primaryGreen = const Color.fromRGBO(51, 114, 51, 1.0);

  const ModernDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFFF8FAF8),
      child: Column(
        children: [
          // 1. Premium Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, const Color(0xFF2E5E2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(50)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color.fromRGBO(51, 114, 51, 1.0)),
                  ),
                  const SizedBox(height: 15),
                  const Text("Farmer Profile", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? "farmer@farmlink.com", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
          ),
          // 2. Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                _drawerLabel("Main Menu"),
                _customDrawerTile(Icons.dashboard_rounded, "Dashboard", () => Navigator.pop(context)),
                _customDrawerTile(
                  Icons.inventory_2_outlined,
                  "My Inventory",
                      () {
                    // 1. Close the drawer first
                    Navigator.pop(context);

                    // 2. Navigate to the Inventory Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FarmerInventoryScreen()),
                    );
                  },
                ),              ],
            ),
          ),
          // 3. Logout
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const welcome()), (r) => false),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                    SizedBox(width: 10),
                    Text("Logout Session", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 15, top: 10),
      child: Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _customDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryGreen, size: 24),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}