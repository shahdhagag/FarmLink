import 'package:flutter/material.dart';

class Farmercropdetailcrop extends StatefulWidget {
  final Map<String, dynamic> crop;

  const Farmercropdetailcrop({super.key, required this.crop});

  @override
  State<Farmercropdetailcrop> createState() => _FarmercropdetailcropState();
}

class _FarmercropdetailcropState extends State<Farmercropdetailcrop> {
  final Color primaryGreen = const Color.fromRGBO(51, 114, 51, 1.0);
  final Color backgroundGrey = const Color(0xFFF8F9FA);
  final Color accentGold = const Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.crop['product']?.toString() ?? "Crop Details",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- Top Hero Header ---
            _buildHeroHeader(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Pricing Section ---
                  _sectionLabel("PRICING & STOCK"),
                  _buildDetailCard([
                    _infoRow(Icons.currency_rupee_rounded, "Cost Per Kg", "₹${widget.crop['costPerKg']}"),
                    _infoRow(Icons.shopping_bag_outlined, "Price Type", widget.crop['priceType'] ?? "Fixed"),
                    _infoRow(Icons.inventory_2_outlined, "Availability", "${widget.crop['availability']} units"),
                  ]),

                  const SizedBox(height: 24),

                  // --- Timeline Section ---
                  _sectionLabel("IMPORTANT DATES"),
                  _buildDetailCard([
                    _infoRow(Icons.agriculture_rounded, "Harvest Date", widget.crop['harvestDate'] ?? "N/A"),
                    _infoRow(Icons.event_busy_rounded, "Expiry Date", widget.crop['expiryDate'] ?? "N/A"),
                    _infoRow(Icons.cloud_upload_outlined, "Listed On", widget.crop['uploadDate'] ?? "N/A"),
                  ]),

                  const SizedBox(height: 24),

                  // // --- Farmer Section ---
                  // _sectionLabel("FARMER INFORMATION"),
                  // _buildDetailCard([
                  //   _infoRow(Icons.person_pin_rounded, "Farmer Name", widget.crop['farmerName'] ?? "N/A"),
                  //   _infoRow(Icons.phone_android_rounded, "Contact", widget.crop['phoneNumber'] ?? "N/A"),
                  //   _infoRow(Icons.location_on_rounded, "Location", widget.crop['location'] ?? "N/A"),
                  // ]),

                 // --- Farmer Section ---
                  _sectionLabel("FARMER INFORMATION"),
                  _buildDetailCard([
                    // Change 'farmerName' to 'FarmerName'
                    _infoRow(Icons.person_pin_rounded, "Farmer Name", widget.crop['FarmerName'] ?? "N/A"),

                    // Change 'phoneNumber' to 'PhoneNumber'
                    _infoRow(Icons.phone_android_rounded, "Contact", widget.crop['phoneNumber'] ?? "N/A"),

                    // Change 'location' to 'Location'
                    _infoRow(Icons.location_on_rounded, "Location", widget.crop['Location'] ?? "N/A"),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grass_rounded, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            widget.crop['product']?.toString().toUpperCase() ?? "PRODUCT",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: accentGold, size: 20),
                const SizedBox(width: 4),
                Text(
                  "Rating: ${widget.crop['cropRating'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: primaryGreen.withOpacity(0.7),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: primaryGreen),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
        ],
      ),
    );
  }
}