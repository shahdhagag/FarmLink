import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Landing_pages/welcome.dart';
import 'FarmerCropDetail.dart';
import 'Farmer_AddScreen.dart';
import 'farmar_profileScreen.dart';

class FarmerHomescreen extends StatefulWidget {
  const FarmerHomescreen({super.key});

  @override
  State<FarmerHomescreen> createState() => _FarmerHomescreenState();
}

class _FarmerHomescreenState extends State<FarmerHomescreen> {
  final Color primaryGreen = const Color(0xFF337233);
  final Color background = const Color(0xFFF8FAF8);
  final User? user = FirebaseAuth.instance.currentUser;

  // --- MODERN DELETE LOGIC ---
  Future<void> _deleteCrop(String docId) async {
    bool confirmed = await _showDeleteConfirmation();
    if (confirmed) {
      // No need to call setState or fetch; the StreamBuilder handles it!
      await FirebaseFirestore.instance.collection("CropMain").doc(docId).delete();
      HapticFeedback.lightImpact();
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade600, size: 38),
              ),
              const SizedBox(height: 20),
              const Text("Remove Listing?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                "This crop will be permanently removed. This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Harvest Inventory",
                style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 22)),
            const Text("Live Marketplace Sync",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.notes_rounded, color: primaryGreen, size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildModernDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        // This keeps a live connection to your data
        stream: FirebaseFirestore.instance
            .collection("CropMain")
            .where("FarmerUID", isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Connection Error"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              // Prepare the data map for the Card and Detail Screen
              final cropMap = {
                'id': docs[index].id,
                ...data,
                'product': data['Product'],
                'costPerKg': data['CostPerKg'],
                'availability': data['Availability'],
                'uploadDate': data['CropUploadedDate'],
                'cropType': data['Croptype'],
                'rating': data['CropRating'],
              };

              return _ModernCropCard(
                crop: cropMap,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Farmercropdetailcrop(crop: cropMap))),
                onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerAddScreen(existingCrop: cropMap))),
                onDelete: () => _deleteCrop(docs[index].id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 100, color: primaryGreen.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text("No crops currently listed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          const Text("Start selling by adding your first product", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          // --- CUSTOM MODERN HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, size: 45, color: Color(0xFF337233)),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Welcome Back,",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  user?.email?.split('@')[0].toUpperCase() ?? "FARMER",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- DRAWER ITEMS ---
          _drawerTile(
            icon: Icons.dashboard_customize_rounded,
            title: "My Inventory",
            onTap: () => Navigator.pop(context),
          ),
          _drawerTile(
            icon: Icons.account_circle_outlined,
            title: "Farmer Profile",
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerProfileScreen()));
            },
          ),


          const Spacer(),

          // --- LOGOUT SECTION ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const welcome()),
                        (route) => false,
                  );
                },
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  "Sign Out",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

// Helper for clean drawer tiles
  Widget _drawerTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: Colors.grey[700], size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _ModernCropCard extends StatelessWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ModernCropCard({required this.crop, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF337233);
    final bool isOrganic = crop['cropType'] == 'Organic';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      height: 60, width: 60,
                      decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                      child: Icon(Icons.grass_rounded, color: primaryGreen, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(crop['product'] ?? "Unnamed", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              const SizedBox(width: 8),
                              _badge(isOrganic ? "ORGANIC" : "HYBRID", isOrganic ? Colors.green : Colors.blue),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("Uploaded: ${crop['uploadDate']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    _actionMenu(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: primaryGreen.withOpacity(0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBit(Icons.payments_outlined, "₹${crop['costPerKg']}/kg"),
                    _infoBit(Icons.inventory_2_outlined, "${crop['availability']} kg"),
                    _infoBit(Icons.star_rounded, "${crop['rating']}", color: Colors.amber),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoBit(IconData icon, String text, {Color color = Colors.grey}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D3436))),
      ],
    );
  }

  Widget _actionMenu() {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        PopupMenuItem(onTap: onEdit, child: const Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text("Edit")])),
        PopupMenuItem(onTap: onDelete, child: const Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
      ],
    );
  }
}