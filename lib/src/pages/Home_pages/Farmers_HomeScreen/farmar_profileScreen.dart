import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'EditProfileScreen.dart';

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({super.key});

  final Color primaryGreen = const Color(0xFF337233);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Listening to the specific farmer document in Firestore
        stream: FirebaseFirestore.instance.collection('Farmers').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If no data exists yet, we'll show defaults
          Map<String, dynamic> data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryGreen.withOpacity(0.1),
                        child: Icon(Icons.person, size: 60, color: primaryGreen),
                      ),
                      const SizedBox(height: 15),
                      const Text("Verified Farmer",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(data['fullName'] ?? "New Farmer",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(data['farmName'] ?? "Farm name not set",
                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Info Section
                _buildInfoTile(Icons.email_outlined, "Email Address", user?.email ?? "N/A"),
                _buildInfoTile(Icons.phone_android_outlined, "Phone Number", data['phone'] ?? "Not set"),
                _buildInfoTile(Icons.description_outlined, "About Farm", data['bio'] ?? "No description added"),
                _buildInfoTile(Icons.calendar_today_outlined, "Member Since", "March 2026"),

                const SizedBox(height: 40),

                // Edit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen(existingData: data)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text("EDIT PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          )
        ],
      ),
    );
  }
}