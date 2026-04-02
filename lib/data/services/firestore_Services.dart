import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' as ent;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmlink/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_room.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/order.dart'as model;
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── User Operations ──────────────────────────────────────────────────────

  Future<AppUser?> getUser(String uid) async {
    final doc =
    await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, uid);
  }

  Stream<AppUser?> watchCurrentUserStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((s) => s.exists ? AppUser.fromMap(s.data()!, s.id) : null);
  }

  Future<void> createUser(AppUser user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  // ─── Crop Operations ──────────────────────────────────────────────────────

  Stream<List<Crop>> watchAllCrops({String? filterType}) {
    // 1. We keep the query very simple to avoid "Index Errors"
    // We only use ONE 'where' and ONE 'orderBy'
    Query query = _db
        .collection(AppConstants.cropsCollection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('CropUploadedDate', descending: true);

    // 2. If there's a filter, we add it (Firestore allows this)
    if (filterType != null && filterType != 'All') {
      query = query.where('Croptype', isEqualTo: filterType);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Crop.fromMap(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  Stream<List<Crop>> watchFarmerCrops(String farmerUid) {
    return _db
        .collection(AppConstants.cropsCollection)
        .where('FarmerUID', isEqualTo: farmerUid)
        .orderBy('CropUploadedDate', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => Crop.fromMap(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  Future<void> updateCrop(String cropId, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.cropsCollection).doc(cropId).update(data);
  }

  Future<void> deleteCrop(String cropId) async {
    await _db.collection(AppConstants.cropsCollection).doc(cropId).delete();
  }

  // Stream<List<Crop>> watchFarmerCrops(String farmerUid) {
  //   return _db
  //       .collection(AppConstants.cropsCollection)
  //       .where('FarmerUID', isEqualTo: farmerUid)
  //       .orderBy('CropUploadedDate', descending: true)
  //       .snapshots()
  //       .map((snap) =>
  //       snap.docs.map((d) => Crop.fromMap(d.data() as Map<String,dynamic>, d.id)).toList());
  // }
  //
  // Future<String> addCrop(Crop crop) async {
  //   final ref = await _db
  //       .collection(AppConstants.cropsCollection)
  //       .add(crop.toMap());
  //   return ref.id;
  // }
  //
  // Future<void> updateCrop(String cropId, Map<String, dynamic> data) async {
  //   await _db
  //       .collection(AppConstants.cropsCollection)
  //       .doc(cropId)
  //       .update(data);
  // }
  //
  // Future<void> deleteCrop(String cropId) async {
  //   await _db.collection(AppConstants.cropsCollection).doc(cropId).delete();
  // }

  Future<void> incrementViewCount(String cropId) async {
    await _db
        .collection(AppConstants.cropsCollection)
        .doc(cropId)
        .update({'viewCount': FieldValue.increment(1)});
  }

  // ─── Order Operations ─────────────────────────────────────────────────────
// ─── Order Operations ─────────────────────────────────────────────────────

  Future<String> placeOrder(model.Order order) async {
    final cropRef = _db.collection(AppConstants.cropsCollection).doc(order.cropId);
    final orderRef = _db.collection(AppConstants.ordersCollection).doc();

    final result = await _db.runTransaction((transaction) async {
      final cropSnap = await transaction.get(cropRef);
      if (!cropSnap.exists) return "ERROR: Crop not found";

      // Use 'Availability' to match your farmer edit dialog key
      final availRaw = cropSnap.data()?['Availability'];
      final currentStock = double.tryParse(availRaw?.toString() ?? '0') ?? 0;

      if (currentStock < order.quantityKg) {
        return "ERROR: Not enough stock!";
      }

      // 1. Subtract the quantity from the database
      transaction.update(cropRef, {
        'Availability': (currentStock - order.quantityKg).toString(),
      });

      // 2. Save the order
      final orderMap = order.toMap();
      orderMap['createdAt'] = FieldValue.serverTimestamp();
      transaction.set(orderRef, orderMap);

      return orderRef.id;
    });

    if (result.startsWith("ERROR:")) {
      throw Exception(result.replaceFirst("ERROR: ", ""));
    }

    return result;
  }

  Stream<List<model.Order>> watchBuyerOrders(String buyerUid) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('buyerUid', isEqualTo: buyerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => model.Order.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  Stream<List<model.Order>> watchFarmerOrders(String farmerUid) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('farmerUid', isEqualTo: farmerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => model.Order.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Chat Operations ──────────────────────────────────────────────────────

  String _buildChatId(String uid1, String uid2, String cropId) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}_$cropId';
  }

  Future<String> getOrCreateChatRoom({
    required String currentUid,
    required String currentName,
    required String otherUid,
    required String otherName,
    required String cropId,
    required String cropName,
  }) async {
    final chatId = _buildChatId(currentUid, otherUid, cropId);
    final ref = _db.collection(AppConstants.chatsCollection).doc(chatId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participantIds': [currentUid, otherUid],
        'participantNames': {currentUid: currentName, otherUid: otherName},
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'cropId': cropId,
        'cropName': cropName,
        'unreadCount': {currentUid: 0, otherUid: 0},
      });
    }
    return chatId;
  }

  Stream<List<ChatRoom>> watchUserChats(String uid) {
    return _db
        .collection(AppConstants.chatsCollection)
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ChatRoom.fromMap(d.data() as Map<String,dynamic>, d.id))
        .toList());
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ChatMessage.fromMap(d.data() as Map<String,dynamic>, d.id))
        .toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
    required String otherUid,
  }) async {
    final batch = _db.batch();
    final msgRef = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc();

    batch.set(msgRef, message.toMap());
    batch.update(
      _db.collection(AppConstants.chatsCollection).doc(chatId),
      {
        'lastMessage': message.text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount.$otherUid': FieldValue.increment(1),
      },
    );
    await batch.commit();
  }

  Future<void> markMessagesRead(String chatId, String uid) async {
    await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({'unreadCount.$uid': 0});
  }
}