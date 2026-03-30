import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Landing_pages/welcome.dart';
import 'BuyerCropDetails.dart';

class BuyerMainHome extends StatefulWidget {
  const BuyerMainHome({super.key});

  @override
  State<BuyerMainHome> createState() => _BuyerMainHomeState();
}

class _BuyerMainHomeState extends State<BuyerMainHome> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Organic', 'Hybrid'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Marketplace",
          style: TextStyle(
            fontFamily: 'Poppins-SemiBold',
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF337233)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(
                fontFamily: 'Poppins-SemiBold',
                fontSize: 14,
                color: Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Search crops, farmers…',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontFamily: 'Poppins-SemiBold',
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF9CA3AF), size: 20),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF337233), width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final selected = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF337233)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Crop grid ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('CropMain')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF337233)),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }

                var docs = snapshot.data!.docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .where((crop) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final product =
                    (crop["Product"] ?? '').toString().toLowerCase();
                    final farmer =
                    (crop["FarmerName"] ?? '').toString().toLowerCase();
                    final location =
                    (crop["Location"] ?? '').toString().toLowerCase();
                    if (!product.contains(_searchQuery) &&
                        !farmer.contains(_searchQuery) &&
                        !location.contains(_searchQuery)) {
                      return false;
                    }
                  }
                  // Type filter
                  if (_selectedFilter != 'All') {
                    final type =
                    (crop["Croptype"] ?? '').toString();
                    if (type != _selectedFilter) return false;
                  }
                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return _buildEmpty(message: 'No results found');
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _CropCard(
                      crop: docs[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CropDetailsPage(cropDetails: docs[index]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({String message = 'No crops available'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco_outlined,
              color: Color(0xFFD1D5DB), size: 64),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontFamily: 'Poppins-SemiBold',
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            child: Container(
              color: const Color(0xFF337233),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_basket_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Buyer Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins-SemiBold',
                    ),
                  ),
                  if (user?.email != null)
                    Text(
                      user!.email!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontFamily: 'Poppins-SemiBold',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const welcome()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                label: const Text("Logout",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins-SemiBold')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF337233),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crop card widget ──────────────────────────────────────────────────────────
class _CropCard extends StatelessWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onTap;

  const _CropCard({required this.crop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double rating =
        double.tryParse(crop["CropRating"]?.toString() ?? '0') ?? 0;
    final int filledStars = rating.floor().clamp(0, 5);
    final cropType = crop["Croptype"]?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colored top banner ────────────────────────────────────────
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF337233).withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.eco_rounded,
                      color: const Color(0xFF337233).withOpacity(0.25),
                      size: 56,
                    ),
                  ),
                  if (cropType.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cropType == 'Organic'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cropType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins-SemiBold',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop["Product"] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF111827),
                      fontFamily: 'Poppins-SemiBold',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${crop["CostPerKg"] ?? "N/A"} / kg",
                    style: const TextStyle(
                      color: Color(0xFF337233),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Poppins-SemiBold',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                          (i) => Icon(
                        i < filledStars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: i < filledStars
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFE5E7EB),
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          crop["Location"] ?? "Unknown",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9CA3AF),
                            fontFamily: 'Poppins-SemiBold',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}