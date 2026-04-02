import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:farmlink/core/theme/app_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/crop.dart';
import '../../providers/app_provider.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/fl_text_field.dart';

class FarmerAddTab extends ConsumerStatefulWidget {
  const FarmerAddTab({super.key});

  @override
  ConsumerState<FarmerAddTab> createState() => _FarmerAddTabState();
}

class _FarmerAddTabState extends ConsumerState<FarmerAddTab> {
  final _formKey = GlobalKey<FormState>();
  final _productCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _availCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // Selection States
  String _cropType = 'Organic';
  String _priceType = 'Fixed Price';
  String _category = 'Vegetable'; // Added: Category state
  double _rating = 3;

  DateTime? _harvestDate;
  DateTime? _expiryDate;
  String _location = '';
  double? _lat;
  double? _lon;
  bool _locLoading = false;
  bool _submitting = false;
  final List<File> _images = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _productCtrl.dispose();
    _descCtrl.dispose();
    _availCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() => _locLoading = true);
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        if (mounted)
          setState(() {
            _location = 'Location services disabled';
            _locLoading = false;
          });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted)
          setState(() {
            _location = 'Permission denied';
            _locLoading = false;
          });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 12));

      _lat = pos.latitude;
      _lon = pos.longitude;

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if (mounted) {
          setState(() {
            _location =
                '${p.name ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}'
                    .replaceAll(RegExp(r',\s*,'), ',')
                    .trim();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _location = 'Could not get location');
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 75, limit: 4);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.map((x) => File(x.path)));
        if (_images.length > 4) _images.length = 4;
      });
    }
  }

  Future<List<String>> _uploadImages(String cropId) async {
    if (_images.isEmpty) return [];
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    try {
      for (int i = 0; i < _images.length; i++) {
        final ref = storage.ref('crop_images/$cropId/img_$i.jpg');
        await ref.putFile(_images[i]);
        urls.add(await ref.getDownloadURL());
      }
    } catch (e) {
      return [];
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);

    if (_harvestDate == null || _expiryDate == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Please select harvest and expiry dates')));
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      final cropId = const Uuid().v4();
      final imageUrls = await _uploadImages(cropId);

      final crop = Crop(
        id: cropId,
        category: _category,
        // Correctly passing the selected category
        farmerUid: user.uid,
        farmerName: user.name,
        farmerPhone: user.phone ?? '',
        product: _productCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        costPerKg: double.parse(_priceCtrl.text),
        availabilityKg: double.parse(_availCtrl.text),
        cropType: _cropType,
        priceType: _priceType,
        rating: _rating,
        imageUrls: imageUrls,
        location: _location,
        lat: _lat,
        lon: _lon,
        harvestDate: _harvestDate!,
        expiryDate: _expiryDate!,
        uploadedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('CropMain')
          .doc(cropId)
          .set(crop.toMap());

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Crop listed successfully! 🌱'),
        backgroundColor: Colors.green,
      ));
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _productCtrl.clear();
    _descCtrl.clear();
    _availCtrl.clear();
    _priceCtrl.clear();
    setState(() {
      _cropType = 'Organic';
      _priceType = 'Fixed Price';
      _category = 'Vegetable';
      _rating = 3;
      _harvestDate = null;
      _expiryDate = null;
      _images.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('List a Crop',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20.sp)),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 120.h),
          physics: const BouncingScrollPhysics(),
          children: [
            _SectionLabel('Photos (up to 4)'),
            SizedBox(height: 12.h),
            _buildImagePicker(),
            SizedBox(height: 28.h),

            _SectionLabel('Crop Info'),
            SizedBox(height: 12.h),
            FLTextField(
              label: 'Product Name',
              hint: 'e.g. Tomatoes, Potatoes',
              controller: _productCtrl,
              prefixIcon: Icons.eco_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter product name' : null,
            ),
            SizedBox(height: 16.h),

            // --- NEW CATEGORY SECTION ---
            _SectionLabel('Category'),
            SizedBox(height: 12.h),
            Row(
                children: ['Vegetable', 'Fruit'].map((cat) {
              final isSelected = _category == cat;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin:
                        EdgeInsets.only(right: cat == 'Vegetable' ? 10.w : 0),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat == 'Vegetable'
                              ? Icons.grass_rounded
                              : Icons.apple_rounded,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14.sp,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()),
            SizedBox(height: 20.h),

            FLTextField(
              label: 'Description',
              hint: 'Describe quality, grade, farming method…',
              controller: _descCtrl,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            Row(children: [
              Expanded(
                child: FLTextField(
                  label: 'Price (₹/kg)',
                  controller: _priceCtrl,
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter price' : null,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: FLTextField(
                  label: 'Availability (kg)',
                  controller: _availCtrl,
                  prefixIcon: Icons.scale_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter quantity' : null,
                ),
              ),
            ]),
            SizedBox(height: 28.h),

            _SectionLabel('Crop Type'),
            SizedBox(height: 12.h),
            _buildToggleRow(['Organic', 'Hybrid'], _cropType,
                (v) => setState(() => _cropType = v)),
            SizedBox(height: 20.h),

            _SectionLabel('Pricing Type'),
            SizedBox(height: 12.h),
            _buildToggleRow(['Fixed Price', 'Negotiable'], _priceType,
                (v) => setState(() => _priceType = v),
                isSecondary: true),
            SizedBox(height: 28.h),

            _SectionLabel('Dates'),
            SizedBox(height: 12.h),
            Row(children: [
              Expanded(
                  child: _DatePickerTile(
                      label: 'Harvest Date',
                      date: _harvestDate,
                      onTap: () => _pickDate(true))),
              SizedBox(width: 14.w),
              Expanded(
                  child: _DatePickerTile(
                      label: 'Expiry Date',
                      date: _expiryDate,
                      onTap: () => _pickDate(false))),
            ]),
            SizedBox(height: 28.h),

            _SectionLabel('Self Rating'),
            SizedBox(height: 12.h),
            _buildRatingCard(),
            SizedBox(height: 28.h),

            _SectionLabel('Location'),
            SizedBox(height: 12.h),
            _buildLocationCard(),
            SizedBox(height: 36.h),

            FLButton(
              label: 'Publish Crop Listing',
              onPressed: _submit,
              isLoading: _submitting,
              icon: const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper UI Builders ---

  Widget _buildImagePicker() {
    return SizedBox(
      height: 100.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 100.w,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.primary, size: 32.sp),
                  Text('Add',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          ..._images.asMap().entries.map((e) => Stack(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 12.w),
                    width: 100.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      image: DecorationImage(
                          image: FileImage(e.value), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(e.key)),
                      child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle),
                          child: Icon(Icons.close,
                              color: Colors.white, size: 14.sp)),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      List<String> options, String current, Function(String) onSelect,
      {bool isSecondary = false}) {
    return Row(
        children: options.map((t) {
      final sel = current == t;
      final activeColor = isSecondary ? AppColors.secondary : AppColors.primary;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: t == options.first ? 10.w : 0),
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: sel ? activeColor : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: sel ? activeColor : AppColors.border),
            ),
            child: Text(t,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14.sp)),
          ),
        ),
      );
    }).toList());
  }

  Widget _buildRatingCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Column(children: [
        RatingBar(
          filledColor: AppColors.amber,
          size: 40.sp,
          filledIcon: Icons.star_rounded,
          emptyIcon: Icons.star_outline_rounded,
          onRatingChanged: (r) => setState(() => _rating = r),
          initialRating: _rating,
          maxRating: 5,
        ),
        SizedBox(height: 8.h),
        Text('Quality rating: ${_rating.toStringAsFixed(1)} / 5',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12.sp)),
      ]),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Row(children: [
        Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22.sp),
        SizedBox(width: 12.w),
        Expanded(
            child: Text(
                _locLoading
                    ? 'Getting location…'
                    : (_location.isEmpty ? 'Location not set' : _location),
                style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
                maxLines: 2)),
        IconButton(
            onPressed: _fetchLocation,
            icon: Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 20.sp)),
      ]),
    );
  }

  Future<void> _pickDate(bool isHarvest) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked != null)
      setState(() => isHarvest ? _harvestDate = picked : _expiryDate = picked);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary));
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerTile(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border.withOpacity(0.5))),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              color: AppColors.primary, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textTertiary, fontSize: 10.sp)),
                Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date!)
                        : 'Tap to select',
                    style: TextStyle(
                        color: date != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
      ),
    );
  }
}
