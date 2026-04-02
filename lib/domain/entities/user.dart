import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role; // 'farmer' | 'buyer'
  final String? phone;
  final String? photoUrl;
  final String? location;
  final double? lat;
  final double? lon;
  final DateTime createdAt;
  final bool isVerified;
  final double rating;
  final int ratingCount;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.photoUrl,
    this.location,
    this.lat,
    this.lon,
    required this.createdAt,
    this.isVerified = false,
    this.rating = 0,
    this.ratingCount = 0,
  });

  bool get isFarmer => role == 'farmer';
  bool get isBuyer => role == 'buyer';

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      location: map['location'],
      lat: (map['lat'] as num?)?.toDouble(),
      lon: (map['lon'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: map['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'photoUrl': photoUrl,
        'location': location,
        'lat': lat,
        'lon': lon,
        'createdAt': Timestamp.fromDate(createdAt),
        'isVerified': isVerified,
        'rating': rating,
        'ratingCount': ratingCount,
      };

  AppUser copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? location,
    double? lat,
    double? lon,
    bool? isVerified,
    double? rating,
    int? ratingCount,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      createdAt: createdAt,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  @override
  List<Object?> get props =>
      [uid, email, name, role, phone, photoUrl, location];
}

