import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reflection_model.dart';

class ReflectionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReflectionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User get _requireUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not signed in.');
    }
    return user;
  }

  CollectionReference<Map<String, dynamic>> _reflectionsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('reflections');
  }

Stream<ReflectionModel?> streamLatestReflection() {
    final user = _requireUser;
    final q = _reflectionsCollection(user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1);
        
    return q.snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return ReflectionModel.fromMap(doc.data(), doc.id);
    });
  }

  Stream<List<ReflectionModel>> streamAllReflections() {
    final user = _requireUser;
    final q = _reflectionsCollection(user.uid).orderBy('createdAt', descending: true);
    
    return q.snapshots().map((snap) {
      return snap.docs
          .map((doc) => ReflectionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String> saveReflection(ReflectionModel reflection) async {
    final user = _requireUser;
    final ref = await _reflectionsCollection(user.uid).add(reflection.toMap());
    return ref.id;
  }

  Future<void> setAiResponse({
    required String reflectionId,
    required String aiResponse,
  }) async {
    final user = _requireUser;
    await _reflectionsCollection(user.uid).doc(reflectionId).update({
      'aiResponse': aiResponse,
      'aiGeneratedAt': FieldValue.serverTimestamp(),
    });
  }
}

