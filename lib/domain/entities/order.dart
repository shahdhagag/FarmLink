import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Order extends Equatable {
  final String id;
  final String cropId;
  final String cropName;
  final String farmerUid;
  final String farmerName;
  final String buyerUid;
  final String buyerName;
  final double quantityKg;
  final double pricePerKg;
  final double totalAmount;
  final String status;
  final String? buyerNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.farmerUid,
    required this.farmerName,
    required this.buyerUid,
    required this.buyerName,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalAmount,
    required this.status,
    this.buyerNote,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory method must be static (which it is)
  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      farmerUid: map['farmerUid'] ?? '',
      farmerName: map['farmerName'] ?? '',
      buyerUid: map['buyerUid'] ?? '',
      buyerName: map['buyerName'] ?? '',
      quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 0,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'pending',
      buyerNote: map['buyerNote'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Explicitly define the return type for toMap
  Map<String, dynamic> toMap() {
    return {
      'cropId': cropId,
      'cropName': cropName,
      'farmerUid': farmerUid,
      'farmerName': farmerName,
      'buyerUid': buyerUid,
      'buyerName': buyerName,
      'quantityKg': quantityKg,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'status': status,
      'buyerNote': buyerNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [id, cropId, buyerUid, status];
}