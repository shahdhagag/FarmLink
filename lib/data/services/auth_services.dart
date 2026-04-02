import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmlink/core/constants/app_constants.dart';

import '../../domain/entities/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await cred.user!.updateDisplayName(name.trim());

    final user = AppUser(
      uid: cred.user!.uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      phone: phone?.trim(),
      createdAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    return user;
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(cred.user!.uid)
        .get();

    if (!doc.exists) throw Exception('User profile not found.');
    return AppUser.fromMap(doc.data()!, cred.user!.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, user.uid);
  }
}