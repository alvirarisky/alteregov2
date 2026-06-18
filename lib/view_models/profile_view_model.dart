import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? get profileData => _profileData;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch profil saat aplikasi pertama kali buka atau saat masuk tab profil
  Future<void> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _profileData = doc.data();
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CRUD: Update profil user ke database[cite: 1]
  Future<void> updateProfile({required String bio, required String major}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'bio': bio,
        'major': major,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      await fetchProfile(); // Refresh data lokal
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}