import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Crop extends Equatable {
  final String id;
  final String farmerUid;
  final String farmerName;
  final String farmerPhone;
  final String? farmerPhotoUrl;
  final String product;
  final String description;
  final double costPerKg;
  final double availabilityKg;
  final String category; // <--- Add this (e.g., "Vegetable", "Fruit")
  final String cropType; // Organic | Hybrid
  final String priceType; // Fixed Price | Negotiable
  final double rating;
  final List<String> imageUrls;
  final String location;
  final double? lat;
  final double? lon;
  final DateTime harvestDate;
  final DateTime expiryDate;
  final DateTime uploadedAt;
  final bool isAvailable;
  final int viewCount;

  const Crop({

    required this.id,
    required this.farmerUid,
    required this.farmerName,
    required this.farmerPhone,
    this.farmerPhotoUrl,
    required this.product,
    required this.description,
    required this.costPerKg,
    required this.availabilityKg,
    required this.cropType,
    required this.priceType,
    required this.rating,
    required this.imageUrls,
    required this.location,
    this.lat,
    this.lon,
    required this.harvestDate,
    required this.expiryDate,
    required this.uploadedAt,
    this.isAvailable = true,
    this.viewCount = 0,
    required this.category,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isOrganic => cropType == 'Organic';

  factory Crop.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          final parts = val.split('/');
          if (parts.length == 3) {
            return DateTime(
                int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
          return DateTime.tryParse(val) ?? DateTime.now();
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Crop(
      id: id,
      farmerUid: map['FarmerUID'] ?? '',
      farmerName: map['FarmerName'] ?? '',
      farmerPhone: map['PhoneNumber'] ?? '',
      farmerPhotoUrl: map['farmerPhotoUrl'],
      product: map['Product'] ?? '',
      description: map['description'] ?? '',
      costPerKg: double.tryParse(map['CostPerKg']?.toString() ?? '0') ?? 0,
      availabilityKg:
          double.tryParse(map['Availability']?.toString() ?? '0') ?? 0,
      cropType: map['Croptype'] ?? 'Organic',
      priceType: map['PriceType'] ?? 'Fixed Price',
      rating: double.tryParse(map['CropRating']?.toString() ?? '0') ?? 0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      location: map['Location'] ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lon: (map['lon'] as num?)?.toDouble(),
      harvestDate: _parseDate(map['HarvestDate']),
      expiryDate: _parseDate(map['ExpiryDate']),
      uploadedAt: _parseDate(map['CropUploadedDate']),
      isAvailable: map['isAvailable'] ?? true,
      viewCount: map['viewCount'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'FarmerUID': farmerUid,
        'FarmerName': farmerName,
        'PhoneNumber': farmerPhone,
        'farmerPhotoUrl': farmerPhotoUrl,
        'Product': product,
        'description': description,
        'CostPerKg': costPerKg.toString(),
        'Availability': availabilityKg.toString(),
        'Croptype': cropType,
        'PriceType': priceType,
        'CropRating': rating.toString(),
        'imageUrls': imageUrls,
        'Location': location,
        'lat': lat,
        'lon': lon,
        'HarvestDate': Timestamp.fromDate(harvestDate),
        'ExpiryDate': Timestamp.fromDate(expiryDate),
        'CropUploadedDate': Timestamp.fromDate(uploadedAt),
        'isAvailable': isAvailable,
        'viewCount': viewCount,
        'category': category,
      };

  @override
  List<Object?> get props => [id, farmerUid, product, uploadedAt];
}
