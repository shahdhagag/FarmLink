import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Farmers_HomeScreen/Farmer_LocationMapScreen.dart';

class CropDetailsPage extends StatelessWidget {
  final Map<String, dynamic> cropDetails;

  const CropDetailsPage({super.key, required this.cropDetails});

  Future<void> _callFarmer(BuildContext context) async {
    final phone = cropDetails["PhoneNumber"]?.toString() ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = cropDetails["Product"] ?? "Crop Details";
    final location = cropDetails["Location"]?.toString() ?? '';
    final phone = cropDetails["PhoneNumber"]?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF337233),
        elevation: 0,
        title: Text(
          product,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins-SemiBold',
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF337233),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF337233).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.eco_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins-SemiBold',
                              ),
                            ),
                            Text(
                              cropDetails["Croptype"] ?? 'Crop',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontFamily: 'Poppins-SemiBold',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _HeroPill(
                        label: '₹${cropDetails["CostPerKg"] ?? "N/A"}/kg',
                        icon: Icons.currency_rupee_rounded,
                      ),
                      const SizedBox(width: 10),
                      _HeroPill(
                        label: '${cropDetails["Availability"] ?? "N/A"} kg',
                        icon: Icons.inventory_2_rounded,
                      ),
                      const SizedBox(width: 10),
                      _HeroPill(
                        label: cropDetails["PriceType"] ?? "N/A",
                        icon: Icons.handshake_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Rating row ─────────────────────────────────────────────────
            _buildRatingRow(cropDetails["CropRating"]),

            const SizedBox(height: 20),

            // ── Details card ───────────────────────────────────────────────
            _SectionCard(
              title: 'Crop Info',
              icon: Icons.info_outline_rounded,
              children: [
                _DetailRow('Crop Type', cropDetails["Croptype"]),
                _DetailRow('Harvest Date', cropDetails["HarvestDate"]),
                _DetailRow('Expiry Date', cropDetails["ExpiryDate"]),
                _DetailRow('Listed On', cropDetails["CropUploadedDate"]),
              ],
            ),

            const SizedBox(height: 16),

            // ── Farmer card ────────────────────────────────────────────────
            _SectionCard(
              title: 'Farmer Details',
              icon: Icons.person_outline_rounded,
              children: [
                _DetailRow('Farmer Name', cropDetails["FarmerName"]),
                _DetailRow('Phone', cropDetails["PhoneNumber"]),
                _DetailRow('Location', location),
              ],
            ),

            const SizedBox(height: 28),

            // ── Action buttons ─────────────────────────────────────────────
            Row(
              children: [
                // View on Map
                if (location.isNotEmpty)
                  Expanded(
                    child: _BigActionButton(
                      icon: Icons.map_rounded,
                      label: 'View on Map',
                      color: const Color(0xFF337233),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmerLocationMapScreen(
                            locationText: location,
                            cropName: product,
                            phoneNumber: phone,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (location.isNotEmpty && phone.isNotEmpty)
                  const SizedBox(width: 12),

                // Call Farmer
                if (phone.isNotEmpty)
                  Expanded(
                    child: _BigActionButton(
                      icon: Icons.call_rounded,
                      label: 'Call Farmer',
                      color: const Color(0xFF1A5276),
                      onTap: () => _callFarmer(context),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(dynamic rating) {
    final double r = double.tryParse(rating?.toString() ?? '0') ?? 0;
    final int filled = r.floor().clamp(0, 5);
    return Row(
      children: [
        ...List.generate(
          5,
              (i) => Icon(
            i < filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: i < filled ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          r > 0 ? '$r / 5' : 'Not rated',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontFamily: 'Poppins-SemiBold',
          ),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins-SemiBold',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF337233), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Poppins-SemiBold',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final dynamic value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontFamily: 'Poppins-SemiBold',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : 'N/A',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins-SemiBold',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'Poppins-SemiBold',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}