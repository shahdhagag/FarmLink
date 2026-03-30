import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class FarmerAddScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final Map<String, dynamic>? existingCrop;

  const FarmerAddScreen({super.key, this.onBackToHome, this.existingCrop});

  @override
  State<FarmerAddScreen> createState() => _FarmerAddScreenState();
}

class _FarmerAddScreenState extends State<FarmerAddScreen> {
  final Color primaryGreen = const Color.fromRGBO(51, 114, 51, 1.0);
  final GlobalKey<FormState> farmerAddGkey = GlobalKey<FormState>();

  // Controllers
  final productController = TextEditingController();
  final availabilityController = TextEditingController();
  final costPerKgController = TextEditingController();
  final harvestDateController = TextEditingController();
  final expiryDateController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final farmerNameController = TextEditingController();

  // State
  String cropType = 'Organic';
  double cropRating = 0.0;
  String priceType = 'Fixed Price';
  String location = "Fetching location...";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCrop != null) {
      _loadExistingData();
    } else {
      _getLocation();
    }
  }

  void _loadExistingData() {
    final data = widget.existingCrop!;
    // Note: Using Capitalized keys to match your Firebase structure
    productController.text = data['Product']?.toString() ?? "";
    availabilityController.text = data['Availability']?.toString() ?? "";
    costPerKgController.text = data['CostPerKg']?.toString() ?? "";
    harvestDateController.text = data['HarvestDate']?.toString() ?? "";
    expiryDateController.text = data['ExpiryDate']?.toString() ?? "";
    farmerNameController.text = data['FarmerName']?.toString() ?? "";
    phoneNumberController.text = data['PhoneNumber']?.toString() ?? "";

    cropType = data['Croptype'] ?? 'Organic';
    cropRating = double.tryParse(data['CropRating']?.toString() ?? "0.0") ?? 0.0;
    priceType = data['PriceType'] ?? 'Fixed Price';
    location = data['Location'] ?? "Location set";
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() => location =
      "${placemarks[0].locality}, ${placemarks[0].administrativeArea}");
    } catch (e) {
      setState(() => location = "Location unavailable");
    }
  }

  Future<void> handleSubmission() async {
    if (!farmerAddGkey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final cropData = {
        "Product": productController.text.trim(),
        "Availability": availabilityController.text.trim(),
        "CostPerKg": costPerKgController.text.trim(),
        "HarvestDate": harvestDateController.text.trim(),
        "ExpiryDate": expiryDateController.text.trim(),
        "FarmerName": farmerNameController.text.trim(),
        "Croptype": cropType,
        "CropRating": cropRating.toString(),
        "PriceType": priceType,
        "PhoneNumber": phoneNumberController.text.trim(),
        "Location": location,
        "FarmerUID": user?.uid,
        "CropUploadedDate": widget.existingCrop?['uploadDate'] ??
            DateFormat('dd-MM-yyyy').format(DateTime.now()),
      };

      if (widget.existingCrop != null) {
        await FirebaseFirestore.instance
            .collection("CropMain")
            .doc(widget.existingCrop!['id'])
            .update(cropData);
        _showSnackBar("Updated Successfully!", Colors.blue);
      } else {
        await FirebaseFirestore.instance.collection("CropMain").add(cropData);
        _showSnackBar("Added Successfully!", Colors.green);
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else if (widget.onBackToHome != null) {
        widget.onBackToHome!();
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.existingCrop == null ? "Add New Crop" : "Update Crop",
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            }
          },
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: farmerAddGkey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildFieldCard("Farmer Info", [
                  _inputField(farmerNameController, "Farmer Name", Icons.person),
                  const SizedBox(height: 15),
                  _inputField(phoneNumberController, "Phone", Icons.phone,
                      keyboard: TextInputType.phone),
                ]),
                const SizedBox(height: 20),
                _buildFieldCard("Product Details", [
                  _inputField(productController, "Product Name", Icons.grass),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(
                        child: _inputField(
                            availabilityController, "Qty (Kg)", Icons.scale,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _inputField(
                            costPerKgController, "Price/Kg", Icons.payments,
                            keyboard: TextInputType.number)),
                  ]),
                  const SizedBox(height: 15),
                  _buildToggleRow(),
                ]),
                const SizedBox(height: 20),
                _buildFieldCard("Dates & Rating", [
                  Row(children: [
                    Expanded(child: _dateField(harvestDateController, "Harvest")),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField(expiryDateController, "Expiry")),
                  ]),
                  const SizedBox(height: 20),
                  Center(
                    child: RatingBar(
                      initialRating: cropRating,
                      filledIcon: Icons.star,
                      emptyIcon: Icons.star_border,
                      onRatingChanged: (v) => cropRating = v,
                      filledColor: Colors.amber,
                    ),
                  ),
                ]),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    onPressed: handleSubmission,
                    child: Text(
                        widget.existingCrop == null
                            ? "LIST CROP"
                            : "UPDATE LISTING",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                // This extra space ensures the button isn't hidden by the Bottom Nav Bar
               // const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!)),
        child: Column(children: children),
      )
    ]);
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: (v) => v!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget _dateField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        DateTime? p = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2024),
            lastDate: DateTime(2030));
        if (p != null) controller.text = DateFormat('dd-MM-yyyy').format(p);
      },
      decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget _buildToggleRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      ChoiceChip(
          label: const Text("Organic"),
          selected: cropType == "Organic",
          onSelected: (s) => setState(() => cropType = "Organic")),
      ChoiceChip(
          label: const Text("Hybrid"),
          selected: cropType == "Hybrid",
          onSelected: (s) => setState(() => cropType = "Hybrid")),
    ]);
  }
}