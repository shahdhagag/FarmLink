import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'FarmerCropDetail.dart';

class FarmerInventoryScreen extends StatefulWidget {
  const FarmerInventoryScreen({super.key});

  @override
  State<FarmerInventoryScreen> createState() => _FarmerInventoryScreenState();
}

class _FarmerInventoryScreenState extends State<FarmerInventoryScreen> {
  final Color primaryGreen = const Color.fromRGBO(51, 114, 51, 1.0);
  final Color backgroundGrey = const Color(0xFFF8F9FA);

  List<Map<String, dynamic>> allCrops = [];
  List<Map<String, dynamic>> filteredCrops = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCrops();
  }

  // LOGIC: Fetch from Firestore
  Future<void> fetchCrops() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      var snapshot = await FirebaseFirestore.instance
          .collection("CropMain")
          .where("FarmerUID", isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> fetched = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Store document ID for updates later
        return data;
      }).toList();

      // Sort by date (Newest first)
      fetched.sort((a, b) => _parseDate(b['CropUploadedDate']).compareTo(_parseDate(a['CropUploadedDate'])));

      setState(() {
        allCrops = fetched;
        filteredCrops = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
      setState(() => isLoading = false);
    }
  }

  DateTime _parseDate(dynamic date) {
    try {
      return DateFormat("dd-MM-yyyy").parse(date.toString());
    } catch (e) {
      return DateTime(2000, 1, 1);
    }
  }

  // LOGIC: Search/Filter function
  void _filterCrops(String query) {
    setState(() {
      filteredCrops = allCrops
          .where((crop) => crop['Product'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int lowStockCount = allCrops.where((c) => (double.tryParse(c['Availability'].toString()) ?? 0) < 10).length;

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text("My Inventory", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeaderStats(lowStockCount),
          _buildSearchBox(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : filteredCrops.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: fetchCrops,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredCrops.length,
                itemBuilder: (context, index) => _buildInventoryCard(filteredCrops[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(int lowStock) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          _statTile("Total Items", allCrops.length.toString(), Icons.inventory_2),
          const SizedBox(width: 15),
          _statTile("Low Stock", lowStock.toString(), Icons.warning_amber_rounded, color: Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: searchController,
        onChanged: _filterCrops,
        decoration: InputDecoration(
          hintText: "Search your crops...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> crop) {
    double stock = double.tryParse(crop['Availability'].toString()) ?? 0;
    Color stockColor = stock < 10 ? Colors.red : primaryGreen;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Farmercropdetailcrop(crop: crop))),
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.grass, color: primaryGreen),
        ),
        title: Text(crop['Product'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Price: ₹${crop['CostPerKg']}/${crop['PriceType'] ?? 'Kg'}"),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storage, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text("Stock: $stock kg", style: TextStyle(color: stockColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const Text("No crops found", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}