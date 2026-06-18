import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tambahin state loading di sini
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Getter untuk dipanggil dari UI (seperti ProfileScreen atau HomeScreen)
  User? get currentUser => _auth.currentUser;

  // Stream untuk AuthGate
  Stream<User?> get authStateStream => _auth.authStateChanges();

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow; // Lempar errornya ke UI biar bisa ditangkep try-catch di sana
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Register error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}