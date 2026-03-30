import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;
  const EditProfileScreen({super.key, required this.existingData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color primaryGreen = const Color(0xFF337233);
  final user = FirebaseAuth.instance.currentUser;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController farmNameController;
  late TextEditingController bioController;

  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing Firestore data
    nameController = TextEditingController(text: widget.existingData['fullName'] ?? "");
    phoneController = TextEditingController(text: widget.existingData['phone'] ?? "");
    farmNameController = TextEditingController(text: widget.existingData['farmName'] ?? "");
    bioController = TextEditingController(text: widget.existingData['bio'] ?? "");
  }

  Future<void> _updateProfile() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name cannot be empty")));
      return;
    }

    setState(() => isUpdating = true);

    try {
      await FirebaseFirestore.instance.collection('Farmers').doc(user!.uid).set({
        'fullName': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'farmName': farmNameController.text.trim(),
        'bio': bioController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true prevents overwriting other fields

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Color(0xFF337233)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
      ),
      body: isUpdating
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: primaryGreen.withOpacity(0.1),
                  child: Icon(Icons.person, size: 70, color: primaryGreen),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: primaryGreen,
                    radius: 18,
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildEditField("Full Name", Icons.person_outline, nameController),
            _buildEditField("Farm Name", Icons.agriculture_outlined, farmNameController),
            _buildEditField("Phone Number", Icons.phone_android_outlined, phoneController, keyboardType: TextInputType.phone),
            _buildEditField("Farm Description", Icons.info_outline, bioController, maxLines: 3),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("SAVE CHANGES",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, IconData icon, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF8FAF8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryGreen, width: 1.5)),
        ),
      ),
    );
  }
}